import Foundation

/// Determines how Replay should behave in tests.
public enum RecordingMode: String, Hashable, CaseIterable {
    /// Only replay from archives (default).
    case playback

    /// Explicitly requested recording.
    case record

    /// Run tests against the live network, ignoring replay archives and without recording.
    case live

    /// The current recording mode.
    ///
    /// - Returns: The inferred recording mode.
    ///
    ///   This value is computed from environment variables and process arguments:
    ///   - `.playback` (default) when `REPLAY_MODE=playback` or not set
    ///   - `.record` when `REPLAY_MODE=record` is set,
    ///     or when `--enable-replay-recording` is present
    ///   - `.live` when `REPLAY_MODE=live` is set,
    ///     or when `--enable-replay-live` is present
    public static var current: RecordingMode {
        if let modeString = ProcessInfo.processInfo.environment["REPLAY_MODE"]?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased(),
            let mode = RecordingMode(rawValue: modeString)
        {
            return mode
        }

        return .playback
    }
}
