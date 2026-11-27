import Foundation

/// 全局配置。
///
/// 接入已授权后端时，把 `backendBaseURL` 填为自有后端域名（HTTPS）。
/// 保持 nil 时，App 使用本地公开示例目录做离线演示，不会直连任何第三方私有接口。
enum AppConfiguration {
    /// 自有授权后端基础地址，例如 `https://api.your-backend.example`。
    /// 暂未获得授权前保持 nil。
    static let backendBaseURL: URL? = nil

    /// 每页条数。
    static let pageSize: Int = 8
}
