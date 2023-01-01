import SwiftUI
import SlideUICommons

struct InputModePanel: View {
    @EnvironmentObject var presentation: PresentationProperties

    @State var screenXManualEntry: String = ""
    @State var screenYManualEntry: String = ""

    @State var slideXManualEntry: String = ""
    @State var slideYManualEntry: String = ""

    var body: some View {
        GridRow {
            Text("LOC_screen_size")
            HStack {
                Button("LOC_apply") {
                    if let w = Double(screenXManualEntry), let h = Double(screenYManualEntry) {
                        presentation.screenSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                    }
                }
                Toggle(isOn: $presentation.automaticScreenSize, label: { Text("LOC_automatic") })
            }
            TextField("LOC_X", text: $screenXManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenXManualEntry = "\($0.width)" }
            TextField("LOC_Y", text: $screenYManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenYManualEntry = "\($0.height)" }
        }
        GridRow {
            Text("LOC_scene_size")
            HStack {
                Button("LOC_apply") {
                    if let w = Double(slideXManualEntry), let h = Double(slideYManualEntry) {
                        presentation.frameSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                    }
                }
                Toggle(isOn: $presentation.automaticFameSize, label: { Text("LOC_automatic") })
            }
            TextField("LOC_X", text: $slideXManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideXManualEntry = "\($0.width)" }
            TextField("LOC_Y", text: $slideYManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideYManualEntry = "\($0.height)" }
        }
        GridRow {
            Text("LOC_color_scheme")
            Spacer()
            Spacer()
            Picker(
                "",
                selection: .init(
                    get: {
                        presentation.colorScheme == .dark ? 0 : 1
                    },
                    set: {
                        presentation.colorScheme = $0 == 0 ? .dark : .light
                    }
                )
            ) {
                Text("LOC_dark").tag(0)
                Text("LOC_light").tag(1)
            }
            .pickerStyle(.segmented)
        }
        GridRow {
            Text("LOC_font")
            Grid(alignment: .trailing) {
                GridRow {
                    FontPicker("LOC_title", selection: $presentation.title)
                    FontPicker("LOC_headline", selection: $presentation.headline)
                    FontPicker("LOC_body", selection: $presentation.body)
                }
                GridRow {
                    FontPicker("LOC_subtitle", selection: $presentation.subTitle)
                    FontPicker("LOC_subheadline", selection: $presentation.subHeadline)
                    FontPicker("LOC_note", selection: $presentation.note)
                }
                GridRow {
                    Slider(
                        value: $presentation.codeEditorFontSize,
                        in: CGFloat(15.0)...CGFloat(40.0),
                        step: 1.0,
                        label: { Text("LOC_editor_size") + Text(" \(presentation.codeEditorFontSize)") }
                    ).gridCellColumns(2)
                }
            }.gridCellColumns(3)
        }
    }
}
