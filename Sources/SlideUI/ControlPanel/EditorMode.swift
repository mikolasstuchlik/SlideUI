import SwiftUI
import SlideUICommons

struct EditModePanel: View {
    @EnvironmentObject var presentation: PresentationProperties

    @State var selectedFocusHash: Int?
    @State var focusesChangeContext: [[String]]

    init(environment: PresentationProperties) {
        _focusesChangeContext = State(initialValue: EditModePanel.makeFocusesChangeContext(with: environment.focuses))
        if environment.selectedFocus >= 0, environment.selectedFocus < environment.focuses.count {
            _selectedFocusHash = State(initialValue: environment.focuses[environment.selectedFocus].hashValue)
        } else {
            _selectedFocusHash = State(initialValue: nil)
        }
    }

    var body: some View {
        GridRow {
            Text("Code generation")
            Button("Save offsets") {
                let editor = OffsetCodeManipulator(slidesPath: presentation.slidesPath, knowSlides: presentation.slides)
                print(editor.saveUpdatesToSourceCode())
            }
            Button("Save focuses & Hints") {
                let editor = FocusCodeManipulator(rootPath: presentation.rootPath, knowSlides: presentation.slides, knownFocuses: presentation.focuses)
                print(editor.saveUpdatesToSourceCode())
            }
        }
        GridRow {
            focusEditor
                .gridCellColumns(4)
                .frame(idealHeight: .infinity, maxHeight: .infinity)
        }
        GridRow {
            HStack {
                Button("Přidej focus na slidy") {
                    focusesChangeContext.append([])
                    presentation.focuses.append(.slides([]))
                }
                Button("Přidej focus na souřadnice") {
                    let properties = Focus.Properties(offset: presentation.camera.offset, scale: presentation.camera.scale)
                    focusesChangeContext.append(["\(properties.offset.dx)", "\(properties.offset.dy)", "\(properties.scale)"])
                    presentation.focuses.append(.properties(properties))
                }
            }.gridCellColumns(4)
        }
    }

    @ViewBuilder var focusEditor: some View {
        List(
            selection: .init(
                get: {
                    selectedFocusHash
                },
                set: { newHash in
                    guard let index = presentation.focuses.firstIndex(where: { $0.hashValue == newHash }) else {
                        selectedFocusHash = nil
                        return
                    }
                    selectedFocusHash = newHash
                    presentation.selectedFocus = index
                }
            )
        ) {
            ForEach(presentation.focuses, id: \.hashValue) { focus in
                let index = presentation.focuses.firstIndex(of: focus)!
                HStack() {
                    switch focus {
                    case .slides(_):
                        slidesTokenView(at: index)
                    case let .properties(properties):
                        Button("Ulož") {
                            var copy = properties
                            let dx = Double(focusesChangeContext[index][0]).flatMap(CGFloat.init(_:))
                            let dy = Double(focusesChangeContext[index][1]).flatMap(CGFloat.init(_:))
                            let scale = Double(focusesChangeContext[index][2]).flatMap(CGFloat.init(_:))
                            copy.offset.dx = dx ?? copy.offset.dx
                            copy.offset.dy = dy ?? copy.offset.dy
                            copy.scale = scale ?? copy.scale
                            presentation.focuses[index] = .properties(copy)
                        }
                        Divider()
                        Text("X")
                        TextEditor(text: .init(get: { focusesChangeContext[index][0] }, set: { focusesChangeContext[index][0] = $0 }))
                        Text("Y")
                        TextEditor(text: .init(get: { focusesChangeContext[index][1] }, set: { focusesChangeContext[index][1] = $0 }))
                        Text("Scale")
                        TextEditor(text: .init(get: { focusesChangeContext[index][2] }, set: { focusesChangeContext[index][2] = $0 }))
                    }
                }
            }.onMove { source, destination in
                presentation.focuses.move(fromOffsets: source, toOffset: destination)
                focusesChangeContext = EditModePanel.makeFocusesChangeContext(with: presentation.focuses)
            }.onDelete { toDelete in
                presentation.focuses.remove(atOffsets: toDelete)
                focusesChangeContext = EditModePanel.makeFocusesChangeContext(with: presentation.focuses)
            }
        }
        .onChange(of: presentation.focuses) { newValue in
            focusesChangeContext = EditModePanel.makeFocusesChangeContext(with: newValue)
        }
    }

    static func makeFocusesChangeContext(with value: [Focus]) -> [[String]] {
        return value.map { item -> [String] in
            switch item {
            case let .properties(properties):
                return ["\(properties.offset.dx)", "\(properties.offset.dy)", "\(properties.scale)"]
            case let .slides(slides):
                return slides.map { $0.name }
            }
        }
    }

    @ViewBuilder func slidesTokenView(at index: Int) -> some View {
        Button("Ulož") {
            let types: [any Slide.Type] = focusesChangeContext[index].compactMap { name in
                presentation.slides.first { $0.name == name }
            }

            presentation.focuses[index] = .slides(types)
        }
        Divider()
        ForEach(focusesChangeContext[index], id: \.self) { slideName in
            let slideIndex = focusesChangeContext[index].firstIndex(of: slideName)!
            Button {
                focusesChangeContext[index].remove(at: slideIndex)
            }
            label: {
                HStack {
                    Text(slideName)
                    Image(systemName: "trash")
                }
            }
        }
        Divider()
        Menu("Přidej") {
            ForEach(presentation.slides.indices) { slideIndex in
                let name = presentation.slides[slideIndex].name
                Button(name) {
                    if !focusesChangeContext[index].contains(where: { $0 == name }) {
                        focusesChangeContext[index].append(name)
                    }
                }
            }
        }.frame(width: 100)
    }
}
