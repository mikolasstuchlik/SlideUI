import SwiftUI
import SlideUICommons

public final class PresentationProperties: ObservableObject {
    public enum Mode: Int, Equatable {
        case presentation, editor
    }

    public static func preview() -> PresentationProperties {
        PresentationProperties(rootPath: "", slidesPath: "", backgrounds: [], slides: [], focuses: [])
    }

    public init(rootPath: String, slidesPath: String, backgrounds: [any Background.Type], slides: [any Slide.Type], focuses: [Focus]) {
        self.rootPath = rootPath
        self.slidesPath = slidesPath
        self.backgrounds = backgrounds
        self.slides = slides
        self.focuses = focuses
    }

    public var selectedFocus: Int = 0 {
        didSet {
            guard let newConfiguration = getConfiguration(for: selectedFocus) else {
                return
            }
            camera = .init(offset: newConfiguration.offset, scale: newConfiguration.scale)
        }
    }

    public func moveTo(slide: any Slide.Type) {
        camera = .init(offset: slide.offset, scale: slide.singleFocusScale)
    }

    public let rootPath: String
    public let slidesPath: String
    public var backgrounds: [any Background.Type]
    public var slides: [any Slide.Type]
    @Published public var focuses: [Focus]

    @Published public var mode: Mode = .presentation
    @Published public var cameraFreeRoam: Bool = false
    @Published public var hoveredSlide: (any Slide.Type)? = nil
    @Published public var colorScheme: ColorScheme = ColorScheme.dark

    @Published public var automaticFameSize: Bool = true
    @Published public var frameSize: CGSize = CGSize(width: 1024, height: 768)

    @Published public var automaticScreenSize: Bool = true
    @Published public var screenSize: CGSize = CGSize(width: 1024, height: 768)

    @Published public var loadThumbnails: Bool = false

    @Published public var camera: Camera = .init(offset: .zero, scale: 1.0)

    public static let defaultTitle = NSFont.systemFont(ofSize: 80, weight: .bold)
    public static let defaultSubTitle = NSFont.systemFont(ofSize: 70, weight: .regular)
    public static let defaultHeadline = NSFont.systemFont(ofSize: 50, weight: .bold)
    public static let defaultSubHeadline = NSFont.systemFont(ofSize: 40, weight: .regular)
    public static let defaultBody = NSFont.systemFont(ofSize: 30)
    public static let defaultNote = NSFont.systemFont(ofSize: 20, weight: .light)
    public static let defaultEditorFont = NSFont.systemFont(ofSize: 25, weight: .regular)

    @Published public var title: NSFont = PresentationProperties.defaultTitle {
        willSet {
            Font.presentationTitle = Font(newValue as CTFont)
        }
    }

    @Published public var subTitle: NSFont = PresentationProperties.defaultSubTitle  {
        willSet {
            Font.presentationSubTitle = Font(newValue as CTFont)
        }
    }

    @Published public var headline: NSFont = PresentationProperties.defaultHeadline {
        willSet {
            Font.presentationHeadline = Font(newValue as CTFont)
        }
    }

    @Published public var subHeadline: NSFont = PresentationProperties.defaultSubHeadline  {
        willSet {
            Font.presentationSubHeadline = Font(newValue as CTFont)
        }
    }

    @Published public var body: NSFont = PresentationProperties.defaultBody {
        willSet {
            Font.presentationBody = Font(newValue as CTFont)
        }
    }

    @Published public var note: NSFont = PresentationProperties.defaultNote  {
        willSet {
            Font.presentationNote = Font(newValue as CTFont)
        }
    }

    @Published public var codeEditorFontSize: CGFloat = 25 {
        willSet {
            Font.presentationEditorFont = Font.system(size: newValue)
            Font.presentationEditorFontSize = newValue
        }
    }

    private func getConfiguration(for newFocusIndex: Int) -> Focus.Properties? {
        guard
            newFocusIndex >= 0,
            newFocusIndex < focuses.count
        else {
            return nil
        }

        switch focuses[newFocusIndex] {
        case let .slides(slides) where slides.count == 1:
            return singleSlideFocus(for: slides.first!)
        case let .slides(slides):
            return computeFocus(for: slides)
        case let .properties(properties):
            return properties
        }
    }

    private func singleSlideFocus(for slide: any Slide.Type) -> Focus.Properties {
        .init(offset: slide.offset, scale: slide.singleFocusScale, hint: slide.hint)
    }

    private func computeFocus(for slides: [any Slide.Type]) -> Focus.Properties? {
        guard !slides.isEmpty else { return nil }

        var minXOffset = slides.first!.offset.dx
        var minYOffset = slides.first!.offset.dy
        var maxXOffset = slides.first!.offset.dx
        var maxYOffset = slides.first!.offset.dy

        for slide in slides {
            minXOffset = min(minXOffset, slide.offset.dx)
            minYOffset = min(minYOffset, slide.offset.dy)
            maxXOffset = max(maxXOffset, slide.offset.dx)
            maxYOffset = max(maxYOffset, slide.offset.dy)
        }

        let width = 1 / (minXOffset.distance(to: maxXOffset) + 1)
        let height = 1 / (minYOffset.distance(to: maxYOffset) + 1)

        let newScale = min(width, height)

        let newOffset = CGVector(
            dx: (minXOffset + minXOffset.distance(to: maxXOffset) / 2),
            dy: (minYOffset + minYOffset.distance(to: maxYOffset) / 2)
        )

        let newHint = slides
            .compactMap { slide in slide.hint.flatMap { "**\(slide.name):**\n" + $0 } }
            .joined(separator: "\n\n--\n\n")

        return .init(offset: newOffset, scale: newScale - 0.01, hint: newHint)
    }

}

public extension Font {
    static fileprivate(set) var presentationTitle: Font = { Font(PresentationProperties.defaultTitle as CTFont) }()
    static fileprivate(set) var presentationSubTitle: Font = { Font(PresentationProperties.defaultSubTitle as CTFont) }()
    static fileprivate(set) var presentationHeadline: Font = { Font(PresentationProperties.defaultHeadline as CTFont) }()
    static fileprivate(set) var presentationSubHeadline: Font = { Font(PresentationProperties.defaultSubHeadline as CTFont) }()
    static fileprivate(set) var presentationBody: Font = { Font(PresentationProperties.defaultBody as CTFont) }()
    static fileprivate(set) var presentationNote: Font = { Font(PresentationProperties.defaultNote as CTFont) }()
    static fileprivate(set) var presentationEditorFont: Font = { Font(PresentationProperties.defaultEditorFont as CTFont) }()
    static fileprivate(set) var presentationEditorFontSize: CGFloat = { PresentationProperties.defaultEditorFont.pointSize }()
}

extension PresentationProperties {
    func offset(for position: NSPoint, in window: CGSize) -> CGVector {
        CGVector(
            dx: (position.x - window.width / 2) / window.width / camera.scale,
            dy: (position.y - window.height / 2) / window.height / camera.scale
        ).invertedDY()
    }

    func absoluteToOffset(size: CGSize) -> CGSize {
        CGSize(
            width: size.width / screenSize.width,
            height: size.height / screenSize.height
        )
    }

    func getOffsetRect(of slide: any Slide.Type) -> CGRect {
        let offset = slide.offset
        let offsetSize = absoluteToOffset(size: frameSize)
        return CGRect(
            origin: CGPoint(
                x: offset.dx - offsetSize.width / 2,
                y: offset.dy - offsetSize.height / 2
            ),
            size: offsetSize
        )
    }

}

