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
            Text("Velikost obrazovky")
            Toggle(isOn: $presentation.automaticScreenSize, label: { Text("Automaticky") })
            TextField("X", text: $screenXManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenXManualEntry = "\($0.width)" }
            TextField("Y", text: $screenYManualEntry)
                .disabled(presentation.automaticScreenSize)
                .onChange(of: presentation.screenSize) { screenYManualEntry = "\($0.height)" }
        }
        GridRow {
            Spacer()
            Spacer()
            Spacer()
            Button("Použít") {
                if let w = Double(screenXManualEntry), let h = Double(screenYManualEntry) {
                    presentation.screenSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                }
            }
        }
        GridRow {
            Text("Velikost slidu")
            Toggle(isOn: $presentation.automaticFameSize, label: { Text("Automaticky") })
            TextField("X", text: $slideXManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideXManualEntry = "\($0.width)" }
            TextField("Y", text: $slideYManualEntry)
                .disabled(presentation.automaticFameSize)
                .onChange(of: presentation.frameSize) { slideYManualEntry = "\($0.height)" }
        }
        GridRow {
            Spacer()
            Spacer()
            Spacer()
            Button("Použít") {
                if let w = Double(slideXManualEntry), let h = Double(slideYManualEntry) {
                    presentation.frameSize = CGSize(width: CGFloat(w), height: CGFloat(h))
                }
            }
        }
        GridRow {
            Text("Barevné schéma")
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
                Text("Dark").tag(0)
                Text("Light").tag(1)
            }
            .pickerStyle(.segmented)
        }
        GridRow {
            Text("Fonty")
            Grid(alignment: .trailing) {
                GridRow {
                    FontPicker("Titulek", selection: $presentation.title)
                    FontPicker("Napis", selection: $presentation.headline)
                    FontPicker("Tělo", selection: $presentation.body)
                }
                GridRow {
                    FontPicker("Podtitulek", selection: $presentation.subTitle)
                    FontPicker("Podnadpis", selection: $presentation.subHeadline)
                    FontPicker("Poznámka", selection: $presentation.note)
                }
                GridRow {
                    Slider(
                        value: $presentation.codeEditorFontSize,
                        in: CGFloat(15.0)...CGFloat(40.0),
                        step: 1.0,
                        label: { Text("Editor font \(presentation.codeEditorFontSize)") }
                    ).gridCellColumns(2)
                }
            }.gridCellColumns(3)
        }
    }
}
