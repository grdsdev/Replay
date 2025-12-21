import Foundation

/// Determines how Replay should behave in tests.
public enum RecordingMode {
    /// Only replay from archives (default).
    case playback

    /// Explicitly requested recording.
    case record

    /// Run tests against the live network, ignoring replay archives and without recording.
    case live

    /// The current recording mode.
    ///
    /// - Returns: `.live` if `REPLAY_MODE=live` / `REPLAY_LIVE=1` is set (or `--enable-replay-live` is present);
    ///            `.record` if `REPLAY_MODE=record` / `REPLAY_RECORDING=1` is set (or `--enable-replay-recording` is present);
    ///            otherwise returns `.playback`.
    public static var current: RecordingMode {
        if let mode = env("REPLAY_MODE")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            switch mode {
            case "live", "passthrough":
                return .live
            case "record", "recording":
                return .record
            case "playback", "replay":
                return .playback
            default:
                break
            }
        }

        if isTruthy(env("REPLAY_LIVE")) {
            return .live
        }
        if isTruthy(env("REPLAY_RECORDING")) {
            return .record
        }

        // Some runners may support passing custom args to the test process.
        if CommandLine.arguments.contains("--enable-replay-live") {
            return .live
        }
        if CommandLine.arguments.contains("--enable-replay-recording") {
            return .record
        }

        return .playback
    }

    private static func env(_ key: String) -> String? {
        guard let value = getenv(key) else { return nil }
        return String(cString: value)
    }

    private static func isTruthy(_ value: String?) -> Bool {
        guard let value else { return false }
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y", "on":
            return true
        default:
            return false
        }
    }
}
