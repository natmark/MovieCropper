import CoreGraphics

extension CGSize {
    func scale(from size: CGSize) -> CGAffineTransform {
        let scaleX = width / size.width
        let scaleY = height / size.height

        return CGAffineTransform(scaleX: scaleX, y: scaleY)
    }
}
