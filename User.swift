import Foundation

/// 作者模型，对应 APK 静态分析中的 `profile/model/User`。
///
/// 仅建模展示所需的公开资料字段；第三方绑定、登录态、隐私类字段按合规要求不纳入。
struct User: Decodable, Equatable, Hashable {
    let uid: String?
    let uniqueId: String?
    let shortId: String?
    let nickname: String?
    let signature: String?
    let avatarThumb: UrlModel?
    let avatarMedium: UrlModel?
    let avatarLarger: UrlModel?
    let followerCount: Int?
    let fansCount: Int?
    let followingCount: Int?
    let gender: Int?
    let city: String?
    let isVerified: Bool?

    /// 展示用昵称：优先 nickname，其次 uniqueId / shortId。
    var displayName: String {
        nickname ?? uniqueId ?? shortId ?? "未知作者"
    }

    var preferredAvatar: UrlModel? {
        avatarLarger ?? avatarMedium ?? avatarThumb
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case uniqueId
        case shortId
        case nickname
        case signature
        case avatarThumb
        case avatarMedium
        case avatarLarger
        case followerCount
        case fansCount
        case followingCount
        case gender
        case city
        case isVerified
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try c.decodeIfPresent(String.self, forKey: .uid)
        self.uniqueId = try c.decodeIfPresent(String.self, forKey: .uniqueId)
        self.shortId = try c.decodeIfPresent(String.self, forKey: .shortId)
        self.nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        self.signature = try c.decodeIfPresent(String.self, forKey: .signature)
        self.avatarThumb = try c.decodeIfPresent(UrlModel.self, forKey: .avatarThumb)
        self.avatarMedium = try c.decodeIfPresent(UrlModel.self, forKey: .avatarMedium)
        self.avatarLarger = try c.decodeIfPresent(UrlModel.self, forKey: .avatarLarger)
        self.followerCount = try c.decodeIfPresent(Int.self, forKey: .followerCount)
        self.fansCount = try c.decodeIfPresent(Int.self, forKey: .fansCount)
        self.followingCount = try c.decodeIfPresent(Int.self, forKey: .followingCount)
        self.gender = try c.decodeIfPresent(Int.self, forKey: .gender)
        self.city = try c.decodeIfPresent(String.self, forKey: .city)
        self.isVerified = try c.decodeIfPresent(Bool.self, forKey: .isVerified)
    }
}
