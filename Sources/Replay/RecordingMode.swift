import Foundation

/// Determines whether tests should only replay from archives or actively record.
public enum RecordingMode {
    /// Only replay from archives
    case playback

    /// Explicitly requested recording
    case record

    /// Determine the current recording mode based on the environment and command line arguments.
    ///
    /// - When `REPLAY_RECORD` environment variable is set
    ///   or `--enable-replay-recording` command line argument is present,
    ///   return `.record`.
    /// - Otherwise, return `.playback`.
    ///
    /// - Returns: The recording mode to use for the current test run.
    public static var current: RecordingMode {
        // Check for explicit recording flag
        if ProcessInfo.processInfo.environment["REPLAY_RECORD"] != nil {
            return .record
        }

        // Check command line arguments (Swift Testing 6.1+)
        if CommandLine.arguments.contains("--enable-replay-recording") {
            return .record
        }

        return .playback
    }
}
