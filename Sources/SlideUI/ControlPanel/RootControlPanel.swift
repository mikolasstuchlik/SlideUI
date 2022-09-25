import SwiftUI
import SlideUICommons

private let timeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateFormat = .none
    return formatter
}()

@available(macOS 13.0, *)
struct SlideControlPanel: View {

    @EnvironmentObject var presentation: PresentationProperties
    @Environment(\.openWindow) private var openWindow


    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 16) {
                Button {
                    openWindow(id: "slides")
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .foregroundStyle(.primary, .secondary, .green)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                .frame(width: 50, height: 50)
                if presentation.mode != .editor {
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
                Text("Klávesové zkratky").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text(presentation.mode.hotkeyHint.joined(separator: "\n"))
                Text("Ovládání prezentace").bold().frame(maxWidth: .infinity, alignment: .leading)
                VStack {
                    Grid {
                        GridRow {
                            Text("Režim")
                            Picker(
                                "",
                                selection: .init(
                                    get: {
                                        presentation.mode.rawValue
                                    },
                                    set: {
                                        presentation.mode = .init(rawValue: $0)!
                                    }
                                )
                            ) {
                                Text("Inspekce").tag(0)
                                Text("Prezentace").tag(1)
                                Text("Editor").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .gridCellColumns(2)
                            Button("Reload placeholders") {
                                presentation.loadThumbnails.toggle()
                            }
                        }
                        if presentation.mode == .entry {
                            InputModePanel()
                        }
                        if presentation.mode == .editor {
                            EditModePanel(environment: presentation)
                        }
                    }
                }
            }
            Divider()
            VStack(spacing: 16) {
                Text("Poznámky pro zaostřené").bold().frame(maxWidth: .infinity, alignment: .leading)
                HintView(environment: presentation)
            }
        }.padding()
    }

}

