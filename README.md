# DouyinLite v0.6

一个 SwiftUI 短视频浏览骨架应用，包含 **iOS App** 与 **独立 watchOS App** 两个 Target。
本版本在 v0.4.1 基础上补全了分层网络架构、授权预留、分页预加载、错误/空态处理，以及 Watch 独立联网播放。

> **合规与现状声明（务必先读）**
>
> - 本工程**未接入**抖音/字节私有接口，不携带 Cookie、签名、设备标识，不做风控绕过。
> - 当前默认数据源是 **Blender Foundation 公开样片 Big Buck Bunny（CC BY 3.0）**，属于离线演示，**不是抖音作品**，界面上已明确标注。
> - 私有 Feed/详情接口仅在模型层做了结构预留；真正取数需要先获得官方开放平台能力审批，并由**自有后端**转发已授权数据。
> - 本源码在 **Linux 环境**编写，该环境无 Xcode / `xcodebuild`，**未在此环境执行真实构建，也未产出 IPA**。真实构建、签名与装机必须在 macOS + Xcode 上完成，或由仓库的 GitHub Actions（macos runner）产出未签名包。

---

## 一、技术栈

- Swift 5.9 / SwiftUI
- iOS 17.0+ / watchOS 10.0+
- AVFoundation / AVPlayer / AVKit
- URLSession 网络层
- XcodeGen 生成 `.xcodeproj`

## 二、目录结构

```
DouyinLite-v0.6/
├── project.yml                 # XcodeGen 工程定义（双 Target + Watch embed）
├── Shared/
│   ├── Configuration.swift     # 后端基础地址等全局配置
│   ├── Models/                 # Decodable 模型（对齐 APK 静态分析结构）
│   │   ├── UrlModel.swift
│   │   ├── VideoUrlModel.swift
│   │   ├── Video.swift
│   │   ├── User.swift
│   │   ├── Aweme.swift
│   │   ├── FeedItemList.swift
│   │   └── FeedDTO.swift       # 授权后端契约 DTO + 展示模型 VideoItem
│   ├── Networking/
│   │   ├── APIError.swift
│   │   ├── APIClient.swift
│   │   ├── AuthProvider.swift   # OAuth / 令牌刷新预留
│   │   ├── TokenStore.swift    # Keychain 安全存储
│   │   ├── FeedService.swift
│   │   ├── VideoDetailService.swift
│   │   └── PublicDemoCatalog.swift
│   └── Playback/
│       ├── VideoPlaybackManager.swift
│       └── FeedPreloader.swift
├── iOS/
│   ├── DouyinLiteApp.swift
│   └── FeedView.swift
└── Watch/
    ├── DouyinLiteWatchApp.swift
    └── WatchFeedView.swift
```

## 三、本地编译步骤（macOS + Xcode）

1. 安装 XcodeGen：
   ```bash
   brew install xcodegen
   ```
2. 进入 `DouyinLite-v0.6/` 目录，生成工程：
   ```bash
   xcodegen generate
   ```
3. 打开 `DouyinLite.xcodeproj`：
   ```bash
   open DouyinLite.xcodeproj
   ```
4. 分别选择 Scheme 构建：
   - `DouyinLite`：iOS Simulator / 真机
   - `DouyinLiteWatch`：watchOS Simulator
5. 运行：iPhone 上下滑动切换；Watch 上用「上一条 / 下一条」切换。

### 命令行构建（macOS）

