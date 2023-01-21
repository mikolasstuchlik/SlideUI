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

    @State var content: String = ___VARIABLE_sceneName___.defaultCode
    @State var state: TerminalView.State = .idle
    @State var stdin: String = ___VARIABLE_sceneName___.defaultStdIn[0]

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
            ToggleView {
                VStack {
                    TextEditorView(
                        axis: .vertical,
                        filePath: FileCoordinator.shared.pathToFolder(for: "code") + "/___VARIABLE_codeName___.swift",
                        format: .constant(.swift),
                        content: $content
                    )
                    TerminalView(
                        axis: .horizontal,
                        workingPath: URL(fileURLWithPath: FileCoordinator.shared.pathToFolder(for: "code")),
                        aspectRatio: 0.25,
                        stdIn: $stdin,
                        state: $state
                    ).frame(height: 200)
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
