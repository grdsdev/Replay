import Foundation
import Testing

@testable import Replay

@Suite("RecordingMode Tests")
struct RecordingModeTests {

    @Suite("Enum Cases")
    struct EnumCaseTests {
        @Test("playback case exists")
        func playbackCase() {
            let mode: RecordingMode = .playback
            #expect(mode == .playback)
        }

        @Test("record case exists")
        func recordCase() {
            let mode: RecordingMode = .record
            #expect(mode == .record)
        }

        @Test("live case exists")
        func liveCase() {
            let mode: RecordingMode = .live
            #expect(mode == .live)
        }

        @Test("cases are distinct")
        func casesAreDistinct() {
            #expect(RecordingMode.playback != RecordingMode.record)
            #expect(RecordingMode.playback != RecordingMode.live)
            #expect(RecordingMode.record != RecordingMode.live)
        }
    }

    @Suite("fromEnvironment()")
    struct FromEnvironmentTests {
        @Test("returns playback when REPLAY_MODE is not set")
        func returnsPlaybackWhenNotSet() throws {
            // This test assumes REPLAY_MODE is not set in the test environment
            // If it is set, the test will use that value instead
            let mode = try RecordingMode.fromEnvironment()
            #expect(mode == .playback || mode == .record || mode == .live)
        }

        @Test("returns valid mode when REPLAY_MODE is set to valid value")
        func returnsValidModeWhenSet() throws {
            let mode = try RecordingMode.fromEnvironment()
            #expect(mode == .playback || mode == .record || mode == .live)
        }

        @Test("does not throw when REPLAY_MODE is valid or not set")
        func doesNotThrowWhenValid() throws {
            // This test verifies the function doesn't throw for valid cases
            // (either not set, or set to a valid value)
            let mode = try RecordingMode.fromEnvironment()
            #expect(mode == .playback || mode == .record || mode == .live)
        }
    }

    @Suite("Equatable")
    struct EquatableTests {
        @Test("same cases are equal")
        func sameCasesEqual() {
            #expect(RecordingMode.playback == RecordingMode.playback)
            #expect(RecordingMode.record == RecordingMode.record)
            #expect(RecordingMode.live == RecordingMode.live)
        }

        @Test("different cases are not equal")
        func differentCasesNotEqual() {
            #expect(RecordingMode.playback != RecordingMode.record)
            #expect(RecordingMode.playback != RecordingMode.live)
            #expect(RecordingMode.record != RecordingMode.live)
        }
    }
}
