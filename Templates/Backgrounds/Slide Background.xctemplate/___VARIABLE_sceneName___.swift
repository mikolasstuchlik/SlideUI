import SwiftUI
import SlideUI
import SlideUICommons

struct ___VARIABLE_sceneName___: Background {
    static var offset = CGVector(dx: -1, dy: -1)
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

struct ___VARIABLE_sceneName____Previews: PreviewProvider {
    static var previews: some View {
        ___VARIABLE_sceneName___()
            .frame(width: 1024, height: 768)
            .environmentObject(PresentationProperties.preview())
    }
}
