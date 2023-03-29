import CodeEditor
import SwiftUI
import SlideUI

/// This class is just a wrapper for already resolved views
private final class Providers {
    private static var providers: [String: RuntimeViewProvider] = [:]

    static func provider(for name: String) -> RuntimeViewProvider {
        if let provider = providers[name] {
            return provider
        }

        let provider = RuntimeViewProvider(rootViewName: name)
        providers[name] = provider
        return provider
    }

    static subscript(_ name: String) -> RuntimeViewProvider {
        return provider(for: name)
    }

    private init () {}
}

/// Compiler view is an editor with internal logic, that allows you to compile and "plug in" a SwiftUI view into the
/// view hiearachy of this presentation at runtime.
///
/// The view itself only contains the editor and some accesory, the compiled view is exposed via the `state` property.
///
/// The Compiler view uses `Process` in order to invoke `swiftc`. The code entered into the editor provided by
/// Compiler view is appended after the following code:
/// ```
/// import SwiftUI
///
/// @_cdecl("\(symbolName)")
/// public func \(symbolName)() -> Any {
///     return AnyView(\(rootViewName).init())
/// }
/// ```
/// The `symbolName` is private to the `RuntimeViewProvider` which handles the compilation, while
/// `rootViewName` is equal to the `uniqueName` provided to the Compiler view.
///
/// The top-level SwiftUI view you define must have the `uniqueName`.
///
/// - Warning: The resulting code is compiler into a `.dylib` and loaded via `ldopen` and `dlsym`.
/// Therefore, aby crash in the code will crash the whole presentation. Notice, that sandbox and other binary
/// protection musts be switched off.
public struct CompilerView: View {

    public enum Axis {
        case horizontal, vertical
    }

    public enum State {
        case idle, loading, exception(Error), view(AnyView)
    }

    public final class Model: ObservableObject {

        /// The name of the UIView in your code - must be globally unique
        public let uniqueName: String

        /// The code to compile
        @Published public var code: String

        /// Use this binding to observe the sate of the view - in case of success, the reference to compiled view will be present there
        @Published public var state: State

        /// The build command used during the code compilation. Use the `%file%` delimiter in order to reference to the file for compilation. Do not change the destination.
        @Published public var buildCommand: String

        /// Set to `true` if you want to present the input for build command modification
        @Published public var editBuildCommand: Bool = false

        public init(uniqueName: String, code: String, state: CompilerView.State = .idle, buildCommand: String = RuntimeViewProvider.defaultCommand, editBuildCommand: Bool = false) {
            self.uniqueName = uniqueName
            self.code = code
            self.state = state
            self.buildCommand = buildCommand
            self.editBuildCommand = editBuildCommand
        }

        public func execute() {
            state = .loading
            Task { @MainActor in
                do {
                    state = .view(try Providers[uniqueName].compileAndLoad(code: code, command: buildCommand))
                } catch {
                    state = .exception(error)
                }
            }
        }
    }


    /// Constructs an editor and infrastructure that allows you, to enter, compile and execute a SwiftUI code
    /// during the runtime of the presentation.
    /// - Parameters:
    ///   - uniqueName: The name of the UIView in your code - must be globally unique
    ///   - code: The code to compile
    ///   - state: Use this binding to observe the sate of the view - in case of success, the reference to compiled view will be present there
    ///   - buildCommand: The build command used during the code compilation. Use the `%file%` delimiter in order to reference to the file for compilation. Do not change the destination.
    ///   - editBuildCommand: Set to `true` if you want to present the input for build command modification
    ///   - axis: Whether elements should be organized horizontally or vertically
    public init(model: Model, axis: CompilerView.Axis = .vertical) {
        self.axis = axis
        self.model = model
    }

    /// Whether elements should be organized horizontally or vertially
    public let axis: Axis

    @ObservedObject var model: Model

    public var body: some View {
        OutlineView(title: "SwiftUI View: \(model.uniqueName)") {
            if axis == .horizontal {
                HStack { elements }
            } else {
                VStack { elements }
            }
        }
    }
    
    @ViewBuilder private var elements: some View {
        VStack {
            CodeEditor(
                source: $model.code,
                language: .swift,
                theme: CodeEditor.ThemeName(rawValue: "xcode"),
                fontSize: .constant(Font.presentationEditorFontSize),
                indentStyle: .softTab(width: 2)
            ).colorScheme(.light)
            if model.editBuildCommand {
                TextEditor(text: $model.buildCommand)
                    .frame(height: 50)
            }
        }
        if case .loading = model.state {
            ProgressView()
                .frame(width: 50, height: 50)
        } else {
            if axis == .vertical {
                HStack { buttons }
            } else {
                VStack { buttons }
            }
        }
    }
    
    @ViewBuilder private var buttons: some View {
        Button {
            model.execute()
        } label: {
            Image(systemName: "play.circle.fill")
                .resizable()
                .foregroundStyle(.primary, .secondary, .green)
        }
        .frame(width: 50, height: 50)
        .buttonStyle(.plain)
        Button {
            model.editBuildCommand.toggle()
        } label: {
            Image(systemName: "terminal.fill")
                .resizable()
        }
        .frame(width: 25, height: 25, alignment: .bottomTrailing)
        .buttonStyle(.plain)
    }
}

struct CompilerView_Previews: PreviewProvider {
    static var previews: some View {
        CompilerView(model: CompilerView.Model(
            uniqueName: "preview",
            code: "",
            state: .idle,
            buildCommand: "xyz"
        ))
    }
}
