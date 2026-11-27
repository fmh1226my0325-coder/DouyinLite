import Foundation

/// 视频媒体模型，对应 APK 静态分析中的 `feed/model/Video`。
struct Video: Decodable, Equatable, Hashable {
    let cover: UrlModel?
    let dynamicCover: UrlModel?
    let originCover: UrlModel?
    let playAddr: VideoUrlModel?
    let downloadAddr: UrlModel?
    let newDownloadAddr: UrlModel?
    let hasWaterMark: Bool?
    let width: Int?
    let height: Int?
    let videoLength: Int?
    let ratio: String?

    /// 首选封面：动态封面 > 普通封面 > 原始封面。
    var preferredCover: UrlModel? {
        dynamicCover ?? cover ?? originCover
    }

    enum CodingKeys: String, CodingKey {
        case cover
        case dynamicCover
        case originCover
        case playAddr
        case downloadAddr
        case newDownloadAddr
        case hasWaterMark
        case width
        case height
        case videoLength
        case ratio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.cover = try c.decodeIfPresent(UrlModel.self, forKey: .cover)
        self.dynamicCover = try c.decodeIfPresent(UrlModel.self, forKey: .dynamicCover)
        self.originCover = try c.decodeIfPresent(UrlModel.self, forKey: .originCover)
        self.playAddr = try c.decodeIfPresent(VideoUrlModel.self, forKey: .playAddr)
        self.downloadAddr = try c.decodeIfPresent(UrlModel.self, forKey: .downloadAddr)
        self.newDownloadAddr = try c.decodeIfPresent(UrlModel.self, forKey: .newDownloadAddr)
        self.hasWaterMark = try c.decodeIfPresent(Bool.self, forKey: .hasWaterMark)
        self.width = try c.decodeIfPresent(Int.self, forKey: .width)
        self.height = try c.decodeIfPresent(Int.self, forKey: .height)
        self.videoLength = try c.decodeIfPresent(Int.self, forKey: .videoLength)
        self.ratio = try c.decodeIfPresent(String.self, forKey: .ratio)
    }
}
