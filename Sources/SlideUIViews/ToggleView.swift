import SwiftUI
import SlideUI

public struct ToggleView<C: View>: View {
    @EnvironmentObject public var presentation: PresentationProperties
    
    @ViewBuilder public var content: () -> C
    
    public var alignment: Alignment = .bottomTrailing
    @State public var toggledOn: Bool = fa lse
    @State public var placeholder: NSImage? = nil

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: alignment) {
                if toggledOn {
                    content()
                } else if let image = placeholder {
                    Image(nsImage: image)
                        .blur(radius: 10)
                } else if C.self == WebView.self {
                    Image("safari")
                        .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                        .scaledToFit()
                        .clipped()
                        .blur(radius: 10)
                }
                toggleButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: presentation.loadThumbnails) { _ in
                Task {
                    guard C.self != WebView.self else {
                        return
                    }
                    
                    content()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .renderAsImage(delay: TimeInterval.random(in: 0.1...4.0)) { image in
                            placeholder = image
                        }
                }
            }
        }
    }
    
    private var toggleButton: some View {
        Button {
            toggledOn.toggle()
        } label: {
            Image(
                systemName: toggledOn
                    ? "stop.circle.fill"
                    : "play.circle.fill"
            )
            .resizable()
            .foregroundStyle(
                .primary,
                .secondary,
                toggledOn ? .red : .green
            )
            .frame(width: 25, height: 25)
        }
        .buttonStyle(.plain)
    }
}

struct ToggleView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleView { Text("Hello") }
    }
}
