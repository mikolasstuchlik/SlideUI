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

    public final class ExposedState: ForwardEventCapturingState {
        public static var stateSingleton: ___VARIABLE_sceneName___.ExposedState = .init()

        @Published var toggle: Bool = false

        public func captured(forwardEvent number: UInt) -> Bool {
            switch number {
            case 0:
                toggle.toggle()
            case 1:
                toggle.toggle()
            default:
                return false
            }
            return true
        }
    }
    @ObservedObject private var state: ExposedState = ExposedState.stateSingleton

    init() {}

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading) {
                Text("Headline").font(.presentationHeadline)
                Text("Subheadline").font(.presentationSubHeadline)
            }
            ToggleView(toggledOn: $state.toggle) {
                WebView(url: URL(string: "https://apple.com")!)
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
