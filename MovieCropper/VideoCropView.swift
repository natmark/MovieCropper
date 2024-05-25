import AVKit
import SwiftUI

struct VideoCropView: View {
    private struct DragArea {
        private var controlPoint1: CGPoint
        private var controlPoint2: CGPoint

        var rect: CGRect {
            let rect1 = CGRect(origin: controlPoint1, size: .zero)
            let rect2 = CGRect(origin: controlPoint2, size: .zero)
            return rect1.union(rect2).standardized
        }

        init(controlPoint1: CGPoint, controlPoint2: CGPoint) {
            self.controlPoint1 = controlPoint1
            self.controlPoint2 = controlPoint2
        }
    }

    var url: URL
    var didTapClose: () -> Void
    var didExport: (_ url: URL) -> Void

    private var avAsset: AVAsset
    private var avPlayerItem: AVPlayerItem
    private var avQueuePlayer: AVQueuePlayer
    private var playerLooper: AVPlayerLooper
    private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State private var isLoading: Bool = false
    @State private var totalTime: Double = 0.0
    @State private var videoSize: CGSize = .zero
    @State private var videoFrameSize: CGSize = .zero
    @State private var currentTime: Double = 0.0
    @State private var dragAreaRect: CGRect? = nil
    @State private var cropFrame: CGRect?

    @State private var showNoCropAreaAlert: Bool = false
    @State private var showCropErrorAlert: Bool = false

