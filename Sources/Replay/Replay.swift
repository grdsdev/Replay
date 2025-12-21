import Foundation

/// Namespace for URLSession-related helpers used with Replay.
public enum Replay {
    /// A pre-configured `URLSession` with Replay enabled.
    ///
    /// This is a convenience for tests and tools that want a session without
    /// manually configuring `URLSessionConfiguration`.
    public static var session: URLSession {
        let config = URLSessionConfiguration.ephemeral
        configure(config)

        // When running in `.test` scope, route requests to the scoped store.
        if let store = ReplayContext.playbackStore {
            let key = PlaybackStoreRegistry.key(for: store)
            var headers = config.httpAdditionalHeaders ?? [:]
            headers[ReplayProtocolContext.headerName] = key
            config.httpAdditionalHeaders = headers
        }

        return URLSession(configuration: config)
    }

    /// Configure a `URLSessionConfiguration` with `PlaybackURLProtocol`
    /// inserted at highest priority.
    public static func configure(_ configuration: URLSessionConfiguration) {
        var protocols = configuration.protocolClasses ?? []
        if !protocols.contains(where: { $0 == PlaybackURLProtocol.self }) {
            protocols.insert(PlaybackURLProtocol.self, at: 0)
        }
        configuration.protocolClasses = protocols
    }

    /// Create a new `URLSessionConfiguration` with Replay pre-configured.
    public static func configuration(
        base: URLSessionConfiguration = .default
    ) -> URLSessionConfiguration {
        let config = base
        configure(config)
        return config
    }

    /// Create a `URLSession` with Replay pre-configured.
    public static func makeSession(
        configuration: URLSessionConfiguration = .default
    ) -> URLSession {
        let config = self.configuration(base: configuration)

        if let store = ReplayContext.playbackStore {
            let key = PlaybackStoreRegistry.key(for: store)
            var headers = config.httpAdditionalHeaders ?? [:]
            headers[ReplayProtocolContext.headerName] = key
            config.httpAdditionalHeaders = headers
        }

        return URLSession(configuration: config)
    }
}
