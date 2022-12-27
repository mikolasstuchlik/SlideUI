import SwiftUI

public struct OutlineView<C: View>: View {
    public init(title: String, @ViewBuilder content: @escaping () -> C) {
        self.title = title
        self.content = content
    }

    public let title: String
    @ViewBuilder public var content: () -> C
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                content()
            }
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.gray, style: StrokeStyle(lineWidth: 1, dash: [3]))
            )
            .padding(6)
            Text(title)
                .background( EffectView(material: .windowBackground))
                .padding(.leading, 16)
                .foregroundColor(.gray)
                .font(.system(.footnote))
        }
    }
}

struct OutlineView_Previews: PreviewProvider {
    static var previews: some View {
        OutlineView(title: "Ahoj" ) { Text("Hello") }
    }
}
