import SwiftUI

/// SwiftUI View describing a background.
public protocol Background: View {
    /// Offset of the background in multilpes of frame size from point [0, 0]
    static var offset: CGVector { get }
    /// Size of the view relative to a multiple of frame size.
    static var relativeSize: CGSize { get }
    /// Scale using which the Background is rendered. Use this to save up resources.
    /// Single hight resolution background may drain all the HW resources and affect program responsiveness.
    static var scale: CGFloat { get }

    init()
}

/// Type identyfying the slide
public typealias SlideID = String

/// Protocol which describes `ObservableObjects` that allow to consume a forward event.
public protocol ForwardEventCapturingState: ObservableObject {
    /// Each type has only 1 valid instance of the state which should be stored in this property
    static var stateSingleton: Self { get }
    /// Use this factory method to intialize singleton. It sets up chain of event from inner ObservableObject.
    static func makeSingleton() -> Self

    init()

    /// If the selected focus is of the `.specific` kind, and there is only 1 slide,
    /// the presentation invokes this function to provide the slide with ability to consume
    /// the "next slide" event.
    /// - Parameter number: The number of "next slide" events consumed by this slide.
    /// - Returns: `true` if Slide consumed the event, `false` is default
    func captured(forwardEvent number: UInt ) -> Bool

    /// Sets up chain of event from inner ObservableObject.
    func hookObjectWillChange()
}

private var willChangeCancellables: Set<AnyCancellable> = []

private extension ObservableObject {
    func hookWillChange(handler: @escaping () -> Void) {
        guard let publisher = objectWillChange as? ObservableObjectPublisher else {
            return
        }

        publisher.sink { _ in
            handler()
        }.store(in: &willChangeCancellables)
    }
}

public extension ForwardEventCapturingState where Self.ObjectWillChangePublisher: ObservableObjectPublisher {
    static func makeSingleton() -> Self {
        let aSelf = Self.init()
        aSelf.hookObjectWillChange()
        return aSelf
    }


    func hookObjectWillChange() {
        let mirror = Mirror(reflecting: self)
        mirror.children.forEach { child in
            guard let element = child.value as? any ObservableObject else {
                return
            }

            element.hookWillChange { [unowned self] in
                self.objectWillChange.send()
            }
        }
    }
}

/// Default implementation of `ForwardEventCapturingState`, that retains no state and
/// captures no events.
public final class NoCapturingState: ForwardEventCapturingState {
    public static let stateSingleton: NoCapturingState = .init()
    public init() {}
    public func captured(forwardEvent number: UInt) -> Bool { false }
}

/// SlideUI Slide describing a frame of the presentation
public protocol Slide: View {
    /// Exposed state is a type of `StateObject`, that allows to capture "forward" input to change slide and prevent
    /// presentation from proceeding to the next Slide
    associatedtype ExposedState: ForwardEventCapturingState = NoCapturingState

    /// Offset of the slide in multiples of frame size from point [0, 0]
    static var offset: CGVector { get set }
    /// Preferred scale ("zoom") of the Camera when this slide is in single focus.
    static var singleFocusScale: CGFloat { get }
    /// Hint related to this slide.
    static var hint: String? { get set }
    /// Globally unique name of this slide (provided default implementation).
    static var name: SlideID { get }

    /// If the selected focus is of the `.specific` kind, and there is only 1 slide,
    /// the presentation invokes this function to provide the slide with ability to consume
    /// the "next slide" event.
    /// - Parameter number: The number of "next slide" events consumed by this slide.
    /// - Returns: `true` if Slide consumed the event, `false` is default
    static func captured(forwardEvent number: UInt ) -> Bool

    init()
}

public extension Slide {
    static var name: SlideID { String(describing: Self.self) }
    static var singleFocusScale: CGFloat { 0.9999 } // When scale is 1.0, some shapes disappear :shurug:

    var name: SlideID { Self.name }

    static func captured(forwardEvent number: UInt ) -> Bool {
        ExposedState.stateSingleton.captured(forwardEvent: number)
    }
}
