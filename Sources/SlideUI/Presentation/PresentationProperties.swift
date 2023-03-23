import SwiftUI
import SlideUICommons

/// PresentationProperties is a class that contains the global state of the presentation.
/// It stores the slides, focuses, camera position, fonts and other properties, that apply globaly.
/// However, the state of individual views are managed by the SwiftUI itself.
public final class PresentationProperties: ObservableObject {

    /// Current User Interaction idiom of the Application
    public enum Mode: Int, Equatable {
        /// Presentation idiom is used, when presentation is being Presented
        case presentation
        /// Editor idiom is used, when the Presentation is open to modifications in Control Panel
        case editor
    }

    /// Static instance for usage in SwiftUI previews
    public static func preview() -> PresentationProperties {
        PresentationProperties(rootPath: "", slidesPath: "", backgrounds: [], slides: [], focuses: [])
    }

    /// Create the instance of PresentationProperties
    /// - Parameters:
    ///   - rootPath: The path to the root of the Application source code. It is used by the code generator.
    ///   - slidesPath: Path to the directory containing slides.
    ///   - backgrounds: Metatypes of all Backgrounds. Presentation may have 0 background. Background cannot be modified during runtime.
    ///   - slides: Metatypes of all slides. Presentation may have at least 1 slide. Slides cannot be modified during runtime.
    ///   - focuses: ORDERED array of all focuses. Presentation may have at least 1 Focus.
    public init(rootPath: String, slidesPath: String, backgrounds: [any Background.Type], slides: [any Slide.Type], focuses: [Focus]) {
        self.rootPath = rootPath
        self.slidesPath = slidesPath
        self.backgrounds = backgrounds
        self.slides = slides
        self.focuses = focuses
    }

    private var currentSlideStateUpdates: UInt = 0

    /// Currently selected focus.
    public var selectedFocus: Int = 0 {
        didSet {
            currentSlideStateUpdates = 0
            if let newConfiguration = getConfiguration(for: selectedFocus) {
                camera = newConfiguration.camera
                hint = newConfiguration.hint
            } else {
                hint = "Mimo plánovaný průchod"
            }
        }
    }

    /// Allows you to select a concrete slide.
    public func moveTo(slide: any Slide.Type) {
        camera = .init(offset: slide.offset, scale: slide.singleFocusScale)
        hint = slide.hint
    }

    func shouldProceedToNextFocus() -> Bool {
        guard
            focuses.indices.contains(selectedFocus),
            case let .specific(slides) = focuses[selectedFocus].kind,
            slides.count == 1,
            let slide = slides.first
        else {
            return true
        }

        defer { currentSlideStateUpdates += 1 }
        return !slide.captured(forwardEvent: currentSlideStateUpdates)
    }

    /// The path to the root of the Application source code. It is used by the code generator.
    public let rootPath: String
    /// Path to the directory containing slides.
    public let slidesPath: String
    /// Metatypes of all Backgrounds. Presentation may have 0 background. Background cannot be modified during runtime.
    public var backgrounds: [any Background.Type]
    /// Metatypes of all slides. Presentation may have at least 1 slide. Slides cannot be modified during runtime.
    public var slides: [any Slide.Type]
    /// ORDERED array of all focuses. Presentation may have at least 1 Focus. Focuses may be modified by Control Panel.
    @Published public var focuses: [Focus]

    /// Current user input idiom.
    @Published public var mode: Mode = .presentation
    /// Whether camera can move freely using the position of cursor and wheel.
    @Published public var enableDoubleClickFreeRoam: Bool = false
    /// Whether camera can move freely using the position of cursor and wheel.
    @Published public var cameraFreeRoam: Bool = false
    /// Slide, that is hovered during camera free roam.
    @Published public var hoveredSlide: (any Slide.Type)? = nil
    /// Color scheme of the presentation.
    @Published public var colorScheme: ColorScheme = ColorScheme.dark

    /// Scale size of a Slide frame depending on the window size.
    @Published public var automaticFameSize: Bool = true
    /// The size of a Slide frame.
    @Published public var frameSize: CGSize = CGSize(width: 1024, height: 768)

    /// Scale size of a screen depending on the window size.
    @Published public var automaticScreenSize: Bool = true
    /// Size of the screen.
    @Published public var screenSize: CGSize = CGSize(width: 1024, height: 768)

