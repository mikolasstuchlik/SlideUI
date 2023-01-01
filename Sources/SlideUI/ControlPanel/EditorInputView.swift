import SwiftUI
import SlideUICommons

struct InputEditorView: View {
    @EnvironmentObject var presentation: PresentationProperties

    @Binding var selectedFocusUUID: UUID?
    @Binding var selectedSlideIndex: Int?

    var body: some View {
        if let selectedFocusUUID {
            FocusEditor(selectedFocusUUID: $selectedFocusUUID)
        } else if let selectedSlideIndex {
            SlideEditor(selectedSlideIndex: $selectedSlideIndex)
        } else {
            Text("LOC_pick_item_to_edit")
        }
    }
}

private struct SlideEditor: View {
    @EnvironmentObject var presentation: PresentationProperties

    @Binding var selectedSlideIndex: Int?
    @State var previousSelection: Int? = nil

    @State var XEntry: String = ""
    @State var YEntry: String = ""
    @State var hint: String = ""

    var body: some View {
        VStack {
            Button("LOC_apply") {
                store(index: selectedSlideIndex)
            }
            TextField("LOC_X", text: $XEntry)
            TextField("LOC_Y", text: $YEntry)
            TextEditor(text: $hint)
        }
        .onAppear {
            previousSelection = selectedSlideIndex
            load(index: selectedSlideIndex)
        }
        .onChange(of: selectedSlideIndex) { newValue in
            store(index: previousSelection)
            load(index: newValue)
            previousSelection = newValue
        }
        .onDisappear {
            store(index: previousSelection)
        }
    }

    private func store(index: Int?) {
        guard let index else {
            return
        }

        presentation.slides[index].hint = hint
        Double(XEntry).flatMap { presentation.slides[index].offset.dx = $0 }
        Double(YEntry).flatMap { presentation.slides[index].offset.dy = $0 }
    }

    private func load(index: Int?) {
        guard let index else {
            return
        }

        hint = presentation.slides[index].hint ?? ""
        XEntry = String(describing: presentation.slides[index].offset.dx)
        YEntry = String(describing: presentation.slides[index].offset.dy)
    }
}

private struct FocusEditor: View {
    enum Kind: Int {
        case unbound, specific
    }

    @EnvironmentObject var presentation: PresentationProperties
    @Binding var selectedFocusUUID: UUID?
    @State var previousSelection: UUID? = nil

    @State var kind: Kind = .unbound
    @State var slides: [any Slide.Type] = []
    @State var XEntry: String = ""
    @State var YEntry: String = ""
    @State var scaleEntry: String = ""
    @State var hint: String = ""

    var body: some View {
        VStack {
            Button("LOC_apply") {
                store(uuid: selectedFocusUUID)
            }
            Picker("LOC_type", selection: .init(
                    get: { kind.rawValue },
                    set: { kind = .init(rawValue: $0)! }
            )) {
                Text("LOC_freecam").tag(0)
                Text("LOC_slide_focus").tag(1)
            }
            .pickerStyle(.segmented)

            switch kind {
            case .specific:
                ForEach(slides.map { $0.name }, id: \.self) { slideName in
                    Button {
                        slides.removeAll(where: { $0.name == slideName })
                    }
                    label: {
                        HStack {
                            Text(slideName)
                            Image(systemName: "trash")
                        }
                    }
                }
                Divider()
                Menu("LOC_add") {
                    ForEach(presentation.slides.indices) { slideIndex in
                        let name = presentation.slides[slideIndex].name
                        Button(name) {
                            if !slides.contains(where: { $0.name == name }) {
                                slides.append(presentation.slides[slideIndex])
                            }
                        }
                    }
                }.frame(width: 100)
            case .unbound:
                TextField("LOC_X", text: $XEntry)
                TextField("LOC_Y", text: $YEntry)
                TextField("LOC_scale", text: $scaleEntry)
            }
            TextEditor(text: $hint)
        }
        .onAppear {
            previousSelection = selectedFocusUUID
            load(uuid: selectedFocusUUID)
        }
        .onChange(of: selectedFocusUUID) { newValue in
            store(uuid: previousSelection)
            load(uuid: newValue)
            previousSelection = newValue
        }
        .onDisappear {
            store(uuid: previousSelection)
        }
    }
    private func store(uuid: UUID?) {
        guard let uuid, let index = presentation.focuses.firstIndex(where: {$0.uuid == uuid }) else {
            return
        }

        presentation.focuses[index].hint = hint

        switch kind {
        case .unbound:
            presentation.focuses[index].kind = .unbound(Camera(
                offset: CGVector(
                    dx: Double(XEntry) ?? 0.0,
                    dy: Double(YEntry) ?? 0.0
                ),
                scale: Double(scaleEntry) ?? 0.99
            ))
        case .specific:
            presentation.focuses[index].kind = .specific(slides)
        }

    }

    private func load(uuid: UUID?) {
        guard let uuid, let focus = presentation.focuses.first(where: {$0.uuid == uuid }) else {
            return
        }

        self.hint = focus.hint ?? ""

        switch focus.kind {
        case .specific(let slides):
            self.kind = .specific
            self.slides = slides
            self.XEntry = ""
            self.YEntry = ""
            self.scaleEntry = ""
        case .unbound(let camera):
            self.kind = .unbound
            self.slides = []
            self.XEntry = String(describing: camera.offset.dx)
            self.YEntry = String(describing: camera.offset.dy)
            self.scaleEntry = String(describing: camera.scale)
        }

    }
}
