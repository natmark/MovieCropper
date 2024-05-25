import AVKit

struct VideoExporter {
    static func export(avAsset: AVAsset, videoComposition: AVVideoComposition, url: URL, outputFileType: AVFileType) async {
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try? FileManager.default.removeItem(at: url)
        }

        let exporter = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = url
        exporter?.outputFileType = outputFileType
        await exporter?.export()
    }
}
