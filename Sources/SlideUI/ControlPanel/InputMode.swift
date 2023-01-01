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
            Text(NSLocalizedString("LOC_screen_size", bundle: .module, comment: "LOC_screen_size"))
            HStack {
                Button(NSLocalizedString("LOC_apply", bundle: .module, comment: "LOC_apply")) {
                    if let w = Double(screenXManualEntry), let h = Double(screenYManualEntry) {
                        presentation.screenSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                    }
                }
                Toggle(isOn: $presentation.automaticScreenSize, label: { Text(NSLocalizedString("LOC_automatic", bundle: .module, comment: "LOC_automatic")) })
            }
            TextField(NSLocalizedString("LOC_X", bundle: .module, comment: "LOC_X"), text: $screenXManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenXManualEntry = "\($0.width)" }
            TextField(NSLocalizedString("LOC_Y", bundle: .module, comment: "LOC_Y"), text: $screenYManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenYManualEntry = "\($0.height)" }
        }
        GridRow {
            Text(NSLocalizedString("LOC_scene_size", bundle: .module, comment: "LOC_scene_size"))
            HStack {
                Button(NSLocalizedString("LOC_apply", bundle: .module, comment: "LOC_apply")) {
                    if let w = Double(slideXManualEntry), let h = Double(slideYManualEntry) {
                        presentation.frameSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                    }
                }
                Toggle(isOn: $presentation.automaticFameSize, label: { Text(NSLocalizedString("LOC_automatic", bundle: .module, comment: "LOC_automatic")) })
            }
            TextField(NSLocalizedString("LOC_X", bundle: .module, comment: "LOC_X"), text: $slideXManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideXManualEntry = "\($0.width)" }
            TextField(NSLocalizedString("LOC_Y", bundle: .module, comment: "LOC_Y"), text: $slideYManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideYManualEntry = "\($0.height)" }
        }
        GridRow {
            Text(NSLocalizedString("LOC_color_scheme", bundle: .module, comment: "LOC_color_scheme"))
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
                Text(NSLocalizedString("LOC_dark", bundle: .module, comment: "LOC_dark")).tag(0)
                Text(NSLocalizedString("LOC_light", bundle: .module, comment: "LOC_light")).tag(1)
            }
            .pickerStyle(.segmented)
        }
        GridRow {
            Text(NSLocalizedString("LOC_font", bundle: .module, comment: "LOC_font"))
            Grid(alignment: .trailing) {
                GridRow {
                    FontPicker(NSLocalizedString("LOC_title", bundle: .module, comment: "LOC_title"), selection: $presentation.title)
                    FontPicker(NSLocalizedString("LOC_headline", bundle: .module, comment: "LOC_headline"), selection: $presentation.headline)
                    FontPicker(NSLocalizedString("LOC_body", bundle: .module, comment: "LOC_body"), selection: $presentation.body)
                }
                GridRow {
                    FontPicker(NSLocalizedString("LOC_subtitle", bundle: .module, comment: "LOC_subtitle"), selection: $presentation.subTitle)
                    FontPicker(NSLocalizedString("LOC_subheadline", bundle: .module, comment: "LOC_subheadline"), selection: $presentation.subHeadline)
                    FontPicker(NSLocalizedString("LOC_note", bundle: .module, comment: "LOC_note"), selection: $presentation.note)
                }
                GridRow {
                    Slider(
                        value: $presentation.codeEditorFontSize,
                        in: CGFloat(15.0)...CGFloat(40.0),
                        step: 1.0,
                        label: { Text(NSLocalizedString("LOC_editor_size", bundle: .module, comment: "LOC_editor_size")) + Text(" \(presentation.codeEditorFontSize)") }
                    ).gridCellColumns(2)
                }
            }.gridCellColumns(3)
        }
    }
}
