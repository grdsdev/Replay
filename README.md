# Replay

> [!CAUTION]
> This package is in active development, and may make breaking changes before an initial release.

HTTP recording, playback, and stubbing for Swift, 
built around **HAR (HTTP Archive)** fixtures and **Swift Testing** traits.

## Requirements

- Swift 6.2+
- macOS 14+ / iOS 17+ / tvOS 17+ / watchOS 10+ / visionOS 1+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mattt/Replay.git", branch: "main")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTestTarget",
    dependencies: [.product(name: "Replay", package: "Replay")]
)
```

## Quick Start

Add Replay as a dependency, then annotate your tests:

```swift
import Testing
import Replay

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

@Suite(.serialized) // recommended when tests share global HTTP mocking state
struct MyAPITests {
    @Test(.replay("fetchUser"))
    func fetchUser() async throws {
        // Replay intercepts requests globally, including URLSession.shared.
        // Your production code can stay unchanged.
        // Your tests don't make network requests unless you explicitly enable them.
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.example.com/users/42")!)
        let user = try JSONDecoder().decode(User.self, from: data)
        #expect(user.id == 42)
    }
}
```

## Design Philosophy

Recent additions to Swift 6 — 
package plugins, Swift Testing traits, test attachments, and strict concurrency — 
_finally_ make it possible to build a truly great HTTP recording library.

Replay combines these capabilities into a cohesive experience: 
convenient HTTP capture with package plugin,
seamless test integration via traits, 
and rich debugging through attachments.

### Why explicit recording?

Traditional VCR-style libraries 
(like Ruby's [VCR](https://github.com/vcr/vcr) or Python's [VCR.py](https://github.com/kevin1024/vcrpy)) 
record automatically on first run, then replay thereafter. 

However, this convenience can become a liability:

- **Silent recording of wrong responses** — A misconfigured test might record an error response and replay it forever
- **Accidental network calls in CI** — Tests that should use fixtures might hit live APIs
- **Stale fixtures go unnoticed** — No signal that recorded data is months old

Replay takes a different approach: 
**tests fail explicitly when archives are missing**, 
with clear instructions on how to record. 
This makes fixture creation a deliberate action, 
preventing accidental recordings 
and ensuring CI environments never make network calls.

### Why HAR format?

[HAR (HTTP Archive)](http://www.softwareishard.com/blog/har-12-spec/) 
is the industry standard for HTTP traffic capture, 
supported by every major browser's developer tools, 
Charles Proxy, Postman, and most debugging tools. 

Using HAR means:

- **Interoperability** — Import/export captures from any browser or proxy tool
- **Human-readable** — JSON format is easy to inspect and edit
- **Complete fidelity** — Headers, cookies, timing, and content are all preserved
- **Ecosystem support** — Tools like [HAR Analyzer](https://toolbox.googleapps.com/apps/har_analyzer/) for visualization

### How `URLProtocol` works

Replay intercepts HTTP requests using `URLProtocol`, 
which operates at the Foundation networking layer. 

When a test runs with `.replay`:

1. Replay registers a custom `URLProtocol` globally
2. All `URLSession` requests (including `URLSession.shared`) are intercepted
3. Matching requests serve responses from the HAR archive
4. Unmatched requests fail (or record, if enabled)

This means **your production code doesn't need any changes**.
Replay works with Alamofire and any other networking library 
built on the Foundation URL Loading System.

### Where fixtures live

`ReplayTrait` looks for `Replays/<name>.har` in the test bundle by default.

In this package's own tests,
fixtures are stored at `Tests/ReplayTests/Replays/*.har` 
and copied into the test bundle via Swift Package Manager resources.

If you want to load fixtures from a specific bundle or directory, 
use the helper trait:

```swift
@Suite(.playbackIsolated(replaysFrom: Bundle.module))
struct MyAPITests { /* ... */ }
```

You can also configure `ReplayTrait` directly with `rootURL`
to specify a absolute or relative URL where `*.har` files can be found.

## Recording fixtures (explicit)

Replay only records when recording is enabled:

```bash
# Record everything in the current test run
REPLAY_RECORD=1 swift test

# Record a single test by name
REPLAY_RECORD=1 swift test --filter fetchUser

