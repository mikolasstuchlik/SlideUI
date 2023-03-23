import SwiftUI
import SlideUI

/// `ToggleView` is used to temporarily hide views with high presentation cost. For example, if a view contains web-page or
/// editor, it might be beneficial to wrap it in a toggle view, the resources needed for disaplying the content are saved.
///
/// Toggle view also supports thunbnails - either provided in the initializer or rendered by the `ToggleView` based on the content.
/// Notice, that there is a hard-coded exception for `WebView` which can not automatically generate thumbnail.
///
/// Toggle view uses geometry reader, but only for the purposes of WebView. Maybe it would be better, to ommit the exception
/// and refrein from using geomtery reader...
public struct ToggleView<C: View>: View {

    /// - Parameters:
    ///   - toggledOn: Whether the initial state is on or off 
    ///   - alignment: Alignment of the content of the content
    ///   - placeholder: Placeholder displayed when toggle is off
    ///   - content: What that should be displayed when toggle is on
    public init(toggledOn: Binding<Bool>, alignment: Alignment = .bottomTrailing, placeholder: NSImage? = nil, @ViewBuilder content: @escaping () -> C) {
        self.content = content
        self.alignment = alignment
        self._toggledOn = toggledOn
        self.placeholder = placeholder
    }

    @EnvironmentObject public var presentation: PresentationProperties

    @ViewBuilder public var content: () -> C

    /// Alignment of the content in the view
    public var alignment: Alignment = .bottomTrailing

    /// Should display content or thumbnail
    @Binding public var toggledOn: Bool

    /// Placeholder displayed when toggle is off.
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
                ToggleButton(toggledOn: $toggledOn)
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

    private struct ToggleButton: View {
        @Binding var toggledOn: Bool
        var body: some View {
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
}

struct ToggleView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleView(toggledOn: .constant(false)) { Text("Hello") }
    }
}
