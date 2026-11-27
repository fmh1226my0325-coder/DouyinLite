import Foundation
import Security

/// 授权后端下发的短期凭证。
/// 注意：这里只保存自家后端颁发的访问/刷新令牌；不保存第三方 Cookie、签名或设备标识。
struct AuthCredential: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiry: Date?

    var isExpired: Bool {
        guard let expiry else { return false }
        return expiry <= Date().addingTimeInterval(30)
    }
}

/// 基于 Keychain 的安全存储。iOS 与 watchOS 通过共享 Keychain 访问同一份凭证。
final class TokenStore {
    private let service: String
    private let account = "douyinlite-credential"

    init(service: String = "com.jionzyk.douyinlite.credential") {
        self.service = service
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func save(_ credential: AuthCredential) throws {
        let data = try JSONEncoder().encode(credential)
        var query = self.query
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let update: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(self.query as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else { throw APIError.unknown("令牌更新失败，状态码 \(updateStatus)") }
        } else if status != errSecSuccess {
            throw APIError.unknown("令牌保存失败，状态码 \(status)")
        }
    }

    func load() -> AuthCredential? {
        var query = self.query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthCredential.self, from: data)
    }

    func clear() {
        SecItemDelete(self.query as CFDictionary)
    }
}
