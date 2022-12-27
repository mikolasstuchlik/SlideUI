import AppKit

extension NSApplication {
    var areWindowsFirstResponder: Bool {
        windows.allSatisfy { $0.firstResponder === $0 }
    }

    func makeWindowsFirstResponder() {
        windows.forEach { $0.makeFirstResponder(nil) }
    }
}