    init(url: URL, didTapClose: @escaping () -> Void, didExport: @escaping (_ url: URL) -> Void) {
        self.url = url
        self.didTapClose = didTapClose
        self.didExport = didExport

        avAsset = .init(url: url)
        avPlayerItem = .init(asset: avAsset)
        avQueuePlayer = .init(playerItem: avPlayerItem)
        playerLooper = .init(player: avQueuePlayer, templateItem: avPlayerItem)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("切り取りたい領域をマウスでドラッグして選択 \(Image(systemName: "rectangle.inset.filled.and.cursorarrow"))")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
            CustomVideoPlayer(player: avQueuePlayer)
                .onAppear { avQueuePlayer.play() }
                .onDisappear{ avQueuePlayer.pause() }
                .overlay {
                    GeometryReader { proxy in
                        Color.white.opacity(0.01) // Color.clearだとタッチイベント拾わなくなるので
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .modifier(PressActions(
                                onPress: { value in
                                    let dragAreaRect = calcDragArea(controlPoint1: value.startLocation, controlPoint2: value.location)
                                    self.dragAreaRect = dragAreaRect

                                    cropFrame = calcCropArea(
                                        dragAreaRect: dragAreaRect,
                                        videoSize: videoSize,
                                        videoFrameSize: videoFrameSize
                                    )
                                },
                                onRelease: { value in
                                    let dragAreaRect = calcDragArea(controlPoint1: value.startLocation, controlPoint2: value.location)
                                    self.dragAreaRect = dragAreaRect

                                    cropFrame = calcCropArea(
                                        dragAreaRect: dragAreaRect,
                                        videoSize: videoSize,
                                        videoFrameSize: videoFrameSize
                                    )
                                }
                            ))
                            .onAppear {
                                videoFrameSize = proxy.size
                            }
                            .onChange(of: proxy.size) { oldSize, newSize in
                                videoFrameSize = newSize

                                if let dragAreaRect = dragAreaRect {
                                    let oldVideoRect = resizedVideoRect(videoSize: videoSize, videoFrameSize: oldSize)
                                    let newVideoRect = resizedVideoRect(videoSize: videoSize, videoFrameSize: newSize)
                                    let transform = newVideoRect.transform(from: oldVideoRect)

                                    print(transform)
                                    let newRect = dragAreaRect.applying(transform)
                                    self.dragAreaRect = newRect

                                    cropFrame = calcCropArea(
                                        dragAreaRect: newRect,
                                        videoSize: videoSize,
                                        videoFrameSize: videoFrameSize
                                    )
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let cropFrame {
                        Rectangle()
                            .strokeBorder(.red, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                            .offset(x: cropFrame.origin.x, y: cropFrame.origin.y)
                            .frame(width: cropFrame.width, height: cropFrame.height)
                    }
                }

            BottomContainer(
                progress: currentTime / totalTime, didTapClose: didTapClose,
                didTapCrop: {
                    if let cropFrame, cropFrame.size != .zero {
                        let savePanel = NSSavePanel()
                        savePanel.message = "保存場所を選択"
                        savePanel.showsTagField = false
                        savePanel.allowedContentTypes = UTType.supportedType
                        savePanel.canCreateDirectories = true
                        savePanel.showsHiddenFiles = true
                        savePanel.isExtensionHidden = true
                        savePanel.allowsOtherFileTypes = true

                        savePanel.nameFieldStringValue = url.lastPathComponent
                        savePanel.directoryURL = url

                        guard let avFileType = UTType(filenameExtension: url.pathExtension)?.avFileType else {
                            // 非対応フォーマット
                            return
                        }
                        Task {
                            let response = await savePanel.begin()
                            guard response == .OK, let outputURL = savePanel.url else {
                                return
                            }
                            do {
                                isLoading = true
                                let videoComposition = try await VideoCropper.createCroppedVideoComposition(avAsset: avAsset, cropFrame: cropFrame, videoFrameSize: videoFrameSize)
                                await VideoExporter.export(avAsset: avAsset, videoComposition: videoComposition, url: outputURL, outputFileType: avFileType)
                                isLoading = false
                                didExport(outputURL)
                            } catch {
                                isLoading = false
                            }
                        }
                    } else {
                        showNoCropAreaAlert = true
                    }
                }
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
        .task {
            guard
                let duration = try? await avAsset.load(.duration),
                let avAssetTracks = try? await avAsset.loadTracks(withMediaType: .video),
                let naturalSize = try? await avAssetTracks.first?.load(.naturalSize)
            else {
                return
            }
            totalTime = duration.seconds
            videoSize = naturalSize
        }
        .onReceive(timer) { _ in
            currentTime = avQueuePlayer.currentTime().seconds
        }
        .alert("エラー", isPresented: $showNoCropAreaAlert) {
            Button("OK") {}
        } message: {
            Text("クロップ領域を選択してください")
        }
        .alert("エラー", isPresented: $showCropErrorAlert) {
            Button("OK") {}
        } message: {
            Text("クロップに失敗しました")
        }
        .overlay(alignment: .center) {
            if isLoading {
                Color.black.opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .center) {
                        Text("変換中...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
            }
        }
    }

    private func resizedVideoRect(videoSize: CGSize, videoFrameSize: CGSize) -> CGRect {
        let videoFrameRect = CGRect(origin: .zero, size: videoFrameSize)
        let videoRect = CGRect(origin: .zero, size: videoSize)
        return videoRect.aspectFitRect(inside: videoFrameRect)
    }

    private func calcDragArea(controlPoint1: CGPoint, controlPoint2: CGPoint) -> CGRect {
        let rect1 = CGRect(origin: controlPoint1, size: .zero)
        let rect2 = CGRect(origin: controlPoint2, size: .zero)
        return rect1.union(rect2).standardized
    }

    private func calcCropArea(dragAreaRect: CGRect, videoSize: CGSize, videoFrameSize: CGSize) -> CGRect {
        let resizedVideoRect = resizedVideoRect(videoSize: videoSize, videoFrameSize: videoFrameSize)
        return dragAreaRect.intersection(resizedVideoRect)
    }

    private struct BottomContainer: View {
        var progress: Double
        var didTapClose: () -> Void
        var didTapCrop: () -> Void

        var body: some View {
            HStack(spacing: 10) {
                Button("閉じる") {
                    didTapClose()
                }

                Slider(value: .init(get: { progress }, set: { _ in }))
                    .allowsHitTesting(false)
                    .frame(width: 200)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button("動画をクロップする") {
                    didTapCrop()
                }
            }
        }
    }
}

#Preview {
    VideoCropView(url: URL(string: "")!, didTapClose: {}, didExport: { _ in })
}
