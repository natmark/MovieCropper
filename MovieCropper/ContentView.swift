import SwiftUI

struct ContentView: View {
    enum Scene {
        case input
        case crop(inputURL: URL)
        case exported(outputURL: URL)
    }

    @State private var scene: Scene = .input

    var body: some View {
        switch scene {
        case .input:
            DragAndDropView(didSelectFile: { url in
                scene = .crop(inputURL: url)
            })
        case let .crop(inputURL):
            VideoCropView(
                url: inputURL,
                didTapClose: {
                    scene = .input
                },
                didExport: { url in
                    scene = .exported(outputURL: url)
                }
            )
        case let .exported(outputURL):
            ExportCompletedView(url: outputURL, didTapClose: {
                scene = .input
            })
        }
    }
}

#Preview {
    ContentView()
}
