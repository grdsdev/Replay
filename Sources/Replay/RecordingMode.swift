import Foundation

/// Determines how Replay should behave in tests.
public enum RecordingMode: String, Hashable, CaseIterable {
    /// Only replay from archives (default).
    case playback

    /// Explicitly requested recording.
    case record

    /// Run tests against the live network, ignoring replay archives and without recording.
    case live

    /// Gets the recording mode from environment variables.
    ///
    /// - Returns: The recording mode from `REPLAY_MODE` environment variable.
    /// - Throws: `ReplayError.invalidRecordingMode` if `REPLAY_MODE` is set to an invalid value.
    ///
    ///   Valid values for `REPLAY_MODE`: `playback`, `record`, `live`.
    ///   If `REPLAY_MODE` is not set, returns `.playback`.
    public static func fromEnvironment() throws -> RecordingMode {
        guard
            let modeString = ProcessInfo.processInfo.environment["REPLAY_MODE"]?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).lowercased()
        else {
            return .playback
        }

        guard let mode = RecordingMode(rawValue: modeString) else {
            throw ReplayError.invalidRecordingMode(modeString)
        }

        return mode
    }
}
