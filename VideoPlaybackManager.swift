import AVFoundation
import AVKit
import Combine
import Foundation

/// 单进程单播放器管理：负责切换作品、自动播放/暂停、错误暴露与重试。
/// iOS 与 watchOS 各自持有一份实例，互不共享播放器。
@MainActor
final class VideoPlaybackManager: ObservableObject {
    @Published private(set) var currentVideoID: String?
    @Published private(set) var isPlaying = false
    /// 当前作品的播放错误；无错误为 nil。
    @Published private(set) var playbackError: APIError?

    let player = AVPlayer()
    private var currentURL: URL?
    private var itemObservers: [Any] = []

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        player.actionAtItemEnd = .pause
    }

    /// 播放指定作品。无授权媒体地址时标记 `.mediaNotAuthorized`，不创建播放项。
    /// - Parameter preloadedItem: 预加载器已缓冲的播放项，命中时直接复用以缩短起播等待。
    func play(_ video: VideoItem, preloadedItem: AVPlayerItem? = nil) {
        guard currentVideoID != video.id || currentURL != video.streamURL else {
            player.play()
            isPlaying = true
            return
        }

        player.pause()
        detachItem()
        currentVideoID = video.id
        playbackError = nil

        guard let url = video.streamURL else {
            currentURL = nil
            playbackError = .mediaNotAuthorized
            isPlaying = false
            return
        }

        currentURL = url
        let item: AVPlayerItem
        if let preloadedItem {
            item = preloadedItem
        } else {
            item = AVPlayerItem(url: url)
        }
        attachItem(item)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    /// 清空当前项并重新加载当前作品。
    func retry(_ video: VideoItem) {
        player.pause()
        detachItem()
        currentVideoID = nil
        currentURL = nil
        playbackError = nil
        play(video)
    }

    func stop() {
        player.pause()
        detachItem()
        currentVideoID = nil
        currentURL = nil
        isPlaying = false
    }

    // MARK: - 私有的件监听

    private func attachItem(_ item: AVPlayerItem) {
        itemObservers.append(
            item.observe(\.status, options: [.new]) { [weak self] observed, _ in
                Task { @MainActor in
                    guard let self else { return }
                    if observed.status == .failed {
                        self.playbackError = .network(observed.error?.localizedDescription ?? "播放失败")
                        self.isPlaying = false
                    }
                }
            }
        )
        itemObservers.append(
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.playbackError = .network("播放中断，可重试")
                    self?.isPlaying = false
                }
            }
        )
    }

    private func detachItem() {
        itemObservers.forEach { observer in
            if observer is NSKeyValueObservation {
                (observer as? NSKeyValueObservation)?.invalidate()
            } else {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        itemObservers.removeAll()
        player.replaceCurrentItem(with: nil)
    }
}
