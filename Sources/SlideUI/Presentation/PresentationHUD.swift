import SwiftUI
import AppKit

struct PresentationHUD: View {
    @EnvironmentObject var presentation: PresentationProperties
    @State var editing: Bool = !NSApplication.shared.areWindowsFirstResponder

    public var body: some View {
        HStack(spacing: 8) {
            if editing {
                Button {
                    NSApplication.shared.makeWindowsFirstResponder()
                } label: {
                    Text("LOC_editing")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
            }

            Button {
                presentation.selectedFocus -= 1
            } label: {
                Image(systemName: "arrow.backward.square")
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .frame(width: 25, height: 25)

            Button {
                presentation.selectedFocus = presentation.selectedFocus
            } label: {
                Text("\(presentation.selectedFocus) / \(presentation.focuses.count)")
            }
            .buttonStyle(.plain)

            Button {
                presentation.selectedFocus += 1
            } label: {
                Image(systemName: "arrow.forward.square")
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .frame(width: 25, height: 25)

            Button {
                presentation.cameraFreeRoam.toggle()
            } label: {
                Image(systemName: presentation.cameraFreeRoam ? "lock.open.display" : "lock.display")
                    .resizable()
                    .foregroundStyle(presentation.cameraFreeRoam ? .red : .primary)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .frame(width: 25, height: 25)


        }.onReceive(NotificationCenter.default.publisher(for: NSWindow.willChangeFirstResponder)) { notification in
            editing = !NSApplication.shared.areWindowsFirstResponder
        }
    }
}