    /// Placeholder value, used to trigger refresh of thumbnails. (Thumbnails are used by the SwitchViews in order provide hint
    /// of the underlying content and save the resources.)
    @Published public var loadThumbnails: Bool = false

    /// Offset and scale of the Plane view - used to create a Cemare-like experience
    @Published public var camera: Camera = .init(offset: .zero, scale: 1.0)
    /// Hints displayed in the control panel.
    @Published public var hint: String? = nil

    /// Default font for Title styled text
    public static let defaultTitle = NSFont.systemFont(ofSize: 80, weight: .bold)
    /// Default font for Subtitle styled text
    public static let defaultSubTitle = NSFont.systemFont(ofSize: 70, weight: .regular)
    /// Default font for Headline styled text
    public static let defaultHeadline = NSFont.systemFont(ofSize: 50, weight: .bold)
    /// Default font for Subheadline styled text
    public static let defaultSubHeadline = NSFont.systemFont(ofSize: 40, weight: .regular)
    /// Default font for Body styled text
    public static let defaultBody = NSFont.systemFont(ofSize: 30)
    /// Default font for Note styled text
    public static let defaultNote = NSFont.systemFont(ofSize: 20, weight: .light)
    /// Default font size for Editor styled text (used in Text Editor view)
    public static let defaultEditorFont = NSFont.systemFont(ofSize: 25, weight: .regular)

    /// Current font used for Title styled text
    @Published public var title: NSFont = PresentationProperties.defaultTitle {
        willSet {
            Font.presentationTitle = Font(newValue as CTFont)
        }
    }

    /// Current font used for Subtitle styled text
    @Published public var subTitle: NSFont = PresentationProperties.defaultSubTitle  {
        willSet {
            Font.presentationSubTitle = Font(newValue as CTFont)
        }
    }

    /// Current font used for Headline styled text
    @Published public var headline: NSFont = PresentationProperties.defaultHeadline {
        willSet {
            Font.presentationHeadline = Font(newValue as CTFont)
        }
    }

    /// Current font used for Subheadline styled text
    @Published public var subHeadline: NSFont = PresentationProperties.defaultSubHeadline  {
        willSet {
            Font.presentationSubHeadline = Font(newValue as CTFont)
        }
    }

    /// Current font used for Body styled text
    @Published public var body: NSFont = PresentationProperties.defaultBody {
        willSet {
            Font.presentationBody = Font(newValue as CTFont)
        }
    }

    /// Current font used for Note styled text
    @Published public var note: NSFont = PresentationProperties.defaultNote  {
        willSet {
            Font.presentationNote = Font(newValue as CTFont)
        }
    }

    /// Current font size used for Text Editor view
    @Published public var codeEditorFontSize: CGFloat = 25 {
        willSet {
            Font.presentationEditorFont = Font.system(size: newValue)
            Font.presentationEditorFontSize = newValue
        }
    }

    private func getConfiguration(for newFocusIndex: Int) -> PresentableFocus? {
        guard
            newFocusIndex >= 0,
            newFocusIndex < focuses.count
        else {
            return nil
        }

        switch focuses[newFocusIndex].kind {
        case let .specific(slides) where slides.count == 1:
            var result = singleSlideFocus(for: slides.first!)
            let hint = result?.hint ?? ""
            result?.hint = (focuses[newFocusIndex].hint.flatMap { $0 + "\n\n--\n\n" } ?? "" ) + hint
            return result
        case let .specific(slides):
            var result = computeFocus(for: slides)
            let hint = result?.hint ?? ""
            result?.hint = (focuses[newFocusIndex].hint.flatMap { $0 + "\n\n--\n\n" } ?? "") + hint
            return result
        case let .unbound(camera):
            return .init(camera: camera, hint: focuses[newFocusIndex].hint)
        }
    }

    private func singleSlideFocus(for slide: any Slide.Type) -> PresentableFocus? {
        .init(camera: .init(offset: slide.offset, scale: slide.singleFocusScale), hint: slide.hint)
    }

    private func computeFocus(for slides: [any Slide.Type]) -> PresentableFocus? {
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

        let camera = Camera(offset: newOffset, scale: newScale - 0.01)
        return .init(camera: camera, hint: newHint)
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

