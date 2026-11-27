import SwiftUI
import AVKit

struct FeedView: View {
    @StateObject private var playback = VideoPlaybackManager()
    private let service: FeedService
    private let preloader = FeedPreloader()

    @State private var videos: [VideoItem] = []
    @State private var selectedID: String?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isLoadingMore = false
    @State private var nextCursor: String?
    @State private var hasMore = false
    @State private var isDemoData = false

    init() {
        let client = APIClient(baseURL: AppConfiguration.backendBaseURL, auth: AppAuthProvider())
        self.service = FeedService(client: client)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView("正在准备视频…")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let loadError {
                errorView(loadError, retryable: true)
            } else if videos.isEmpty {
                errorView("暂时没有可播放的视频", retryable: false)
            } else {
                feed
            }
        }
        .task { await loadFirst() }
        .onChange(of: selectedID) { _, newID in
            guard let newID, let index = videos.firstIndex(where: { $0.id == newID }) else { return }
            let preloaded = preloader.cachedItem(for: videos[index].streamURL)
            playback.play(videos[index], preloadedItem: preloaded)
            preloader.prefetch(videos, around: index)
        }
    }

    private var feed: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                    VideoPage(video: video, playback: playback)
                        .containerRelativeFrame(.vertical)
                        .id(video.id)
                        .onAppear { if index == videos.count - 1 { Task { await loadMore() } } }
                }

                if isLoadingMore {
                    ProgressView()
                        .tint(.white)
                        .frame(height: 60)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selectedID)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DouyinLite")
                    .font(.caption.weight(.semibold))
                Text(isDemoData ? "公开演示样片 · 非抖音内容" : "授权后端数据")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
        }
    }

    private func errorView(_ message: String, retryable: Bool) -> some View {
        VStack(spacing: 14) {
            Text(message).foregroundStyle(.white).multilineTextAlignment(.center)
            if retryable {
                Button("重新加载") { Task { await loadFirst() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    @MainActor
    private func loadFirst() async {
        isLoading = true
        loadError = nil
        do {
            let result = try await service.loadFeed(cursor: nil, limit: AppConfiguration.pageSize)
            videos = result.items
            nextCursor = result.nextCursor
            hasMore = result.hasMore
            isDemoData = service.isUsingDemoData
            selectedID = videos.first?.id
            if let first = videos.first { playback.play(first) }
            preloader.prefetch(videos, around: 0)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let result = try await service.loadFeed(cursor: nextCursor, limit: AppConfiguration.pageSize)
            videos.append(contentsOf: result.items)
            nextCursor = result.nextCursor
            hasMore = result.hasMore
            isDemoData = service.isUsingDemoData
        } catch {
            // 追加失败不打断当前列表，保留已有内容。
            loadError = nil
        }
        isLoadingMore = false
    }
}

private struct VideoPage: View {
    let video: VideoItem
    @ObservedObject var playback: VideoPlaybackManager

    private var isCurrent: Bool { playback.currentVideoID == video.id }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black

            if isCurrent {
                VideoPlayer(player: playback.player)
                    .ignoresSafeArea()
            } else {
                placeholder
            }

            LinearGradient(colors: [.clear, .black.opacity(0.78)],
                           startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let avatar = video.avatarURL {
                        AsyncImage(url: avatar) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(.white.opacity(0.15))
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    }
                    Text(video.creator)
                        .font(.subheadline.weight(.semibold))
                }

                Text(video.title)
                    .font(.title2.bold())
                    .lineLimit(3)

                if let signature = video.signature, !signature.isEmpty {
                    Text(signature)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                if let attribution = video.attribution {
                    Text(attribution)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if let error = playback.playbackError, isCurrent {
                    Text(error.errorDescription ?? "播放失败")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.9))
                }

                HStack(spacing: 12) {
                    Button(playback.isPlaying ? "暂停" : "播放") { playback.togglePlayback() }
                    Button("重试") { playback.retry(video) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 54)
            .foregroundStyle(.white)
        }
        .clipped()
    }

    @ViewBuilder
    private var placeholder: some View {
        if let cover = video.coverURL {
            AsyncImage(url: cover) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else { ProgressView().tint(.white) }
            }
            .ignoresSafeArea()
        } else {
            Color.white.opacity(0.06)
        }
    }
}
