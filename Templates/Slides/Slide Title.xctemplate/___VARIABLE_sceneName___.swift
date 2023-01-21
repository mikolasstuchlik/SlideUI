import SwiftUI
import SlideUI

struct ___VARIABLE_sceneName___: Slide {
    // @offset(___VARIABLE_sceneName___)
    static var offset = CGVector(dx: 0, dy: 0)

    // @hint(___VARIABLE_sceneName___){
    static var hint: String? =
"""

"""
    // }@hint(___VARIABLE_sceneName___)

    init() {}

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Text("Title")
                    .font(.presentationTitle)
                Text("SubTitle")
                    .font(.presentationSubTitle)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            Text("Signature, company, date")
                .font(.presentationNote)
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
