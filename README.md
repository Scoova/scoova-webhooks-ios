# ScoovaWebhooks (Swift)

Standalone Swift client for Scoova webhook subscriptions plus an HMAC-SHA256
signature verifier using CryptoKit. iOS 15+, macOS 12+, tvOS 15+, watchOS 8+.

## Install (Swift Package Manager)

`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Scoova/scoova-webhooks-ios.git", from: "1.0.1"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "ScoovaWebhooks", package: "scoova-webhooks-ios"),
    ]),
]
```

## Usage

```swift
import ScoovaWebhooks

let client = WebhooksClient()  // reads SCOOVA_API_KEY from env, or use "demo"
let all   = try await client.list()
let made  = try await client.create(url: "https://example.com/scoova",
                                    events: ["route.created"])
try await client.delete(made.id)

// In your server handler:
let ok = verifyWebhookSignature(
    body: rawBody,
    headerValue: request.headers["X-Scoova-Signature"],
    secret: subscriptionSecret
)
```

Pass explicit options when you need to:

```swift
WebhooksClient(
    WebhooksClientOptions(
        apiKey: "sk_live_...",
        baseURL: URL(string: "https://api.scoo-va.info/v1")!
    )
)
```

## Build

```sh
swift build
swift test
```

## License

Apache-2.0
