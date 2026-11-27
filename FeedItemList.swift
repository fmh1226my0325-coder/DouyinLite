import Foundation

/// Feed 列表响应模型，对应 APK 静态分析中的 `feed/model/FeedItemList`。
///
/// 仅作为授权后端转发私有/官方接口时的解析预留；App 默认不直连该结构对应的私有域名。
struct FeedItemList: Decodable, Equatable, Hashable {
    let items: [Aweme]
    var hasMore: Bool?
    var maxCursor: Int64?
    var minCursor: Int64?
    var requestId: String?

    enum CodingKeys: String, CodingKey {
        case items
        case hasMore
        case maxCursor
        case minCursor
        case requestId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try c.decodeIfPresent([Aweme].self, forKey: .items) ?? []
        self.hasMore = try c.decodeIfPresent(Bool.self, forKey: .hasMore)
        self.maxCursor = try c.decodeIfPresent(Int64.self, forKey: .maxCursor)
        self.minCursor = try c.decodeIfPresent(Int64.self, forKey: .minCursor)
        self.requestId = try c.decodeIfPresent(String.self, forKey: .requestId)

        // 下划线命名容错：仅在驼峰键缺失时补充。
        let snake = try decoder.container(keyedBy: SnakeKeys.self)
        if self.hasMore == nil {
            self.hasMore = try snake.decodeIfPresent(Bool.self, forKey: .hasMore)
        }
        if self.maxCursor == nil {
            self.maxCursor = try snake.decodeIfPresent(Int64.self, forKey: .maxCursor)
        }
        if self.minCursor == nil {
            self.minCursor = try snake.decodeIfPresent(Int64.self, forKey: .minCursor)
        }
        if self.requestId == nil {
            self.requestId = try snake.decodeIfPresent(String.self, forKey: .requestId)
        }
    }

    private enum SnakeKeys: String, CodingKey {
        case hasMore = "has_more"
        case maxCursor = "max_cursor"
        case minCursor = "min_cursor"
        case requestId = "request_id"
    }
}
