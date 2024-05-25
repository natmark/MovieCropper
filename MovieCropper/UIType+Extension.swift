import AVFoundation
import UniformTypeIdentifiers

extension UTType {
    static var supportedType: [UTType] = [.mpeg4Movie, .quickTimeMovie]

    var avFileType: AVFileType? {
        switch self {
        case .mpeg4Movie:
            return .mp4
        case .quickTimeMovie:
            return .mov
        default:
            return nil
        }
    }
}
