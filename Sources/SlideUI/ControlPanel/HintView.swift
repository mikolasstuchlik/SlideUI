import SwiftUI
import SlideUICommons

struct HashedInt: Hashable {
    var int: Int
    let hash: Int
}

struct HintView: View {
    @EnvironmentObject var presentation: PresentationProperties

    @State var hintEditing: [String?]

    init(environment: PresentationProperties) {
        if environment.selectedFocus >= 0, environment.selectedFocus < environment.focuses.count {
            switch environment.focuses[environment.selectedFocus] {
            case let .slides(slides):
                _hintEditing = State(initialValue: slides.map { $0.hint })
            case let .properties(properties):
                _hintEditing = State(initialValue: [properties.hint] )
            }
        } else {
            _hintEditing = State(initialValue: [])
        }
    }

    var body: some View {
        Group {
            if presentation.selectedFocus >= 0, presentation.selectedFocus < presentation.focuses.count {
                switch presentation.focuses[presentation.selectedFocus] {
                case let .properties(properties) where presentation.mode == .editor:
                    VStack {
                        Button("Ulož") {
                            var copy = properties
                            copy.hint = hintEditing[0]
                            presentation.focuses[presentation.selectedFocus] = .properties(copy)
                        }
                        TextEditor(text: .init(
                            get: { hintEditing[0] ?? "" },
                            set: { hintEditing[0] = $0 })
                        )
                    }
                case let .properties(properties):
                    ScrollView { Text(LocalizedStringKey(properties.hint ?? "")) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                case let .slides(slides) where presentation.mode == .editor:
                    ScrollView {
                        VStack {
                            let hash = presentation.focuses[presentation.selectedFocus].hashValue
                            let hashedInts = slides.indices.map { HashedInt(int: $0, hash: hash) }
                            ForEach(hashedInts, id: \.int) { index in
                                HStack {
                                    Button("Ulož") {
                                        slides[index.int].hint = hintEditing[index.int]
                                    }
                                    Text("\(slides[index.int].name)")
                                }
                                TextEditor(text: .init(
                                    get: { hintEditing[index.int] ?? "" },
                                    set: { hintEditing[index.int] = $0 })
                                )
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                case let .slides(slides):
                    let text = slides.compactMap { slide in slide.hint.flatMap { "**\(slide.name)**\n\($0)" } }.joined(separator: "\n\n--\n\n")
                    ScrollView { Text(LocalizedStringKey(text)) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: presentation.selectedFocus, perform: prepareHintEditor(for:))
        .onChange(of: presentation.focuses) { newValue in
            prepareHintEditor(for: presentation.selectedFocus, focuses: newValue)
        }
        .onChange(of: presentation.mode) { _ in
            prepareHintEditor(for: presentation.selectedFocus)
        }

    }

    private func prepareHintEditor(for index: Int) { prepareHintEditor(for: index, focuses: nil)}
    private func prepareHintEditor(for index: Int, focuses: [Focus]?){
        let focuses = focuses ?? presentation.focuses
        if presentation.mode == .editor, index >= 0, index < focuses.count {
            switch focuses[index] {
            case let .slides(slides):
                hintEditing = slides.map { $0.hint }
            case let .properties(properties):
                hintEditing = [properties.hint]
            }
        }
    }
}
