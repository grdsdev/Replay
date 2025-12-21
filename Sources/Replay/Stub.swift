import Foundation

/// A lightweight HTTP stub used for in-memory playback without a HAR file.
public struct Stub: Sendable {
    public var url: URL
    public var method: String

    public var status: Int
    public var headers: [String: String]
    public var body: Data?

    public init(
        _ url: URL,
        method: String = "GET",
        status: Int = 200,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.status = status
        self.headers = headers
        self.body = body
    }

    public init(
        _ url: URL,
        method: String = "GET",
        status: Int = 200,
        headers: [String: String] = [:],
        body: String,
        encoding: String.Encoding = .utf8
    ) {
        self.init(
            url,
            method: method,
            status: status,
            headers: headers,
            body: body.data(using: encoding)
        )
    }
}
