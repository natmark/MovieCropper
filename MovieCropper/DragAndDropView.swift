import SwiftUI
import UniformTypeIdentifiers

struct DragAndDropView: View {
    @State private var isTargeted: Bool = false
    @State private var showUnsupportedFormatAlert: Bool = false

    var didSelectFile: (_ url: URL) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "video")
            Text("動画ファイルをドラッグ & ドロップ")
        }
        .font(.title3)
        .padding(.vertical, 100)
        .padding(.horizontal, 100)
        .border(isTargeted ? Color(.selectedControlColor) : Color(.disabledControlTextColor), width: 5)
        .padding(20)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: { providers in
            guard let provider = providers.first else { return false }
            let _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url else { return }
                if let utType = UTType(filenameExtension: url.pathExtension), utType.avFileType != nil {
                    didSelectFile(url)
                } else {
                    showUnsupportedFormatAlert = true
                }
            }
            return true
        })
        .alert("エラー", isPresented: $showUnsupportedFormatAlert) {
            Button("OK") {}
        } message: {
            Text("サポート対象外のファイルです")
        }
    }
}

#Preview {
    DragAndDropView(didSelectFile: { _ in })
}
