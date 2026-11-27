# 授权与验收状态清单（v0.6）

本清单区分三类状态：

- **已完成**：源码内已实现，可在 Xcode/macOS 构建后验证。
- **待授权**：架构已预留，但需官方开放平台审批或自有后端部署后才能接通。
- **待测试**：代码已写，但本 Linux 环境无 Xcode，未做真实构建/装机验证。

## 一、功能验收对照

### iPhone

| 项 | 状态 | 依据 |
|---|---|---|
| 上下滑动切换视频 | 已完成 | `iOS/FeedView.swift` paging 分页 |
| 自动播放 / 暂停 | 已完成 | `VideoPlaybackManager.play/togglePlayback` |
| 视频预加载 | 已完成 | `FeedPreloader` 缓冲前后半径条目，命中复用 |
| 封面 / 作者 / 昵称 / 描述 | 已完成 | `VideoPage` 绑定 `coverURL/avatarURL/creator/title/signature` |
| 播放失败重试 | 已完成 | 单条 `retry` + 整页 `loadFirst` |
| 连续加载列表 | 已完成 | `loadMore` 游标分页 |
| 网络错误 / 空数据处理 | 已完成 | `APIError` 分类 + 错误态/空态视图 |
| AVPlayer 播放真实有效地址 | 待测试 | 公开示例流可播放；授权媒体地址待后端配置 |

### API 接入

| 项 | 状态 | 依据 |
|---|---|---|
| 统一 APIClient | 已完成 | `Networking/APIClient.swift` |
| FeedService | 已完成 | `Networking/FeedService.swift` |
| VideoDetailService | 已完成（预留） | `Networking/VideoDetailService.swift`，未接私有详情 |
| Decodable 数据模型 | 已完成 | `Shared/Models/*` |
| OAuth 授权接口预留 | 待授权 | `AuthProviding` 协议；`authorize()` 未接通 |
| Token 安全存储与刷新 | 已完成（预留框架） | `TokenStore` Keychain；401 刷新一次；真实刷新端点待配置 |
| API 错误处理 | 已完成 | `APIError` |
| 官方开放平台接入预留 | 待授权 | 后端层对接后切换数据源 |

### Apple Watch（独立 App）

| 项 | 状态 | 依据 |
|---|---|---|
| 独立联网获取列表 | 已完成 | Watch 自建 `FeedService` 实例 |
| 独立播放视频 | 已完成 | 独立 `VideoPlaybackManager` / AVPlayer |
| 上一条 / 下一条 | 已完成 | `WatchFeedView.move(by:)` |
| 标题与作者 | 已完成 | `header(for:)` |
| 网络失败提示重试 | 已完成 | 错误态 + 重试按钮 |
| 不依赖 iPhone 实时传输 | 已完成 | `WKRunsIndependentlyOfCompanionApp = YES` |
| Watch App Embed 配置 | 已完成 | `project.yml` iOS target 依赖 embed |

## 二、交付物状态

| 交付项 | 状态 | 说明 |
|---|---|---|
| 完整 v0.6 源码 ZIP | 已完成 | 见随附压缩包 |
| 完整 Xcode 工程 | 已完成（需生成） | 提供 `project.yml`，macOS 上 `xcodegen generate` 生成 `.xcodeproj` |
| iOS 与 watchOS 双 Target | 已完成 | `project.yml` |
| GitHub Actions 自动构建 | 已完成 | `.github/workflows/ios-watchos-ci.yml` |
| 嵌入 Watch App 的归档配置 | 已完成 | 依赖 embed + CI archive 步骤 |
| 可安装测试的 IPA | **待测试 / 未产出** | 本环境无 Xcode，未真实构建；IPA 需在 macOS 或 CI runner 归档导出 |
| README | 已完成 | `README.md` |

## 三、明确未做 / 未接通的内容

- 未直连 `/aweme/v1/feed/`、`/aweme/v1/aweme/detail/` 等私有域名。
- 未提取、未复用任何账号令牌、Cookie、密钥或设备标识。
- 未伪造真实抖音 Feed；演示条目明确标注为公开样片。
- 未实现真实 OAuth 登录跳转；授权流程为协议预留。
- 未在本环境执行 `xcodebuild`，因此不声称编译通过；构建结论以 macOS / CI 实际产物为准。

## 四、上线前必须补齐

1. 官方开放平台能力审批与授权码交换实现。
2. 自有后端部署，返回已授权 `video_url`。
3. 在 macOS 或 CI 上真实构建，确认模拟器/真机运行无编译错误。
4. 归档导出 IPA 并在目标 iOS / watchOS 版本上装机验证。
