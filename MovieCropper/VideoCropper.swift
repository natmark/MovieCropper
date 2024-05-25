import AVKit

struct VideoCropper {
    enum CropVideoError: Error {
        case noAssetTrack
    }

    static func createCroppedVideoComposition(avAsset: AVAsset, cropFrame: CGRect, videoFrameSize: CGSize) async throws -> AVVideoComposition {
        let avAssetTracks = try await avAsset.loadTracks(withMediaType: .video)
        guard let firstTrack = avAssetTracks.first(where: { $0.mediaType == .video }) else {
            throw CropVideoError.noAssetTrack
        }

        let videoSize = try await firstTrack.load(.naturalSize)
        let frameDuration = try await firstTrack.load(.nominalFrameRate)
        let timeRange = try await firstTrack.load(.timeRange)

        let videoFrameRect = CGRect(origin: .zero, size: videoFrameSize)
        let videoRect = CGRect(origin: .zero, size: videoSize)
        let resizedVideoRect = videoRect.aspectFitRect(inside: videoFrameRect)

        let scale = videoSize.scale(from: resizedVideoRect.size)

        let normalizedCropArea = CGRect(x: cropFrame.minX - resizedVideoRect.minX, y: cropFrame.minY - resizedVideoRect.minY, width: cropFrame.width, height: cropFrame.height).applying(scale)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(frameDuration, 1.0)))
        videoComposition.renderSize = normalizedCropArea.size

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange

        let transform = CGAffineTransform(translationX: -normalizedCropArea.origin.x, y: -normalizedCropArea.origin.y) // 変換
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        transformer.setTransform(transform, at: .zero)

        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]

        return videoComposition
    }
}
