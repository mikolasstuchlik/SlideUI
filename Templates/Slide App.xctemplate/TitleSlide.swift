import SwiftUI
import SlideUI

struct TitleSlide: Slide {
    // @offset(TitleSlide)
    static var offset = CGVector(dx: 0, dy: 0)

    // @hint(TitleSlide){
    static var hint: String? =
"""

"""
    // }@hint(TitleSlide)

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

struct TitleSlide_Previews: PreviewProvider {
    static var previews: some View {
        TitleSlide()
            .frame(width: 1024, height: 768)
            .environmentObject(PresentationProperties.preview())
    }
}
