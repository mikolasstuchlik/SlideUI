import SwiftUI
import SlideUICommons
import AppKit

public enum Focus: Hashable {
    public struct Properties: Hashable {
        public init(offset: CGVector, scale: CGFloat, hint: String? = nil) {
            self.offset = offset
            self.scale = scale
            self.hint = hint
        }

        public let uuid: UUID = UUID()
        public var offset: CGVector
        public var scale: CGFloat
        public var hint: String?
    }

    case slides([any Slide.Type])
    case properties(Properties)

    public static func == (lhs: Focus, rhs: Focus) -> Bool {
        switch (lhs, rhs) {
        case let (.slides(lCont), .slides(rCont)):
            return lCont.map { $0.name } == rCont.map { $0.name }
        case let (.properties(lCont), .properties(rCont)) where lCont == rCont:
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .properties(properties):
            hasher.combine(0)
            hasher.combine(properties)
        case let .slides(slides):
            hasher.combine(slides.map { $0.name })
        }
    }
}

public struct Camera: Equatable {
    var offset: CGVector
    var scale: CGFloat
}

private enum MouseMoveMachine<Context>: Equatable {
    case idle
    case callFlagDown
    case leftButtonDown(lastPosition: CGVector, context: Context)

    static func leftButtonDown(lastPosition: CGVector) -> Self where Context == Void {
        return Self.leftButtonDown(lastPosition: lastPosition, context: ())
    }

    static func == (lhs: MouseMoveMachine<Context>, rhs: MouseMoveMachine<Context>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.callFlagDown, .callFlagDown):
            return true
        case let (.leftButtonDown(llastPos, _), .leftButtonDown(rlastPos, _)) where llastPos == rlastPos:
            return true
        default:
            return false
        }
    }
}

private struct PresentationHUD: View {
    @EnvironmentObject var presentation: PresentationProperties
    @State var editing: Bool = !NSApplication.shared.areWindowsFirstResponder

    public var body: some View {
        HStack(spacing: 8) {
            if editing {
                Text("Editing")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }.onReceive(NotificationCenter.default.publisher(for: NSWindow.willChangeFirstResponder)) { notification in
            editing = !NSApplication.shared.areWindowsFirstResponder
        }
    }
}

public struct Presentation: View {
    public init() { }

    @EnvironmentObject var presentation: PresentationProperties

