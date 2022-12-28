import Foundation

public enum Focus: Hashable {
    public struct Properties: Hashable {
        public init(offset: CGVector, scale: CGFloat, hint: String? = nil) {
            self.offset = offset
            self.scale = scale
            self.hint = hint
        }

        public let uuid: UUID = UUID()
        public var offset: CGVector
        public var scale: CGFloat
        public var hint: String?
    }

    case slides([any Slide.Type])
    case properties(Properties)

    public static func == (lhs: Focus, rhs: Focus) -> Bool {
        switch (lhs, rhs) {
        case let (.slides(lCont), .slides(rCont)):
            return lCont.map { $0.name } == rCont.map { $0.name }
        case let (.properties(lCont), .properties(rCont)) where lCont == rCont:
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .properties(properties):
            hasher.combine(0)
            hasher.combine(properties)
        case let .slides(slides):
            hasher.combine(slides.map { $0.name })
        }
    }
}

public struct Camera: Equatable {
    var offset: CGVector
    var scale: CGFloat
}
