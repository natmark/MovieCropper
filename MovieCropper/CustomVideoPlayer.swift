import AVKit
import SwiftUI

struct CustomVideoPlayer: NSViewRepresentable {
    typealias NSViewType = AVPlayerView

    var player: AVPlayer
    func makeNSView(context: Context) -> NSViewType {
        let avPlayerView = AVPlayerView()
        avPlayerView.controlsStyle = .none
        avPlayerView.player = player
        return avPlayerView
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.player = player
    }
}