    @State private var mouseMoveMachine: MouseMoveMachine<Void> = .idle
    @State private var moveSlideMachine: MouseMoveMachine<any Slide.Type> = .idle

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                plane
                    .onChange(of: geometry.size) { newSize in
                        if presentation.automaticFameSize {
                            presentation.frameSize = newSize
                        }
                        if presentation.automaticScreenSize {
                            presentation.screenSize = newSize
                        }
                    }
                    .preferredColorScheme(presentation.colorScheme)
                PresentationHUD()
            }
        }.onAppear {
            NSWindow.swizzleBecomeFirstResponder()
            NSEvent.addLocalMonitorForEvents(
                matching: [.keyDown, .keyUp, .leftMouseDragged, .leftMouseDown, .leftMouseUp, .flagsChanged],
                handler: handleMac(event:)
            )
        }
    }

    private var plane: some View {
        Plane()
            .offset(
                x: -(presentation.screenSize.width * presentation.camera.offset.dx),
                y: -(presentation.screenSize.height * presentation.camera.offset.dy)
            )
            .scaleEffect(presentation.camera.scale)
            .clipped()
            .animation(
                presentation.mode == .presentation ? .easeInOut(duration: 1.0) : nil,
                value: presentation.camera
            )
    }

    private func handleMac(event: NSEvent) -> NSEvent? {
        guard !(presentation.mode == .editor && !presentation.allowHotkeys) else {
            return event
        }

        resolveMouseDrag(event: event)
        resolveSlideDrag(event: event)
        if resolveZoomHotkeys(event: event) {
            return nil
        }
        if resolveNavigation(event: event) {
            return nil
        }
        if resolveResponder(event: event) {
            return nil
        }

        return event
    }

    private func resolveMouseDrag(event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            mouseMoveMachine = event.modifierFlags.contains(.command) ? .callFlagDown : .idle
        case .leftMouseDown where mouseMoveMachine == .callFlagDown:
            guard let windowSize = event.window?.frame.size else {
                break
            }
            mouseMoveMachine = .leftButtonDown(lastPosition: offset(for: event.locationInWindow, in: windowSize))
        case .leftMouseDragged where mouseMoveMachine != .idle:
            guard case let .leftButtonDown(lastPosition, _) = mouseMoveMachine, let windowSize = event.window?.frame.size else {
                break
            }
            let newPosition = offset(for: event.locationInWindow, in: windowSize)
            presentation.camera.offset = presentation.camera.offset - (newPosition - lastPosition)
            mouseMoveMachine = .leftButtonDown(lastPosition: newPosition)
        case .leftMouseUp where mouseMoveMachine != .idle:
            mouseMoveMachine = .callFlagDown
        default:
            break
        }
    }

    private func resolveSlideDrag(event: NSEvent) {
        guard presentation.mode == .editor else {
            return
        }

        switch event.type {
        case .flagsChanged:
            moveSlideMachine = event.modifierFlags.contains(.shift) ? .callFlagDown : .idle
        case .leftMouseDown where moveSlideMachine == .callFlagDown:
            guard let windowSize = event.window?.frame.size else {
                break
            }
            let offsetLocation = offset(for: event.locationInWindow, in: windowSize) + presentation.camera.offset
            let slide = presentation.slides.reversed().first { slide in
                getOffsetRect(of: slide).contains(CGPoint(x: offsetLocation.dx, y: offsetLocation.dy))
            }
            guard let slide else {
                moveSlideMachine = .callFlagDown
                break
            }
            moveSlideMachine = .leftButtonDown(lastPosition: offsetLocation, context: slide)
        case .leftMouseDragged where moveSlideMachine != .idle:
            guard case let .leftButtonDown(lastPosition, slide) = moveSlideMachine, let windowSize = event.window?.frame.size else {
                break
            }
            let newPosition = offset(for: event.locationInWindow, in: windowSize) + presentation.camera.offset

            slide.offset = slide.offset + (newPosition - lastPosition)
            // If some camera property isnt changed, the slide is not re-arranged on the plane
            presentation.camera.offset = presentation.camera.offset

            moveSlideMachine = .leftButtonDown(lastPosition: newPosition, context: slide)
        case .leftMouseUp where moveSlideMachine != .idle:
            moveSlideMachine = .callFlagDown
        default:
            break
        }
    }

    private func resolveZoomHotkeys(event: NSEvent) -> Bool {
        guard
            NSApplication.shared.areWindowsFirstResponder,
            event.type == .keyDown
        else {
            return false
        }
        switch event.keyCode {
        case 45 /* 'n' */:
            presentation.camera.scale = presentation.camera.scale - (presentation.camera.scale / 3)
        case 46 /* 'n' */:
            presentation.camera.scale = presentation.camera.scale + (presentation.camera.scale / 3)
        default:
            return false
        }

        return true
    }

    private func offset(for position: NSPoint, in window: CGSize) -> CGVector {
        CGVector(
            dx: (position.x - window.width / 2) / window.width / presentation.camera.scale,
            dy: (position.y - window.height / 2) / window.height / presentation.camera.scale
        ).invertedDY()
    }

    private func absoluteToOffset(size: CGSize) -> CGSize {
        CGSize(
            width: size.width / presentation.screenSize.width,
            height: size.height / presentation.screenSize.height
        )
    }

    private func getOffsetRect(of slide: any Slide.Type) -> CGRect {
        let offset = slide.offset
        let offsetSize = absoluteToOffset(size: presentation.frameSize)
        return CGRect(
            origin: CGPoint(
                x: offset.dx - offsetSize.width / 2,
                y: offset.dy - offsetSize.height / 2
            ),
            size: offsetSize
        )
    }

    private func resolveNavigation(event: NSEvent) -> Bool {
        guard
            NSApplication.shared.areWindowsFirstResponder,
            event.type == .keyDown
        else {
            return false
        }

        switch event.keyCode {
        case 49 /* Space bar*/, 36 /* enter */:
            presentation.selectedFocus += 1
        case 51 /* Back space */:
            presentation.selectedFocus -= 1
        default:
            return false
        }

        return true
    }

    private func resolveResponder(event: NSEvent) -> Bool {
        guard
            event.type == .keyDown,
            event.keyCode == 53 /* escape */,
            !NSApplication.shared.areWindowsFirstResponder
        else {
            return false
        }

        NSApplication.shared.makeWindowsFirstResponder()

        return true
    }
}
