import Foundation

/// 本地公开示例目录（离线演示用）。
///
/// 合规声明：这里的视频是 Blender Foundation 的公开样片 **Big Buck Bunny**（CC BY 3.0），
/// **不是抖音作品**，也不代表已接入任何真实推荐流。仅用于验证分页、自动播放、重试等 UI 与播放链路。
/// 接入授权后端后，此目录仅作为后端不可用时的回退演示。
enum PublicDemoCatalog {
    static let attribution = "CC BY 3.0 · Blender Foundation · peach.blender.org"

    private static let stream = URL(string:
        "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4")!

    /// 演示条目：同一公开样片，用于验证分页切换；标题明确标注为演示。
    private static let entries: [VideoItem] = [
        VideoItem(
            id: "demo-bbb-01",
            title: "公开样片演示 1 · Big Buck Bunny",
            creator: "Blender Foundation",
            creatorID: nil,
            signature: "离线公开样片，非抖音内容",
            streamURL: stream,
            coverURL: nil,
            avatarURL: nil,
            shareURL: nil,
            attribution: attribution
        ),
        VideoItem(
            id: "demo-bbb-02",
            title: "公开样片演示 2 · Big Buck Bunny",
            creator: "Blender Foundation",
            creatorID: nil,
            signature: "离线公开样片，非抖音内容",
            streamURL: stream,
            coverURL: nil,
            avatarURL: nil,
            shareURL: nil,
            attribution: attribution
        ),
        VideoItem(
            id: "demo-bbb-03",
            title: "公开样片演示 3 · Big Buck Bunny",
            creator: "Blender Foundation",
            creatorID: nil,
            signature: "离线公开样片，非抖音内容",
            streamURL: stream,
            coverURL: nil,
            avatarURL: nil,
            shareURL: nil,
            attribution: attribution
        )
    ]

    /// 按游标模拟分页。cursor 为偏移量字符串；首页为 nil。
    static func loadPage(cursor: String?, limit: Int) -> PagedResult<VideoItem> {
        let offset = Int(cursor ?? "") ?? 0
        let slice = entries[offset..<min(offset + limit, entries.count)]
        let nextOffset = offset + slice.count
        let hasMore = nextOffset < entries.count
        return PagedResult(
            items: Array(slice),
            nextCursor: hasMore ? String(nextOffset) : nil,
            hasMore: hasMore
        )
    }
}
