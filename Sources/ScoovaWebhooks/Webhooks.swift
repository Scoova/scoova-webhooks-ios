import Foundation
import CryptoKit

// MARK: - Public model

public struct Webhook: Codable, Sendable {
    public let id: String
    public let url: String
    public let events: [String]
    public let active: Bool
    public let createdAt: Int64?
    public init(id: String, url: String, events: [String], active: Bool = true, createdAt: Int64? = nil) {
        self.id = id; self.url = url; self.events = events; self.active = active; self.createdAt = createdAt
    }
}

/// Returned only on creation. `secret` is shown once — persist it.
public struct WebhookCreated: Codable, Sendable {
    public let id: String
    public let url: String
    public let events: [String]
    public let secret: String
    public let createdAt: Int64
    public init(id: String, url: String, events: [String], secret: String, createdAt: Int64) {
        self.id = id; self.url = url; self.events = events; self.secret = secret; self.createdAt = createdAt
    }
}

public struct ScoovaWebhooksError: Error, CustomStringConvertible, Sendable {
    public let status: Int
    public let code: String?
    public let message: String
    public init(status: Int, code: String?, message: String) {
        self.status = status; self.code = code; self.message = message
    }
    public var description: String { "ScoovaWebhooksError(\(status), \(code ?? "-"), \(message))" }
}

// MARK: - Client

public struct WebhooksClientOptions: Sendable {
    public let apiKey: String
    public let baseURL: URL
    public let urlSession: URLSession

    /// API key resolution:
    ///   explicit `apiKey` → env `SCOOVA_API_KEY` → `"demo"`.
    public init(
        apiKey: String? = nil,
        baseURL: URL = URL(string: "https://api.scoo-va.info/api/v1")!,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = Self.resolveApiKey(apiKey)
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    private static func resolveApiKey(_ explicit: String?) -> String {
        if let k = explicit, !k.isEmpty { return k }
        if let env = ProcessInfo.processInfo.environment["SCOOVA_API_KEY"], !env.isEmpty { return env }
        return "demo"
    }
}

/// Standalone client for Scoova webhook subscriptions.
///
///     let client = WebhooksClient()                // reads SCOOVA_API_KEY
///     let all   = try await client.list()
///     let made  = try await client.create(url: "https://x.example", events: ["route.created"])
///     try await client.delete(made.id)
public final class WebhooksClient: @unchecked Sendable {

    private let opts: WebhooksClientOptions
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(_ opts: WebhooksClientOptions = WebhooksClientOptions()) {
        self.opts = opts
        let e = JSONEncoder(); e.outputFormatting = []
        self.encoder = e
        self.decoder = JSONDecoder()
    }

    /// List every webhook subscription on this project.
    public func list() async throws -> [Webhook] {
        let data = try await execute(request(url(path: "/webhooks"), method: "GET"))
        return try decodeList(data)
    }

    /// Create a subscription. Returned `secret` is shown only here.
    /// Throws if `url` isn't an `https://` URL — gateway requires it.
    public func create(url: String, events: [String]) async throws -> WebhookCreated {
        precondition(url.hasPrefix("https://"), "webhooks.create: url must start with https://")
        precondition(!events.isEmpty, "webhooks.create: events must be non-empty")
        struct Body: Encodable { let url: String; let events: [String] }
        let payload = try encoder.encode(Body(url: url, events: events))
        let data = try await execute(request(self.url(path: "/webhooks"), method: "POST", body: payload))
        return try decodeValue(data)
    }

    public func delete(_ id: String) async throws {
        precondition(!id.isEmpty, "webhooks.delete: id is required")
        _ = try await execute(request(url(path: "/webhooks/\(percentEncodedPathSegment(id))"), method: "DELETE"))
    }

    /// Alias for `delete(_:)` — matches the Dart/Flutter `remove()` naming.
    public func remove(_ id: String) async throws { try await delete(id) }

    // MARK: - internals

    private func url(path: String) -> URL {
        var comps = URLComponents()
        comps.scheme = opts.baseURL.scheme
        comps.host = opts.baseURL.host
        comps.port = opts.baseURL.port
        comps.path = opts.baseURL.path + (path.hasPrefix("/") ? path : "/" + path)
        return comps.url!
    }

    private func request(_ url: URL, method: String, body: Data? = nil) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue(opts.apiKey, forHTTPHeaderField: "X-API-Key")
        if let body {
            r.httpBody = body
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return r
    }

    private func execute(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await opts.urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw ScoovaWebhooksError(status: 0, code: nil, message: "no HTTP response")
        }
        if !(200..<300).contains(http.statusCode) {
            let (code, msg) = parseError(data)
            throw ScoovaWebhooksError(
                status: http.statusCode,
                code: code,
                message: msg ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }
        return data
    }

    private func parseError(_ data: Data) -> (String?, String?) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, nil)
        }
        return (obj["code"] as? String, obj["error"] as? String)
    }

    // Accept both `[ ... ]` and `{ "data": [ ... ] }`.
    private func decodeList(_ data: Data) throws -> [Webhook] {
        if data.isEmpty { return [] }
        if let direct = try? decoder.decode([Webhook].self, from: data) { return direct }
        struct Env: Decodable { let data: [Webhook]? }
        let env = try decoder.decode(Env.self, from: data)
        return env.data ?? []
    }

    private func decodeValue(_ data: Data) throws -> WebhookCreated {
        if data.isEmpty {
            throw ScoovaWebhooksError(status: 500, code: nil, message: "create response missing data")
        }
        if let direct = try? decoder.decode(WebhookCreated.self, from: data) { return direct }
        struct Env: Decodable { let data: WebhookCreated? }
        let env = try decoder.decode(Env.self, from: data)
        guard let w = env.data else {
            throw ScoovaWebhooksError(status: 500, code: nil, message: "create response missing data")
        }
        return w
    }
}

private func percentEncodedPathSegment(_ s: String) -> String {
    s.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)?
        .replacingOccurrences(of: "/", with: "%2F")
        ?? s
}

// MARK: - Signature verification

/// Verify a webhook signature on your server.
///
///     let ok = verifyWebhookSignature(body: rawBody,
///                                     headerValue: request.headers["x-scoova-signature"],
///                                     secret: subscriptionSecret)
///
/// Tolerates the `sha256=` prefix on the header. Uses constant-time comparison.
public func verifyWebhookSignature(body: String, headerValue: String?, secret: String) -> Bool {
    guard let h = headerValue, !h.isEmpty, !secret.isEmpty else { return false }
    let expected = (h.hasPrefix("sha256=") ? String(h.dropFirst(7)) : h).lowercased()
    let key = SymmetricKey(data: Data(secret.utf8))
    let sig = HMAC<SHA256>.authenticationCode(for: Data(body.utf8), using: key)
    let got = sig.map { String(format: "%02x", $0) }.joined()
    return constantTimeEqual(got, expected)
}

private func constantTimeEqual(_ a: String, _ b: String) -> Bool {
    guard a.count == b.count else { return false }
    var diff: UInt8 = 0
    let ab = Array(a.utf8), bb = Array(b.utf8)
    for i in 0..<ab.count { diff |= ab[i] ^ bb[i] }
    return diff == 0
}
