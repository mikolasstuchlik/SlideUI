import SwiftUI
import SlideUICommons

private let timeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateFormat = .none
    return formatter
}()

public struct SlideControlPanel: View {
    public init() { }

    @EnvironmentObject var presentation: PresentationProperties
    @Environment(\.openWindow) private var openWindow
    @State var selectedFocusUUID: UUID?
    @State var selectedSlideIndex: Int?

    public var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 16) {
                HStack {
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
                    Button("Reload placeholders") {
                        presentation.loadThumbnails.toggle()
                    }
                }
                if presentation.mode != .editor {
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
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
                                Text("Prezentace").tag(0)
                                Text("Editor").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .gridCellColumns(2)
                            Spacer()
                        }
                        InputModePanel()
                        if presentation.mode == .editor {
                            EditModePanel(selectedFocusUUID: $selectedFocusUUID, selectedSlideIndex: $selectedSlideIndex )
                        }
                    }
                }
            }
            Divider()
            VStack(spacing: 16) {
                if presentation.mode == .presentation {
                    Text("Poznámky pro zaostřené").bold().frame(maxWidth: .infinity, alignment: .leading)
                    HintView()
                } else {
                    InputEditorView(selectedFocusUUID: $selectedFocusUUID, selectedSlideIndex: $selectedSlideIndex)
                }
            }
        }.padding()
    }

}

