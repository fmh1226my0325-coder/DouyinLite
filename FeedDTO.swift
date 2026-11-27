import Foundation

// MARK: - 展示模型（App 内统一使用）

/// 列表与播放层统一使用的展示模型。
/// 数据源可以是已授权后端、官方开放平台，或本地公开示例目录。
struct VideoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let creator: String
    let creatorID: String?
    let signature: String?
    /// 可播放媒体地址。仅当平台/权利人明确授权在本 App 内播放时才存在；否则为 nil。
    let streamURL: URL?
    let coverURL: URL?
    let avatarURL: URL?
    /// 对外的作品页面链接，仅用于跳转网页，绝不交给 AVPlayer。
    let shareURL: URL?
    let attribution: String?

    static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 分页结果包装。
struct PagedResult<Element> {
    let items: [Element]
    let nextCursor: String?
    let hasMore: Bool
}

// MARK: - 已授权后端响应契约（DTO）

/// 授权后端 Feed 响应。契约见 `API_CONTRACT.md`。
/// 后端只应返回已授权可分发的数据；`video_url` 缺失时 App 不做地址猜测。
struct FeedResponse: Decodable {
    let videos: [VideoDTO]
    var nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case videos
        case nextCursor
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.videos = try c.decodeIfPresent([VideoDTO].self, forKey: .videos) ?? []
        if let cursor = try c.decodeIfPresent(String.self, forKey: .nextCursor) {
            self.nextCursor = cursor
        } else {
            let snake = try decoder.container(keyedBy: SnakeKeys.self)
            self.nextCursor = try snake.decodeIfPresent(String.self, forKey: .nextCursor)
        }
    }

    private enum SnakeKeys: String, CodingKey {
        case nextCursor = "next_cursor"
    }
}

struct VideoDTO: Decodable {
    let id: String
    var title: String?
    var author: String?
    var authorID: String?
    var signature: String?
    var videoURL: String?
    var shareURL: String?
    var coverURL: String?
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case authorID
        case signature
        case videoURL
        case shareURL
        case coverURL
        case avatarURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try c.decodeIfPresent(String.self, forKey: .title)
        self.author = try c.decodeIfPresent(String.self, forKey: .author)
        self.authorID = try c.decodeIfPresent(String.self, forKey: .authorID)
        self.signature = try c.decodeIfPresent(String.self, forKey: .signature)
        self.videoURL = try c.decodeIfPresent(String.self, forKey: .videoURL)
        self.shareURL = try c.decodeIfPresent(String.self, forKey: .shareURL)
        self.coverURL = try c.decodeIfPresent(String.self, forKey: .coverURL)
        self.avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)

        // 下划线命名容错。
        let snake = try decoder.container(keyedBy: SnakeKeys.self)
        if self.authorID == nil { self.authorID = try snake.decodeIfPresent(String.self, forKey: .authorID) }
        if self.videoURL == nil { self.videoURL = try snake.decodeIfPresent(String.self, forKey: .videoURL) }
        if self.shareURL == nil { self.shareURL = try snake.decodeIfPresent(String.self, forKey: .shareURL) }
        if self.coverURL == nil { self.coverURL = try snake.decodeIfPresent(String.self, forKey: .coverURL) }
        if self.avatarURL == nil { self.avatarURL = try snake.decodeIfPresent(String.self, forKey: .avatarURL) }
    }

    private enum SnakeKeys: String, CodingKey {
        case authorID = "author_id"
        case videoURL = "video_url"
        case shareURL = "share_url"
        case coverURL = "cover_url"
        case avatarURL = "avatar_url"
    }

    func toItem() -> VideoItem {
        VideoItem(
            id: id,
            title: title ?? "未命名作品",
            creator: author ?? "未知作者",
            creatorID: authorID,
            signature: signature,
            streamURL: videoURL.flatMap(URL.init(string:)),
            coverURL: coverURL.flatMap(URL.init(string:)),
            avatarURL: avatarURL.flatMap(URL.init(string:)),
            shareURL: shareURL.flatMap(URL.init(string:)),
            attribution: nil
        )
    }
}

// MARK: - 私有/官方接口模型 → 展示模型映射（授权后预留）

extension Aweme {
    /// 将 APK 分析结构映射为展示模型。仅在数据来源已授权时调用。
    func toItem() -> VideoItem {
        let cover = video?.preferredCover?.firstURL
        let stream = video?.playAddr?.firstURL
        let avatar = author?.preferredAvatar?.firstURL
        return VideoItem(
            id: aid ?? UUID().uuidString,
            title: desc ?? "未命名作品",
            creator: author?.displayName ?? "未知作者",
            creatorID: author?.uid,
            signature: author?.signature,
            streamURL: stream,
            coverURL: cover,
            avatarURL: avatar,
            shareURL: shareUrl.flatMap(URL.init(string:)),
            attribution: nil
        )
    }
}
