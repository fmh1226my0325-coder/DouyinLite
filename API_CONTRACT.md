# DouyinLite 后端 API 契约（v0.6）

iPhone 与 Apple Watch 各自独立调用同一套自有后端接口；Watch 不通过 iPhone 中继。

> 本契约描述的是**你自己控制的授权后端**。客户端不直接请求任何第三方私有域名。
> 后端在服务端完成官方接口调用、令牌保管、签名与风控合规，只把已授权可分发的结果返回给 App。

## 1. Feed 列表

`GET /v1/douyin/hot?limit=8&cursor=<opaque-cursor>`

| 参数 | 类型 | 说明 |
|---|---|---|
| `limit` | int | 本页条数，App 请求 8 |
| `cursor` | string | 上一页返回的 `next_cursor`，首页省略 |

### 响应

```json
{
  "videos": [
    {
      "id": "platform-item-id",
      "title": "视频标题",
      "author": "创作者昵称",
      "author_id": "creator-id",
      "signature": "作者简介",
      "video_url": "https://authorized-cdn.example/path/stream.m3u8",
      "share_url": "https://www.douyin.com/video/...",
      "cover_url": "https://example.com/cover.jpg",
      "avatar_url": "https://example.com/avatar.jpg"
    }
  ],
  "next_cursor": "opaque-cursor-or-null"
}
```

- `videos`：当前页条目，条数不超过 `limit`。
- `next_cursor`：无下一页时返回 `null`。

### 字段语义

- `video_url`：仅当平台或权利人明确授权在本 App 内播放时填写；这是**唯一**传给 AVPlayer 的媒体地址。
- `share_url`：对外作品页面链接，仅用于打开网页，**绝不**交给 AVPlayer。
- `cover_url` / `avatar_url`：图片地址，不交给 AVPlayer。
- 禁止把分享页面链接猜测、拼接成媒体地址。

## 2. 视频详情（预留）

`GET /v1/douyin/detail/{aweme_id}`

### 响应

单条 `VideoDTO`（结构同上表条目）。对应 APK 静态分析中的私有详情接口 `/aweme/v1/aweme/detail/`（入参 `aweme_id`，响应键 `aweme_detail`）；该私有接口未授权前不直连。

## 3. 鉴权

- 后端颁发短期 `access_token` 与可选 `refresh_token`，由客户端存入 Keychain（`TokenStore`）。
- 请求带 `Authorization: Bearer <access_token>`。
- 401 时客户端用刷新令牌换取新令牌，最多重试一次；仍失败则走未授权提示。
- **客户端不保存**第三方 Cookie、密码、长期会话或请求签名；这些只留在服务端。

## 4. 安全与运营建议

- 仅使用 HTTPS。
- 服务端限流；播放地址使用短期签名 URL。
- 每个作品返回稳定唯一 `id`；列表分页不要无界返回。
- App 不持久化浏览历史、不下载视频文件到自身存储。

## 5. 官方来源限制说明

官方热点/排行类能力通常只提供排行元数据与作品页面链接，不等于通用实时推荐流，也不必然提供可被第三方直接播放的 MP4/HLS 地址。接入公开抖音内容前应：

1. 取得对应抖音开放平台应用能力与审批；
2. 确认在本 App 内展示/播放的权利范围；
3. 部署只调用已授权接口的后端；
4. 仅填入明确授权的媒体地址；
5. 密钥与令牌留在服务端。

不得逆向私有接口、盗用/重放 Cookie、绕过签名或规避访问控制。
