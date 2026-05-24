# Changelog

All notable changes to `ScoovaWebhooks` (Swift) are recorded here.
This project follows [Semantic Versioning](https://semver.org/).

## 1.0.0 — 2026-05-25

First public release.

- `WebhooksClient` — `list()`, `create(url:events:)`, `delete(_:)` /
  `remove(_:)` against `https://api.scoo-va.info/v1/webhooks/*`.
- Top-level `verifyWebhookSignature(body:headerValue:secret:)` — HMAC-SHA256
  via CryptoKit, constant-time comparison, tolerates the `sha256=` prefix.
- Platforms: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+. Swift 5.9.
- API key resolution: explicit option → `SCOOVA_API_KEY` env → `"demo"`.
- `ScoovaWebhooksError` carries the gateway's structured `status` + `code`.