```bash
# iOS 模拟器
xcodebuild -project DouyinLite.xcodeproj -scheme DouyinLite \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

# watchOS 模拟器
xcodebuild -project DouyinLite.xcodeproj -scheme DouyinLiteWatch \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath DerivedData ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

## 四、签名与安装到真机

1. 在 Xcode 里把两个 Target 的 Team 改为你的开发者账号；自动管理签名。
2. Watch Target 的 `WKCompanionAppBundleIdentifier` 已指向 iOS Bundle ID `com.jionzyk.douyinlite`。
3. 真机需先在 iPhone 上配对 Apple Watch，再安装 iOS App；Watch App 会随 iOS App 嵌入安装。
4. 导出签名 IPA：Xcode → Product → Archive，或命令行 `xcodebuild archive` 后导出。

> 未签名的归档包不能直接侧载安装；要装机必须用受信开发者证书签名或走 TestFlight。

## 五、接入授权后端（当前为预留）

1. 按 `API_CONTRACT.md` 部署自有后端，只返回已授权可分发的数据。
2. 在 `Shared/Configuration.swift` 把 `backendBaseURL` 填为后端 HTTPS 地址。
3. 在 `AuthProvider` 中实现真实 OAuth 授权码交换与刷新；令牌由 `TokenStore` 存入 Keychain。
4. `video_url` 仅在权利人明确授权在本 App 内播放时填写；`share_url` 只用于打开网页，绝不交给 AVPlayer。

## 六、功能状态清单

| 模块 | 需求 | 状态 | 说明 |
|---|---|---|---|
| iPhone | 上下滑动切换视频 | 已完成 | paging 竖屏分页 |
| iPhone | 自动播放 / 暂停 | 已完成 | 切页自动播放，离开当前页暂停 |
| iPhone | 视频预加载 | 已完成 | `FeedPreloader` 缓冲前后半径条目 |
| iPhone | 封面 / 作者 / 昵称 / 描述 | 已完成 | 远程封面/头像可选，缺失时占位 |
| iPhone | 播放失败重试 | 已完成 | 单条重试 + 整页重载 |
| iPhone | 连续加载列表 | 已完成 | 游标分页，滚到底加载下一页 |
| iPhone | 网络错误 / 空数据处理 | 已完成 | 错误态、空态、可重试判断 |
| iPhone | AVPlayer 真实地址 | 部分完成 | 公开示例流可播放；授权媒体地址待后端配置 |
| API | 统一 APIClient | 已完成 | `APIClient` |
| API | FeedService | 已完成 | `FeedService` / `AuthorizedBackendFeedService` / `DemoFeedService` |
| API | VideoDetailService | 已完成（预留） | `VideoDetailServicing`，未接私有详情接口 |
| API | Decodable 模型 | 已完成 | 见 `Shared/Models` |
| API | OAuth 授权预留 | 已完成（预留） | `AuthProviding` 协议 + 未接通实现 |
| API | Token 安全存储与刷新 | 已完成（预留） | Keychain 存储 + 401 刷新一次 |
| API | API 错误处理 | 已完成 | `APIError` 分类与可重试判断 |
| API | 官方开放平台接入预留 | 已完成（预留） | 待审批后在后端层对接 |
| Watch | 独立联网获取列表 | 已完成 | Watch 自建 `FeedService` 实例 |
| Watch | 独立播放视频 | 已完成 | 独立 AVPlayer 实例 |
| Watch | 上一条 / 下一条 | 已完成 | |
| Watch | 标题与作者 | 已完成 | |
| Watch | 失败提示与重试 | 已完成 | |
| Watch | 不依赖 iPhone 实时传输 | 已完成 | `WKRunsIndependentlyOfCompanionApp = YES` |
| 工程 | 双 Target | 已完成 | iOS + watchOS |
| 工程 | Watch App Embed | 已完成 | `project.yml` 依赖 embed |
| 工程 | GitHub Actions 构建 | 已完成 | 见 `.github/workflows/ios-watchos-ci.yml` |
| 交付 | 真实构建产物 / 签名 IPA | **待测试** | 本 Linux 环境无 Xcode，未构建；需 macOS 或 CI runner 产出 |

## 七、待授权 / 待测试项

- 官方开放平台能力审批与授权码流程（当前 `authorize()` 抛「未配置」）。
- 授权后端的真实 `video_url` 可用性、时效与跨端播放验证。
- 真机续航、后台缓冲、滚动性能调优。
- CI 归档导出的 IPA 在目标系统版本上的装机验证。

## 八、公开样片署名

Big Buck Bunny — Blender Foundation, CC BY 3.0.
- 项目：https://peach.blender.org/
- 许可：https://creativecommons.org/licenses/by/3.0/
- 样片流：https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4

该样片为第三方公开演示流，不保证长期可用或 SLA；生产环境请替换为你自有或已授权分发的媒体地址。
