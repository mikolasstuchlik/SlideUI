import SwiftUI

struct Plane: View {
    @EnvironmentObject var presentation: PresentationProperties

    var body: some View {
        ZStack {
            ForEach(presentation.backgrounds.indices) { content(for: presentation.backgrounds[$0]) }
            ForEach(presentation.slides.indices) { content(for: presentation.slides[$0]) }
        }
        .frame(
            width: presentation.screenSize.width,
            height: presentation.screenSize.height
        )
    }

    private func content(for background: any Background.Type) -> some View {
        AnyView(
            background.init()
        )
        .frame(
            width: presentation.screenSize.width * background.relativeSize.width,
            height: presentation.screenSize.height * background.relativeSize.height
        )
        .scaleEffect(background.scale)
        .offset(
            x: presentation.screenSize.width * background.offset.dx,
            y: presentation.screenSize.height * background.offset.dy
        )
    }

    private func content(for slide: any Slide.Type) -> AnyView {
        AnyView(
            slide.init()
                .frame(
                    width: presentation.frameSize.width,
                    height: presentation.frameSize.height
                )
                .offset(
                    x: presentation.screenSize.width * slide.offset.dx,
                    y: presentation.screenSize.height * slide.offset.dy
                )
                .disabled(presentation.mode == .editor)
        )
    }
}

