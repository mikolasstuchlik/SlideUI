import SwiftUI
import SlideUICommons

struct HintView: View {
    @EnvironmentObject var presentation: PresentationProperties

    var body: some View {
        Group {
            if let hint = presentation.hint {
                ScrollView { Text(LocalizedStringKey(hint)) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
