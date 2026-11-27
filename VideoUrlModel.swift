import Foundation

/// 播放地址模型，对应 APK 静态分析中的 `feed/model/VideoUrlModel`（继承 `UrlModel`）。
///
/// 可播放 URL 位于 `urlList: [String]`；`ratio` 为清晰度档位，`sourceId` 为资源标识。
struct VideoUrlModel: Decodable, Equatable, Hashable {
    let uri: String?
    let urlList: [String]?
    let width: Int?
    let height: Int?
    let ratio: String?
    let sourceId: String?
    let vr: Bool?

    var firstURL: URL? {
        guard let raw = urlList?.first(where: { URL(string: $0) != nil }) else { return nil }
        return URL(string: raw)
    }

    enum CodingKeys: String, CodingKey {
        case uri
        case urlList
        case width
        case height
        case ratio
        case sourceId
        case vr
    }

    init(uri: String?, urlList: [String]?, width: Int?, height: Int?,
         ratio: String?, sourceId: String?, vr: Bool?) {
        self.uri = uri
        self.urlList = urlList
        self.width = width
        self.height = height
        self.ratio = ratio
        self.sourceId = sourceId
        self.vr = vr
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = try c.decodeIfPresent(String.self, forKey: .uri)
        self.width = try c.decodeIfPresent(Int.self, forKey: .width)
        self.height = try c.decodeIfPresent(Int.self, forKey: .height)
        self.ratio = try c.decodeIfPresent(String.self, forKey: .ratio)
        self.sourceId = try c.decodeIfPresent(String.self, forKey: .sourceId)
        self.vr = try c.decodeIfPresent(Bool.self, forKey: .vr)

        if let list = try c.decodeIfPresent([String].self, forKey: .urlList) {
            self.urlList = list
        } else {
            let snake = try decoder.container(keyedBy: SnakeKeys.self)
            self.urlList = try snake.decodeIfPresent([String].self, forKey: .urlList)
        }
    }

    private enum SnakeKeys: String, CodingKey {
        case urlList = "url_list"
    }
}
