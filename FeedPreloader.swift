import AVFoundation
import Foundation

/// 相邻作品的播放项预加载：提前为前后若干条创建 `AVPlayerItem`，切换时减少起播等待。
/// 仅预加载有授权媒体地址的条目；不下载、不持久化到本地存储。
final class FeedPreloader {
    private let cache = NSCache<NSString, AVPlayerItem>()
    private let radius: Int
    private let maxEntries: Int

    init(radius: Int = 1, maxEntries: Int = 8) {
        self.radius = radius
        self.maxEntries = maxEntries
        cache.countLimit = maxEntries
    }

    /// 根据当前索引，预取前后半径内的作品。
    func prefetch(_ items: [VideoItem], around index: Int) {
        let lower = max(0, index - radius)
        let upper = min(items.count - 1, index + radius)
        guard lower <= upper else { return }

        for i in lower...upper {
            guard let url = items[i].streamURL else { continue }
            let key = url.absoluteString as NSString
            if cache.object(forKey: key) == nil {
                cache.setObject(AVPlayerItem(url: url), forKey: key)
            }
        }
    }

    func cachedItem(for url: URL?) -> AVPlayerItem? {
        guard let url else { return nil }
        return cache.object(forKey: url.absoluteString as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
