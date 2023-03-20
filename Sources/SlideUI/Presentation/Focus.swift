import Foundation

/// Focus represents a single predefined state of the presentation. It may describe either
/// concrete camera position or focus at runtime at a list of slides. Focus is identified by the
/// `uuid` property, that changes between executions. Additionally, focus may contain
/// a hint, that is presented in the presentation control panel.
public struct Focus: Hashable {

    /// Define a configuration of the presentation
    /// - Parameters:
    ///   - kind: Kind of the configuration
    ///   - hint: Hint displayed when focused
    public init(kind: Focus.Kind, hint: String? = nil) {
        self.uuid = UUID()
        self.kind = kind
        self.hint = hint
    }

    /// Kind of the Focus. It may be either list of specific slides or a concere camera position
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

    /// Used to differentiate between instances of Focus - changes between executions.
    public let uuid: UUID

    /// Property which contains the payload of the Focus
    public var kind: Kind

    /// String displayed in the Control panel when the focus is selected
    public var hint: String?
}

/// Camera represents a specific configuration of the transformations, that mimic
/// the camera-like experience of the transitions.
public struct Camera: Hashable {

    /// - Parameters:
    ///   - offset: Offset in multiples of screen size
    ///   - scale: Scale describing "zoom"
    public init(offset: CGVector, scale: CGFloat) {
        self.offset = offset
        self.scale = scale
    }

    /// Offset from point [0, 0] in multiples of screen size
    public var offset: CGVector

    /// Scale describing "zoom"
    public var scale: CGFloat
}

/// `PresentableFocus` is the result of `Focus` resolution.
///
/// Since Focus may not contain a concrete Camera position or may produce multiple
/// (or none) hints, a Focus is not a directly presentable feature. Internally, the Presentation
/// resolves Focus at runtime into a Presentable Focus which is passed around as a
/// concrete configuration.
public struct PresentableFocus {

    /// Resolved camera positon.
    var camera: Camera

    /// Resolved hint that should be presented in the Control panel.
    var hint: String?
}
