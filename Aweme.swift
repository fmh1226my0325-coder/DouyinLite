import Foundation

/// 单条作品模型，对应 APK 静态分析中的 `feed/model/Aweme`。
///
/// 合规说明：本模型仅用于在**已获得官方授权、由自有后端转发**的前提下解析数据。
/// 客户端不直连第三方私有接口，不携带 Cookie / 签名 / 设备标识。
struct Aweme: Decodable, Equatable, Hashable {
    /// 作品 ID。APK 内客户端字段名为 `aid`；其服务端原始 JSON key 静态未最终确认，
    /// 这里兼容 `aid` 与 `aweme_id` 两种命名。
    let aid: String?
    let desc: String?
    let author: User?
    let video: Video?
    let shareUrl: String?
    let createTime: Int?
    let awemeType: Int?
    let isAd: Bool?

    enum CodingKeys: String, CodingKey {
        case aid
        case awemeId
        case desc
        case author
        case video
        case shareUrl
        case createTime
        case awemeType
        case isAd
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.aid = try c.decodeIfPresent(String.self, forKey: .aid)
            ?? c.decodeIfPresent(String.self, forKey: .awemeId)
        self.desc = try c.decodeIfPresent(String.self, forKey: .desc)
        self.author = try c.decodeIfPresent(User.self, forKey: .author)
        self.video = try c.decodeIfPresent(Video.self, forKey: .video)
        self.shareUrl = try c.decodeIfPresent(String.self, forKey: .shareUrl)
        self.createTime = try c.decodeIfPresent(Int.self, forKey: .createTime)
        self.awemeType = try c.decodeIfPresent(Int.self, forKey: .awemeType)
        self.isAd = try c.decodeIfPresent(Bool.self, forKey: .isAd)
    }
}
