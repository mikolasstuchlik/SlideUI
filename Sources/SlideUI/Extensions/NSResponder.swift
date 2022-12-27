import AppKit

extension NSResponder {

    static let willChangeFirstResponder: NSNotification.Name = .init(rawValue: "org.slideui.willChangeFirstResponder")
    static let willChangeFirstResponderContext: String = "org.slideui.willChangeFirstReponder.context"

    @objc dynamic func _swizzled_becomeFirstResponder() -> Bool {
        let wantsToBecomeFirstResponder = _swizzled_becomeFirstResponder()

        if wantsToBecomeFirstResponder {
            NotificationCenter.default.post(
                name: NSResponder.willChangeFirstResponder,
                object: self,
                userInfo: [NSResponder.willChangeFirstResponderContext: self]
            )
        }

        return wantsToBecomeFirstResponder
    }

    private static var swizzled = false

    static func swizzleBecomeFirstResponder() {
        guard !swizzled else { return }
        swizzled = true
        let selector1 = #selector(NSResponder.becomeFirstResponder)
        let selector2 = #selector(NSResponder._swizzled_becomeFirstResponder)
        let originalMethod = class_getInstanceMethod(NSResponder.self, selector1)!
        let swizzleMethod = class_getInstanceMethod(NSResponder.self, selector2)!
        method_exchangeImplementations(originalMethod, swizzleMethod)
    }
}
