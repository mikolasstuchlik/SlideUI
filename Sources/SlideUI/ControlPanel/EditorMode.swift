import SwiftUI
import SlideUICommons

struct EditModePanel: View {
    public enum Editing: Int {
        case slides, focuses
    }

    @EnvironmentObject var presentation: PresentationProperties
    @State var editing = Editing.focuses
    @Binding var selectedFocusUUID: UUID?
    @Binding var selectedSlideIndex: Int?

    var body: some View {
        GridRow {
            Text(NSLocalizedString("LOC_code_gen", bundle: .module, comment: "LOC_code_gen"))
            Button(NSLocalizedString("LOC_generate", bundle: .module, comment: "LOC_generate")) {
                let slidesEditor = OffsetCodeManipulator(slidesPath: presentation.slidesPath, knowSlides: presentation.slides)
                print(slidesEditor.saveUpdatesToSourceCode())
                let focusEditor = FocusCodeManipulator(rootPath: presentation.rootPath, knowSlides: presentation.slides, knownFocuses: presentation.focuses)
                print(focusEditor.saveUpdatesToSourceCode())
            }.gridCellColumns(2)
        }
        GridRow {
            Text(NSLocalizedString("LOC_mode", bundle: .module, comment: "LOC_mode"))
            Picker(
                "",
                selection: .init(
                    get: {
                        editing.rawValue
                    },
                    set: {
                        selectedFocusUUID = nil
                        selectedSlideIndex = nil
                        editing = .init(rawValue: $0)!
                    }
                )
            ) {
                Text(NSLocalizedString("LOC_slides", bundle: .module, comment: "LOC_slides")).tag(0)
                Text(NSLocalizedString("LOC_presentation_steps", bundle: .module, comment: "LOC_presentation_steps")).tag(1)
            }
            .pickerStyle(.segmented)
            .gridCellColumns(2)
            Spacer()
        }
        switch editing {
        case .focuses:
            FocusEditMode(selectedFocusUUID: $selectedFocusUUID)
        case .slides:
            SlideEditMode(selectedSlideIndex: $selectedSlideIndex)
        }
    }
}

private struct SlideEditMode: View {
    @EnvironmentObject var presentation: PresentationProperties
    @Binding var selectedSlideIndex: Int?

    var body: some View {GridRow {
        List(selection: $selectedSlideIndex) {
            ForEach(presentation.slides.indices) { index in
                let slide = presentation.slides[index]
                HStack() {
                    Text(String(describing: slide.self))
                }
            }
        }
        .gridCellColumns(3)
        .frame(maxHeight: 200)
    }
    }
}

private struct FocusEditMode: View {
    @EnvironmentObject var presentation: PresentationProperties
    @Binding var selectedFocusUUID: UUID?

    var body: some View {
        GridRow {
            Text(NSLocalizedString("LOC_presentation_step", bundle: .module, comment: "LOC_presentation_step"))
            Button(NSLocalizedString("LOC_add_step", bundle: .module, comment: "LOC_add_step")) {
                presentation.focuses.append(Focus(kind: .unbound(presentation.camera), hint: NSLocalizedString("LOC_step", bundle: .module, comment: "LOC_step") + " \(presentation.focuses.count)"))
            }
            Spacer().gridCellColumns(2)
        }
        GridRow {
            List(selection: $selectedFocusUUID) {
                ForEach(presentation.focuses, id: \.uuid) { focus in
                    HStack() {
                        Text(focus.uuid.uuidString.prefix(5)).frame(width: 60)
                        Text(" - ")
                        Text(focus.hint?.prefix(40) ?? "")
                    }
                }.onMove { source, destination in
                    presentation.focuses.move(fromOffsets: source, toOffset: destination)
                }.onDelete { toDelete in
                    presentation.focuses.remove(atOffsets: toDelete)
                }
            }
            .gridCellColumns(3)
            .frame(maxHeight: 200)
        }
    }
}
