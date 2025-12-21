import Foundation
import PackagePlugin

@main
struct ReplayPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "ReplayCLI")
        let process = Process()
        process.executableURL = tool.url
        process.arguments = arguments
        process.environment = [
            "IN_PROCESS_SOURCEKIT": "1"  // mitigate sourcekit errors during playback
        ]

        // Pass through the environment variables, especially for PATH
        // so `swift` command can be found by the CLI tool if it needs to run it.
        for (key, value) in ProcessInfo.processInfo.environment {
            process.environment?[key] = value
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ExitCode(process.terminationStatus)
        }
    }
}

struct ExitCode: Error {
    let code: Int32
    init(_ code: Int32) { self.code = code }
}
