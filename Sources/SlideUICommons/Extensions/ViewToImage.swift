import AppKit
import SwiftUI

public extension View {
    func renderAsImage() -> NSImage? {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return view.bitmapImage()
    }

    func renderAsImage(delay: TimeInterval, result: @escaping (NSImage?) -> Void) {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)

        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            result(view.bitmapImage())
        }
    }

}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {

    override var safeAreaInsets: NSEdgeInsets {
        return .init()
    }

}

public extension NSView {

    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }

}
