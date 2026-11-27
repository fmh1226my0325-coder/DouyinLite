import Foundation

/// 基础媒体地址模型，对应 APK 静态分析中的 `base/model/UrlModel`。
///
/// 字段映射来自离线静态分析；服务端 JSON 的原始 key 未在 APK 内静态最终确认，
/// 因此这里对常见命名（驼峰/下划线）做了容错解码。
///
/// - `urlList`: 可访问地址列表；实际交给 AVPlayer 的只应是已授权可播放的媒体地址。
/// - `uri`: 单值资源标识。
struct UrlModel: Decodable, Equatable, Hashable {
    let uri: String?
    let urlList: [String]?
    let width: Int?
    let height: Int?

    /// 列表里第一个可用地址，便于展示层取封面/播放地址。
    var firstURL: URL? {
        guard let raw = urlList?.first(where: { URL(string: $0) != nil }) else { return nil }
        return URL(string: raw)
    }

    enum CodingKeys: String, CodingKey {
        case uri
        case urlList
        case width
        case height
    }

    init(uri: String?, urlList: [String]?, width: Int?, height: Int?) {
        self.uri = uri
        self.urlList = urlList
        self.width = width
        self.height = height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = try container.decodeIfPresent(String.self, forKey: .uri)
        self.width = try container.decodeIfPresent(Int.self, forKey: .width)
        self.height = try container.decodeIfPresent(Int.self, forKey: .height)

        // 兼容 urlList / url_list 两种命名。
        if let list = try container.decodeIfPresent([String].self, forKey: .urlList) {
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
