#error("Add Swift Package https://github.com/mikolasstuchlik/SlideUI.git")

import SwiftUI
import SlideUI

private let backgrounds: [any Background.Type] = [
    ABackground.self,
]

private let slides: [any Slide.Type] = [
    TitleSlide.self,
]

// @focuses(focuses){
private var focuses: [Focus] = [
    Focus(kind: .specific([TitleSlide.self])),
    Focus(kind: .unbound(Camera(offset: CGVector(dx: 0.0, dy: 0.0), scale: 0.2225)))
]
// }@focuses(focuses)

private let presentation = PresentationProperties(
    rootPath: Array(String(#file).components(separatedBy: "/").dropLast()).joined(separator: "/"),
    slidesPath: Array(String(#file).components(separatedBy: "/").dropLast()).joined(separator: "/") + "/Slides",
    backgrounds: backgrounds,
    slides: slides,
    focuses: focuses
)

@main
struct ___PACKAGENAME:identifier___App: App {
    var body: some Scene {
        WindowGroup("Toolbar") {
            SlideControlPanel().environmentObject(presentation)
        }

        Window("Slides", id: "slides") {
            Presentation(environment: presentation).environmentObject(presentation)
        }
    }
}
