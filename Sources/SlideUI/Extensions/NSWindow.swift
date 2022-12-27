import AppKit

extension NSWindow {

    static let willChangeFirstResponder: NSNotification.Name = .init(rawValue: "org.slideui.willChangeFirstResponder")
    static let willChangeFirstResponderContext: String = "org.slideui.willChangeFirstReponder.context"

    @objc dynamic func _swizzled_makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let result = _swizzled_makeFirstResponder(responder)

        if result {
            NotificationCenter.default.post(
                name: NSWindow.willChangeFirstResponder,
                object: self,
                userInfo: [NSWindow.willChangeFirstResponderContext: responder ?? self]
            )
        }

        return result
    }

    private static var swizzled = false

    static func swizzleBecomeFirstResponder() {
        guard !swizzled else { return }
        swizzled = true
        let selector1 = #selector(NSWindow.makeFirstResponder(_:))
        let selector2 = #selector(NSWindow._swizzled_makeFirstResponder(_:))
        let originalMethod = class_getInstanceMethod(NSWindow.self, selector1)!
        let swizzleMethod = class_getInstanceMethod(NSWindow.self, selector2)!
        method_exchangeImplementations(originalMethod, swizzleMethod)
    }
}
