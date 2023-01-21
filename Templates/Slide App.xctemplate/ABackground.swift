import SwiftUI
import SlideUI
import SlideUICommons

struct ABackground: Background {
    static var offset = CGVector(dx: 0, dy: 0)
    static var relativeSize: CGSize = CGSize(width: 4, height: 1.5) / scale
    static var scale: CGFloat = 4.0

    init() {}

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("Hello!")
                .font(.system(size: 375 / Self.scale, weight: .bold))
                .foregroundColor(.blue)
                .padding(.leading, 40 / Self.scale)
            RoundedRectangle(cornerRadius: 40 / Self.scale).stroke(.blue, style: StrokeStyle(lineWidth: 20 / Self.scale, dash: [])).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ABackground_Previews: PreviewProvider {
    static var previews: some View {
        ABackground()
            .frame(width: 1024, height: 768)
            .environmentObject(PresentationProperties.preview())
    }
}
