import Foundation

/// Strategy for matching incoming requests to recorded HAR entries.
public enum Matcher: Sendable {
    /// Matches HTTP method (e.g. `GET`, `POST`).
    case method

    /// Matches the full absolute URL string, including scheme, host, path, and query.
    case url

    /// Matches URL host (e.g. `api.example.com`).
    case host

    /// Matches URL path (e.g. `/v1/users/42`).
    case path

    /// Matches URL query items (`URLComponents.queryItems`).
    case query

    /// Matches the values of the specified HTTP request headers.
    ///
    /// Header name lookup uses `URLRequest.value(forHTTPHeaderField:)` semantics.
    case headers([String])

    /// Matches the raw HTTP body bytes (`URLRequest.httpBody`).
    case body

    /// Escape hatch for custom matching logic.
    /// Compares an incoming request against a candidate request (typically from a recorded entry).
    case custom(@Sendable (_ request: URLRequest, _ candidate: URLRequest) -> Bool)

    fileprivate func matches(_ request: URLRequest, _ candidate: URLRequest) -> Bool {
        switch self {
        case .method:
            return request.httpMethod == candidate.httpMethod

        case .url:
            return request.url?.absoluteString == candidate.url?.absoluteString

        case .host:
            return request.url?.host == candidate.url?.host

        case .path:
            return request.url?.path == candidate.url?.path

        case .query:
            guard
                let url1 = request.url,
                let url2 = candidate.url
            else { return false }

            let components1 = URLComponents(url: url1, resolvingAgainstBaseURL: true)
            let components2 = URLComponents(url: url2, resolvingAgainstBaseURL: true)
            return components1?.queryItems == components2?.queryItems

        case .headers(let names):
            for name in names {
                if request.value(forHTTPHeaderField: name)
                    != candidate.value(forHTTPHeaderField: name)
                {
                    return false
                }
            }
            return true

        case .body:
            return request.httpBody == candidate.httpBody

        case .custom(let block):
            return block(request, candidate)
        }
    }
}

// MARK: -

extension Array where Element == Matcher {
    /// Default matching strategy: HTTP method + full URL.
    ///
    /// This is the strictest matcher set and will treat query string changes as mismatches.
    public static var `default`: [Matcher] {
        [.method, .url]
    }

    /// Returns whether all matchers match `request` against itself.
    ///
    /// This is used by capture as an opt-in filter.
    public func matches(_ request: URLRequest) -> Bool {
        for matcher in self {
            if !matcher.matches(request, request) {
                return false
            }
        }
        return true
    }

    /// Finds the first entry whose request matches according to all matchers.
    public func firstMatch(for request: URLRequest, in entries: [HAR.Entry]) -> HAR.Entry? {
        for entry in entries {
            guard let entryURL = URL(string: entry.request.url) else { continue }

            var entryRequest = URLRequest(url: entryURL)
            entryRequest.httpMethod = entry.request.method
            for header in entry.request.headers {
                entryRequest.setValue(header.value, forHTTPHeaderField: header.name)
            }
            if let postData = entry.request.postData,
                let text = postData.text
            {
                // HAR `postData.text` is stored as UTF-8 for text payloads.
                // For non-text payloads, Replay currently stores base64 in `text` without an
                // explicit encoding marker, so body matching is best-effort.
                entryRequest.httpBody = text.data(using: .utf8)
            }

            if matches(request, entryRequest) {
                return entry
            }
        }

        return nil
    }

    private func matches(_ request: URLRequest, _ candidate: URLRequest) -> Bool {
        for matcher in self {
            if !matcher.matches(request, candidate) {
                return false
            }
        }
        return true
    }
}
