import Foundation

/// 描述一个授权后端请求端点。
struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]

    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }
}

/// 统一网络客户端。
///
/// 只与**已配置的授权后端**通信；不直连第三方私有接口，不生成签名，不携带 Cookie。
/// 令牌由 `AuthProviding` 提供，401 时最多刷新一次后重试。
final class APIClient {
    private let baseURL: URL?
    private let auth: AuthProviding?
    private let session: URLSession

    init(baseURL: URL?, auth: AuthProviding? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.auth = auth
        self.session = session
    }

    /// 后端是否已配置基础地址。未配置时上层应回退到公开示例目录。
    var isConfigured: Bool {
        baseURL != nil
    }

    func get<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        guard let baseURL else { throw APIError.notConfigured("后端基础地址未配置。") }
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems

        guard var request = components?.url.map(URLRequest.init) else {
            throw APIError.invalidURL
        }
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let credential = auth?.currentCredential(), !credential.accessToken.isEmpty {
            request.setValue("Bearer \(credential.accessToken)", forHTTPHeaderField: "Authorization")
        }

        return try await send(request, as: type, isRetryAfterRefresh: false)
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type, isRetryAfterRefresh: Bool) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.network("无 HTTP 响应")
        }

        // 401：刷新一次令牌后重试；已重试过则直接判为未授权。
        if http.statusCode == 401, !isRetryAfterRefresh, let auth {
            do {
                _ = try await auth.refreshCredential()
                var retried = request
                if let credential = auth.currentCredential() {
                    retried.setValue("Bearer \(credential.accessToken)", forHTTPHeaderField: "Authorization")
                }
                return try await send(retried, as: type, isRetryAfterRefresh: true)
            } catch is APIError {
                throw APIError.unauthorized
            } catch {
                throw APIError.unauthorized
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, nil)
        }

        guard !data.isEmpty else { throw APIError.emptyData }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }
}
