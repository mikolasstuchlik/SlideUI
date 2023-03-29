import SwiftUI
import SlideUI
import SlideUIViews
import SlideUICommons

struct ___VARIABLE_sceneName___: Slide {
    // @offset(___VARIABLE_sceneName___)
    static var offset = CGVector(dx: 0, dy: 0)

    // @hint(___VARIABLE_sceneName___){
    static var hint: String? =
"""

"""
    // }@hint(___VARIABLE_sceneName___)

    init() {}


    private static let defaultCode =
"""
print("Hello world")

"""

    private static let defaultStdIn = [
        "swiftc ___VARIABLE_codeName___.swift && ./___VARIABLE_codeName___"
    ]

    public final class ExposedState: ForwardEventCapturingState {
        public static var stateSingleton: ___VARIABLE_sceneName___.ExposedState = .makeSingleton()

        var execCode: TextEditorView.Model = .init(
            filePath: FileCoordinator.shared.pathToFolder(for: "code") + "/___VARIABLE_codeName___.swift",
            format: .swift,
            content: ___VARIABLE_sceneName___.defaultCode
        )
        var terminal: TerminalView.Model = .init(
            workingPath: URL(fileURLWithPath: FileCoordinator.shared.pathToFolder(for: "code")),
            stdIn: ___VARIABLE_sceneName___.defaultStdIn[0]
        )
        @Published var toggle: Bool = false

        public func captured(forwardEvent number: UInt) -> Bool {
            switch number {
            case 0:
                withAnimation { toggle.toggle() }
            case 1:
                execCode.save()
                terminal.execute()
            case 2:
                withAnimation { toggle.toggle() }
            default:
                return false
            }
            return true
        }
    }
    @StateObject private var state: ExposedState = ExposedState.stateSingleton

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading) {
                Text("Headline").font(.presentationHeadline)
                Text("Subheadline").font(.presentationSubHeadline)
            }
            Text(
"""
Body
"""
            ).font(.presentationBody).frame(maxWidth: .infinity, alignment: .topLeading)
            ToggleView(toggledOn: $state.toggle) {
                VStack {
                    TextEditorView(model: state.execCode)
                    TerminalView(model: state.terminal, aspectRatio: 0.35, axis: .horizontal).frame(height: 200)
                }
            }
        }.padding()
    }
}

struct ___VARIABLE_sceneName____Previews: PreviewProvider {
    static var previews: some View {
        ___VARIABLE_sceneName___()
            .frame(width: 1024, height: 768)
            .environmentObject(PresentationProperties.preview())
    }
}
