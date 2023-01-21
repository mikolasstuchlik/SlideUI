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

    private static let defaultCode =
"""
struct ___VARIABLE_viewName___: View {
    var body: some View {
        Text("Hello, people!")
    }
}

"""

    @State var code: String = ___VARIABLE_sceneName___.defaultCode
    @State var buildCommand: String = RuntimeViewProvider.defaultCommand
    @State var state: CompilerView.State = .idle

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading) {
                Text("Headline").font(.presentationHeadline)
                Text("Subheadline").font(.presentationSubHeadline)
            }
            ToggleView {
                HStack {
                    CompilerView(
                        axis: .horizontal,
                        uniqueName: "___VARIABLE_viewName___",
                        code: $code,
                        state: $state,
                        buildCommand: $buildCommand
                    )
                    switch state {
                    case let .exception(ProcessError.endedWith(code: code, error: message)):
                        Text("Process ended with code \(code). Message: \(message ?? "")").foregroundColor(.red).monospaced()
                    case .exception(let error):
                        Text(error.localizedDescription).foregroundColor(.red)
                    case .view(let view):
                        view
                    case .idle, .loading:
                        Text("Nothing to present")
                    }
                }
            }
        }
        .padding()
    }
}

struct ___VARIABLE_sceneName____Previews: PreviewProvider {
    static var previews: some View {
        ___VARIABLE_sceneName___()
            .frame(width: 1024, height: 768)
            .environmentObject(PresentationProperties.preview())
    }
}
