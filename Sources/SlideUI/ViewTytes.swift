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

/// SlideUI Slide describing a frame of the presentation
public protocol Slide: View {
    /// Offset of the slide in multiples of frame size from point [0, 0]
    static var offset: CGVector { get set }
    /// Preferred scale ("zoom") of the Camera when this slide is in single focus.
    static var singleFocusScale: CGFloat { get }
    /// Hint related to this slide.
    static var hint: String? { get set }
    /// Globally unique name of this slide (provided default implementation).
    static var name: String { get }

    init()
}

public extension Slide {
    static var name: String { String(describing: Self.self) }
    static var singleFocusScale: CGFloat { 0.9999 } // When scale is 1.0, some shapes disappear :shurug:

    var name: String { Self.name }
}