# Alternative: enable via custom argument (Swift Testing 6.1+)
swift test --enable-replay-recording
swift test --filter fetchUser --enable-replay-recording
```

If a fixture is missing and recording is *not* enabled, the test fails with instructions on how to record.

## Creating HAR files from browser sessions

Sometimes it's easier to capture HTTP traffic using your browser's developer tools rather than recording through tests. All major browsers can export network activity as HAR files.

> [!WARNING]
> HAR files may contain sensitive data including 
> cookies, authentication tokens, passwords, and personal information. 
> Always review and redact sensitive data before committing HAR files to version control.

### Safari

1. Enable the Develop menu: **Safari → Settings → Advanced → Show features for web developers**
2. Open Developer Tools: **Develop → Show Web Inspector** (or <kbd>⌥⌘I</kbd>)
3. Select the **Network** tab
4. Navigate to the page or trigger the API calls you want to capture
5. Right-click in the network list and choose **Export HAR**

### Chrome

1. Open Developer Tools: **View → Developer → Developer Tools** (or <kbd>⌥⌘I</kbd>)
2. Select the **Network** tab
3. Ensure recording is active (red circle in top-left)
4. Optionally enable **Preserve log** to keep requests across page loads
5. Navigate to the page or trigger the API calls you want to capture
6. Click the **↓** (download) button and choose **Save all as HAR with content**

### Firefox

1. Open Developer Tools: **Tools → Browser Tools → Web Developer Tools** (or <kbd>⌥⌘I</kbd>)
2. Select the **Network** tab
3. Optionally enable **Persist Logs** to keep requests across page loads
4. Navigate to the page or trigger the API calls you want to capture
5. Right-click in the network list and choose **Save All As HAR**

### Edge

1. Open Developer Tools: **Settings → More Tools → Developer Tools** (or <kbd>F12</kbd>)
2. Select the **Network** tab
3. Ensure recording is active and optionally enable **Preserve log**
4. Navigate to the page or trigger the API calls you want to capture
5. Click the **↓** (download) button and choose **Save all as HAR with content**

## Matching

Replay decides which HAR entry to serve using an array of `Matcher` values:

- `.method`
- `.url` (full absolute URL including query)
- `.host`
- `.path`
- `.query`
- `.headers([String])`
- `.body`
- `.custom((URLRequest, URLRequest) -> Bool)`

Default matching is **method + full URL** (`[Matcher].default`).

## Filtering (redacting secrets)

Filters run when recording.

- `Filter.headers(removing:replacement:)`
- `Filter.queryParameters(removing:replacement:)`
- `Filter.body(replacing:with:)`
- `Filter.body(decoding:transform:)`
- `Filter.custom(...)`

Example:

```swift
@Test(
    .replay(
        "fetchUser",
        matching: .method, .path,
        filters: .headers(removing: ["Authorization", "Cookie"]),
                 .queryParameters(removing: ["token", "api_key"]),
                 .body(decoding: User.self) { user in
                     var modified = user
                     modified.email = "redacted@example.com"
                     return modified
                 }
    )
)
func fetchUser() async throws { /* ... */ }
```

## Tooling

Replay includes a Swift Package Manager command plugin to help manage your HAR archives.

> [!NOTE]
> You may need to pass `--allow-writing-to-package-directory` 
> the first time you run commands that modify files (like clean or record),
> depending on your Swift Package Manager configuration.

```bash
# Check status of archives (age, orphans, etc.)
swift package replay status

# Record specific tests (wrapper around swift test)
swift package replay record fetchUser

# Inspect a HAR file
swift package replay inspect Tests/Replays/fetchUser.har

# Validate a HAR file
swift package replay validate Tests/Replays/fetchUser.har

# Filter sensitive data from an existing HAR
swift package replay filter input.har output.har --headers Authorization

# Clean up orphaned archives
swift package replay clean --dry-run
swift package replay clean
```

> [!TIP]
> `clean` is intentionally conservative — 
> it only considers explicitly named archives referenced as `.replay("name")` in `Tests/**/*.swift`.

## Stubbing (no HAR)

Sometimes you want a small, explicit stub instead of recording a HAR.

```swift
import Testing
import Replay

@Test(
    .replay(
        stubs: Stub(URL(string: "https://example.com/hello")!, status: 200, body: "OK")
    )
)
func stubbedRequest() async throws {
    let (data, _) = try await URLSession.shared.data(from: URL(string: "https://example.com/hello")!)
    #expect(String(data: data, encoding: .utf8) == "OK")
}
```

## Lower-level APIs

Replay can be used without Swift Testing:

- `HAR.load(from:)` / `HAR.save(_:to:)` for reading/writing HAR logs.
- `Playback.session(configuration:)` to create a `URLSession` that replays from a HAR.
- `PlaybackConfiguration.Source.stubs([Stub])` for in-memory playback without a HAR file.
- `Capture.session(configuration:)` to record traffic to a HAR file or handler.
- `Replay.session` / `Replay.configure(_:)` for convenience when you want Replay's `URLProtocol` inserted into a session configuration.

## License

This project is available under the MIT license.
See the LICENSE file for more info.
