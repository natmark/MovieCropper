import SwiftUI

struct PressActions: ViewModifier {
    var onPress: (DragGesture.Value) -> Void
    var onRelease: (DragGesture.Value) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        onPress(value)
                    })
                    .onEnded({ value in
                        onRelease(value)
                    })
            )
    }
}
