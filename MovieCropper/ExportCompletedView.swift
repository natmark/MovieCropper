import SwiftUI
import AVKit

struct ExportCompletedView: View {
    var url: URL
    var didTapClose: () -> Void


    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 60))
                Text("クロップした動画を保存しました")
                    .font(.title)
                    .fontWeight(.bold)
            }

            HStack {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }, label: {
                    Text("ファイルを開く")
                })

                Button(action: {
                    didTapClose()
                }, label: {
                    Text("最初に戻る")
                })
            }
        }
        .padding(.vertical, 20)
    }
}


#Preview {
    ExportCompletedView(url: URL(string: "https://example.com")!, didTapClose: {})
}
