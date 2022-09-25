import AppKit
import SwiftUI

public struct EffectView: NSViewRepresentable {
    @State var material: NSVisualEffectView.Material = .headerView
    @State var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
