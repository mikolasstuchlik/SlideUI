import SwiftUI
import SlideUICommons
import AppKit

public struct Presentation: View {
    @EnvironmentObject var presentation: PresentationProperties
    @StateObject var gestureModel: PresentationGestureModel

    public init(environment: PresentationProperties) {
        self._gestureModel = StateObject(wrappedValue: PresentationGestureModel(presentation: environment))
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Plane()
                    .offset(
                        x: -(presentation.screenSize.width * presentation.camera.offset.dx),
                        y: -(presentation.screenSize.height * presentation.camera.offset.dy)
                    )
                    .scaleEffect(presentation.camera.scale)
                    .clipped()
                    .animation(
                        presentation.mode == .presentation && !presentation.cameraFreeRoam
                            ? .easeInOut(duration: 1.0)
                            : nil,
                        value: presentation.camera
                    )
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
                matching: [.keyDown, .keyUp, .leftMouseDragged, .leftMouseDown, .leftMouseUp, .mouseMoved, .scrollWheel],
                handler: gestureModel.handleMac(event:)
            )
        }
    }
}
