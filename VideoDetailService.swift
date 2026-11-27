import Foundation

/// 视频详情能力抽象。对应 APK 分析中的 `/aweme/v1/aweme/detail/`（参数 `aweme_id`，响应键 `aweme_detail`）。
///
/// 合规：私有详情接口未授权前不直连；接入时由自有后端转发，客户端只调用自家后端契约。
protocol VideoDetailServicing {
    /// 按作品 ID 拉取详情。
    func fetchDetail(awemeID: String) async throws -> VideoItem
}

/// 授权后端详情实现（预留）。
final class AuthorizedBackendVideoDetailService: VideoDetailServicing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchDetail(awemeID: String) async throws -> VideoItem {
        guard client.isConfigured else {
            throw APIError.notConfigured("授权后端详情接口尚未配置。")
        }
        let endpoint = Endpoint(path: "/v1/douyin/detail/\(awemeID)")
        let dto: VideoDTO = try await client.get(endpoint, as: VideoDTO.self)
        return dto.toItem()
    }
}

/// 演示目录详情实现：在本地示例条目中按 ID 查找。
final class DemoVideoDetailService: VideoDetailServicing {
    func fetchDetail(awemeID: String) async throws -> VideoItem {
        let all = PublicDemoCatalog.loadPage(cursor: nil, limit: 100).items
        guard let item = all.first(where: { $0.id == awemeID }) else {
            throw APIError.emptyData
        }
        return item
    }
}
