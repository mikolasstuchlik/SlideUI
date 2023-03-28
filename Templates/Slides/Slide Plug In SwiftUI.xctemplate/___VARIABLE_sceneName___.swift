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

    public final class ExposedState: ForwardEventCapturingState {
        public static var stateSingleton: ___VARIABLE_sceneName___.ExposedState = .init()

        @Published var toggle: Bool = false

        public func captured(forwardEvent number: UInt) -> Bool {
            switch number {
            case 0:
                withAnimation { toggle.toggle() }
            case 1:
                withAnimation { toggle.toggle() }
            default:
                return false
            }
            return true
        }
    }
    @ObservedObject private var state: ExposedState = ExposedState.stateSingleton

    // It was observed, that view fails to update state if `compiler` SO is inside of ExposedState...
    @StateObject var compiler: CompilerView.Model = .init(uniqueName: "___VARIABLE_viewName___", code: ___VARIABLE_sceneName___.defaultCode)

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading) {
                Text("Headline").font(.presentationHeadline)
                Text("Subheadline").font(.presentationSubHeadline)
            }
            ToggleView(toggledOn: $state.toggle) {
                HStack {
                    CompilerView(model: compiler, axis: .horizontal)
                    switch compiler.state {
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
