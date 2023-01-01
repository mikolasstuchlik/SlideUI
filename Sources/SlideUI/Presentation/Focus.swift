import Foundation

public struct Focus: Hashable {
    public init(kind: Focus.Kind, hint: String? = nil) {
        self.uuid = UUID()
        self.kind = kind
        self.hint = hint
    }

    public enum Kind: Hashable {
        case unbound(Camera)
        case specific([any Slide.Type])

        public static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case let (.specific(lCont), .specific(rCont)):
                return lCont.map { $0.name } == rCont.map { $0.name }
            case let (.unbound(lCamera), .unbound(rCamera)):
                return lCamera == rCamera
            default:
                return false
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case let .specific(slides):
                hasher.combine(0)
                hasher.combine(slides.map { $0.name })
            case let .unbound(camera):
                hasher.combine(camera)
            }
        }
    }

    public let uuid: UUID
    public var kind: Kind
    public var hint: String?
}

public struct Camera: Hashable {
    public init(offset: CGVector, scale: CGFloat) {
        self.offset = offset
        self.scale = scale
    }

    public var offset: CGVector
    public var scale: CGFloat
}

public struct PresentableFocus {
    var camera: Camera
    var hint: String?
}
