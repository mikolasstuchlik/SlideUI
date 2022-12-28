import SwiftUI

struct PresentationHUD: View {
    @EnvironmentObject var presentation: PresentationProperties
    @State var editing: Bool = !NSApplication.shared.areWindowsFirstResponder

    public var body: some View {
        HStack(spacing: 8) {
            if editing {
                Text("Editing")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
            Image(systemName: presentation.cameraFreeRoam ? "lock.open.display" : "lock.display")
                .resizable()
                .foregroundStyle(presentation.cameraFreeRoam ? .red : .primary)
                .frame(width: 25, height: 25)
        }.onReceive(NotificationCenter.default.publisher(for: NSWindow.willChangeFirstResponder)) { notification in
            editing = !NSApplication.shared.areWindowsFirstResponder
        }
    }
}
