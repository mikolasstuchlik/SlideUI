import SwiftUI
import SlideUICommons

enum MouseMoveMachine<Context>: Equatable {
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

final class PresentationGestureModel: ObservableObject {

    let presentation: PresentationProperties

    init(presentation: PresentationProperties) {
        self.presentation = presentation
    }

    @Published var moveSlideMachine: MouseMoveMachine<any Slide.Type> = .callFlagDown
    private var lastClickTime: DispatchTime = .now()
    private var movementTimer: Timer?
    private var movementVector: CGVector = .zero

    func handleMac(event: NSEvent) -> NSEvent? {
        resolveMouseMove(event: event)
        resolveClick(event: event)
        resolveMousePosition(event: event)
        resolveSlideDrag(event: event)
        if resolveWheel(event: event) {
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

    private func vectorFromScreenCenter(of point: NSPoint, window size: CGSize) -> CGVector {
        let center = size / 2.0
        let relativePoint = CGVector(dx: point.x - center.width, dy: point.y - center.height)
        let fractionPoint = CGVector(dx: relativePoint.dx / center.width, dy: relativePoint.dy / center.height)
        return fractionPoint
    }

    // I have decided to use less smooth solution with Timer instead of CVDisplayLink, because we would
    // need to solve problems related to usage of multiple displays.
    //
    // This works as "proof of concept" but is sub optimal and candidate for refactoring.
    private static let trasholdToScroll: CGFloat = 0.25
    private static let tickFrequency: CGFloat = 24
    private static let maxPerTickScroll: CGFloat = 5 / tickFrequency
    private func resolveMouseMove(event: NSEvent) {
        guard
            case .mouseMoved = event.type,
            let windowSize = event.window?.frame.size
        else {
            return
        }

        let deformedVector = vectorFromScreenCenter(of: event.locationInWindow, window: windowSize).invertedDY()
        let trasholdVector = CGVector(
            dx: max(0.0, abs(deformedVector.dx) - Self.trasholdToScroll) / (1.0 - Self.trasholdToScroll) ,
            dy: max(0.0, abs(deformedVector.dy) - Self.trasholdToScroll) / (1.0 - Self.trasholdToScroll)
        )
        let signedTrashold = CGVector(
            dx: (deformedVector.dx > 0.0 ? 1.0 : -1.0) * trasholdVector.dx,
            dy: (deformedVector.dy > 0.0 ? 1.0 : -1.0) * trasholdVector.dy
        )
        self.movementVector = CGVector(
            dx: signedTrashold.dx * Self.maxPerTickScroll,
            dy: signedTrashold.dy * Self.maxPerTickScroll
        )
        updateMovementTimer()
    }

    private func updateMovementTimer() {
        guard presentation.cameraFreeRoam, movementVector != .zero else {
            movementTimer?.invalidate()
            movementTimer = nil
            return
        }
        guard movementTimer == nil else { return }

        movementTimer = Timer.scheduledTimer(withTimeInterval: Double( 1 / Self.tickFrequency ), repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.presentation.camera.offset = CGVector(
                dx: self.presentation.camera.offset.dx + (1 / self.presentation.camera.scale) * Self.maxPerTickScroll * self.movementVector.dx,
                dy: self.presentation.camera.offset.dy + (1 / self.presentation.camera.scale) * Self.maxPerTickScroll * self.movementVector.dy
            )
        }
    }

    private func resolveWheel(event: NSEvent) -> Bool {
        guard case .scrollWheel = event.type, presentation.cameraFreeRoam else {
            return false
        }

        presentation.camera.scale = presentation.camera.scale + (event.scrollingDeltaY / 1500.0)

        return true
    }

    private func resolveClick(event: NSEvent) {
        // We don't want to enter free roam if presentation is locked or user is in unput mode
        guard
            NSApplication.shared.areWindowsFirstResponder,
            presentation.enableDoubleClickFreeRoam
        else {
            return
        }

        guard case .leftMouseDown = event.type else {
            return
        }

        let now = DispatchTime.now()
        let interval = lastClickTime.distance(to: now)
        lastClickTime = now

        if TimeInterval(dispatchTimeInterval: interval).flatMap({ $0 < NSEvent.doubleClickInterval }) ?? false {
            resolveDoubleClick(event: event)
        }
    }

    private func resolveDoubleClick(event: NSEvent) {
        presentation.cameraFreeRoam.toggle()
        updateMovementTimer()
        if !presentation.cameraFreeRoam {
            presentation.hoveredSlide.flatMap(presentation.moveTo(slide:))
            presentation.hoveredSlide = nil
        }
    }

    private func resolveMousePosition(event: NSEvent) {
        guard
            presentation.cameraFreeRoam,
            (event.type == .leftMouseDown || event.type == .mouseMoved),
            let windowSize = event.window?.frame.size
        else {
            return
        }
        let offsetLocation = presentation.offset(for: event.locationInWindow, in: windowSize) + presentation.camera.offset
        presentation.hoveredSlide = presentation.slides.reversed().first { slide in
            presentation.getOffsetRect(of: slide).contains(CGPoint(x: offsetLocation.dx, y: offsetLocation.dy))
        }
    }

    private func resolveSlideDrag(event: NSEvent) {
        guard presentation.mode == .editor else {
            return
        }

        switch event.type {
        case .leftMouseDown where moveSlideMachine == .callFlagDown:
            guard let windowSize = event.window?.frame.size else {
                break
            }
            let offsetLocation = presentation.offset(for: event.locationInWindow, in: windowSize) + presentation.camera.offset
            let slide = presentation.slides.reversed().first { slide in
                presentation.getOffsetRect(of: slide).contains(CGPoint(x: offsetLocation.dx, y: offsetLocation.dy))
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
            let newPosition = presentation.offset(for: event.locationInWindow, in: windowSize) + presentation.camera.offset

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

    private func resolveNavigation(event: NSEvent) -> Bool {
        guard
            NSApplication.shared.areWindowsFirstResponder,
            event.type == .keyDown
        else {
            return false
        }

        switch event.keyCode {
        case 49 /* Space bar*/, 36 /* enter */:
            guard presentation.shouldProceedToNextFocus() else {
                return true
            }
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
            event.keyCode == 53 /* escape */
        else {
            return false
        }

        if !NSApplication.shared.areWindowsFirstResponder {
            NSApplication.shared.makeWindowsFirstResponder()
        } else if presentation.cameraFreeRoam {
            presentation.cameraFreeRoam.toggle()
        } else {
            return false
        }

        return true
    }
}
