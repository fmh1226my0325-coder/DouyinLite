import SwiftUI
import AVKit

struct WatchFeedView: View {
    @StateObject private var playback = VideoPlaybackManager()
    private let service: FeedService

    @State private var videos: [VideoItem] = []
    @State private var index = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isDemoData = false

    init() {
        let client = APIClient(baseURL: AppConfiguration.backendBaseURL, auth: AppAuthProvider())
        self.service = FeedService(client: client)
    }

    private var currentVideo: VideoItem? {
        guard videos.indices.contains(index) else { return nil }
        return videos[index]
    }

    var body: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView("加载中…")
            } else if let errorMessage {
                Text(errorMessage).font(.footnote).multilineTextAlignment(.center)
                Button("重试") { Task { await load() } }
            } else if let video = currentVideo {
                header(for: video)
                VideoPlayer(player: playback.player)
                    .frame(maxHeight: .infinity)
                controls(for: video)
            } else {
                Text("没有可播放的视频")
                    .font(.footnote)
            }
        }
        .padding()
        .task { await load() }
    }

    private func header(for video: VideoItem) -> some View {
        VStack(spacing: 2) {
            Text(video.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(video.creator)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(isDemoData ? "公开演示样片" : "授权后端数据")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func controls(for video: VideoItem) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button("上一条") { move(by: -1) }
                    .disabled(index == 0)
                Button(playback.isPlaying ? "暂停" : "播放") { playback.togglePlayback() }
                Button("下一条") { move(by: 1) }
                    .disabled(index >= videos.count - 1)
            }
            .font(.caption2)

            Button("重新加载") { playback.retry(video) }
                .font(.caption2)

            if let attribution = video.attribution {
                Text(attribution)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await service.loadFeed(cursor: nil, limit: AppConfiguration.pageSize)
            videos = result.items
            index = 0
            isDemoData = service.isUsingDemoData
            if let video = currentVideo { playback.play(video) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func move(by offset: Int) {
        let next = index + offset
        guard videos.indices.contains(next) else { return }
        index = next
        if let video = currentVideo { playback.play(video) }
    }
}
