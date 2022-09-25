import SwiftUI

public protocol Background: View {
    static var offset: CGVector { get }
    static var relativeSize: CGSize { get }
    static var scale: CGFloat { get }

    init()
}

public protocol Slide: View {
    static var offset: CGVector { get set }
    static var singleFocusScale: CGFloat { get }
    static var hint: String? { get set }
    static var name: String { get }

    init()
}

public extension Slide {
    static var name: String { String(describing: Self.self) }
    static var singleFocusScale: CGFloat { 0.9999 } // When scale is 1.0, some shapes disappear :shurug:

    var name: String { Self.name }
}
