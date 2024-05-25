import CoreGraphics

extension CGRect {
    func transform(from rect: CGRect) -> CGAffineTransform {
        let scaleX = width / rect.width
        let scaleY = height / rect.height

        var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        let transformedOrigin = rect.origin.applying(transform)

        let translateX = origin.x - transformedOrigin.x
        let translateY = origin.y - transformedOrigin.y

        transform = transform.translatedBy(x: translateX, y: translateY)

        return transform
    }

    func aspectFitRect(inside boundingRect: CGRect) -> CGRect {
        let widthRatio = boundingRect.width / self.width
        let heightRatio = boundingRect.height / self.height
        let scale = min(widthRatio, heightRatio)

        let newWidth = self.width * scale
        let newHeight = self.height * scale
        let newX = boundingRect.origin.x + (boundingRect.width - newWidth) / 2
        let newY = boundingRect.origin.y + (boundingRect.height - newHeight) / 2

        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
