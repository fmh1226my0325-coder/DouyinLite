import Foundation

/// Feed 加载能力抽象，便于替换授权后端、官方开放平台或本地演示目录。
protocol FeedServicing {
    /// 加载一页视频。
    /// - Parameters:
    ///   - cursor: 上一页返回的游标，首页传 nil。
    ///   - limit: 本页条数。
    func loadFeed(cursor: String?, limit: Int) async throws -> PagedResult<VideoItem>
}

/// 已授权后端实现：请求自有后端的 Feed 契约接口。
final class AuthorizedBackendFeedService: FeedServicing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func loadFeed(cursor: String?, limit: Int) async throws -> PagedResult<VideoItem> {
        guard client.isConfigured else {
            throw APIError.notConfigured("授权后端地址尚未配置。")
        }

        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor, !cursor.isEmpty {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let response: FeedResponse = try await client.get(
            Endpoint(path: "/v1/douyin/hot", queryItems: query),
            as: FeedResponse.self
        )

        let items = response.videos.map { $0.toItem() }
        return PagedResult(
            items: items,
            nextCursor: response.nextCursor,
            hasMore: response.nextCursor != nil
        )
    }
}

/// 本地公开示例实现：离线验证分页与播放链路。
final class DemoFeedService: FeedServicing {
    func loadFeed(cursor: String?, limit: Int) async throws -> PagedResult<VideoItem> {
        // 模拟网络延迟，便于展示加载态。
        try await Task.sleep(nanoseconds: 120_000_000)
        return PublicDemoCatalog.loadPage(cursor: cursor, limit: limit)
    }
}

/// Feed 门面：按后端是否已配置选择数据源。
///
/// - 后端已配置且可用：走授权后端。
/// - 未配置/未授权：回退公开示例目录，并通过 `isUsingDemoData` 告知界面标注“演示数据”。
final class FeedService: FeedServicing {
    private let backend: AuthorizedBackendFeedService
    private let demo: DemoFeedService
    private let backendConfigured: Bool

    /// 最近一次是否使用了演示数据。
    private(set) var isUsingDemoData = false

    init(client: APIClient) {
        self.backend = AuthorizedBackendFeedService(client: client)
        self.demo = DemoFeedService()
        self.backendConfigured = client.isConfigured
    }

    func loadFeed(cursor: String?, limit: Int) async throws -> PagedResult<VideoItem> {
        guard backendConfigured else {
            isUsingDemoData = true
            return try await demo.loadFeed(cursor: cursor, limit: limit)
        }
        do {
            let result = try await backend.loadFeed(cursor: cursor, limit: limit)
            isUsingDemoData = false
            return result
        } catch {
            // 后端异常时不伪造后端数据；回退演示目录并明确标注。
            isUsingDemoData = true
            return try await demo.loadFeed(cursor: cursor, limit: limit)
        }
    }
}
