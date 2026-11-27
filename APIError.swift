import Foundation

/// 统一 API 错误类型。区分可重试的网络/服务端错误与不可重试的配置/授权错误。
enum APIError: Error, Equatable, LocalizedError {
    case invalidURL
    /// 后端地址或授权能力尚未配置完成，属于“待授权/待配置”，不是网络故障。
    case notConfigured(String)
    /// 鉴权失败，且刷新令牌后仍未恢复。
    case unauthorized
    /// 网络层错误（超时、连接中断等），通常可重试。
    case network(String)
    /// 响应解码失败。
    case decoding(String)
    /// 非 2xx HTTP 状态码。
    case httpStatus(Int, String?)
    case emptyData
    /// 数据存在，但没有已授权可播放的媒体地址。
    case mediaNotAuthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效。"
        case .notConfigured(let detail):
            return "数据源尚未配置或未获得授权：\(detail)"
        case .unauthorized:
            return "登录态已失效，请重新授权。"
        case .network(let detail):
            return "网络连接失败：\(detail)"
        case .decoding(let detail):
            return "数据解析失败：\(detail)"
        case .httpStatus(let code, let message):
            return "请求失败（\(code)）\(message ?? "")"
        case .emptyData:
            return "暂无可展示的内容。"
        case .mediaNotAuthorized:
            return "该作品未授权在本 App 内播放。"
        case .unknown(let detail):
            return detail
        }
    }

    /// 是否允许用户点击“重试”。
    var isRetryable: Bool {
        switch self {
        case .network, .httpStatus, .emptyData, .unknown:
            return true
        case .invalidURL, .notConfigured, .unauthorized, .decoding, .mediaNotAuthorized:
            return false
        }
    }
}
