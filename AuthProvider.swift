import Foundation

/// 鉴权能力预留协议。
///
/// 真实接入官方开放平台或自有授权后端时，实现该协议完成 OAuth 授权、令牌读取与刷新。
/// 当前版本仅提供安全存储与刷新钩子，不内置任何第三方登录跳转、Cookie 复用或签名生成。
protocol AuthProviding {
    /// 当前本地凭证（可能已过期，调用方应结合 `isExpired` 判断）。
    func currentCredential() -> AuthCredential?

    /// 使用刷新令牌换取新的访问令牌；无刷新令牌或后端未配置时抛错。
    func refreshCredential() async throws -> AuthCredential

    /// 发起授权流程（预留）。需要接入官方开放平台后实现。
    func authorize() async throws -> AuthCredential
}

/// 默认鉴权实现：基于 `TokenStore` 读写，刷新端点由配置注入。
final class AppAuthProvider: AuthProviding {
    private let store: TokenStore
    private let refreshEndpoint: URL?
    private let session: URLSession

    init(store: TokenStore = TokenStore(),
         refreshEndpoint: URL? = nil,
         session: URLSession = .shared) {
        self.store = store
        self.refreshEndpoint = refreshEndpoint
        self.session = session
    }

    func currentCredential() -> AuthCredential? {
        store.load()
    }

    func refreshCredential() async throws -> AuthCredential {
        guard let credential = store.load(), let refresh = credential.refreshToken else {
            throw APIError.unauthorized
        }
        guard let refreshEndpoint else {
            // 后端刷新端点尚未配置：保留本地凭证，由上层走“待授权”提示。
            throw APIError.notConfigured("令牌刷新端点尚未配置。")
        }

        var request = URLRequest(url: refreshEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["refresh_token": refresh]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.network("无响应") }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, nil)
        }

        let refreshed = try JSONDecoder().decode(AuthCredential.self, from: data)
        try store.save(refreshed)
        return refreshed
    }

    func authorize() async throws -> AuthCredential {
        // 预留：接入官方开放平台授权页 / 授权码交换后，在此保存凭证。
        throw APIError.notConfigured("官方授权流程尚未接入，等待开放平台能力审批。")
    }
}
