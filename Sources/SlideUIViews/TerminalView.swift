import SwiftUI
import CodeEditor

/// `TerminalView` allows you to execute non-interactive CLI programs. It contains a text view from `CodeEditor` Swift Package
/// for entry and displays the result in non-interactive view.
///
/// On background it uses provided extension on `Process` to execute `zsh` commands in working directory specified in construcor.
public struct TerminalView: View {

    public enum Axis {
        case horizontal, vertical
    }

    public enum State {
        case idle, loading, result(Result<String?, Error>)
    }

    public final class Model: ObservableObject {

        /// String containing current value passed to zsh
        @Published public var stdIn: String

        /// State of the execution
        @Published public var state: State

        /// Working directory for each executed command
        public let workingPath: URL

        public init(workingPath: URL, stdIn: String, state: State = .idle) {
            self.stdIn = stdIn
            self.state = state
            self.workingPath = workingPath
        }

        public func execute() {
            state = .loading
            Task { @MainActor in
                state = .result(Result {
                    try Process.executeAndWait("zsh", arguments: ["-c", stdIn], workingDir: workingPath)
                })
            }
        }
    }

    /// - Parameters:
    ///   - axis: Whether elements should be organized horizontally or vertically
    ///   - workingPath: Working directory for each executed command
    ///   - aspectRatio:Value 0...1 which determines what portion of the view is taken by the entry field
    ///   - stdIn: String containing stdin
    ///   - state: State of the execution
    public init(model: Model, aspectRatio: CGFloat = 0.75, axis: TerminalView.Axis = .vertical) {
        self.axis = axis
        self.aspectRatio = aspectRatio
        self.model = model
    }

    /// Whether elements should be organized horizontally or vertially
    public let axis: Axis

    /// Value 0...1 which determines what portion of the view is taken by the entry field
    public let aspectRatio: CGFloat

    @ObservedObject var model: Model

    public var body: some View {
        OutlineView(title: "zsh in:\(model.workingPath.path) %") {
            HStack {
                GeometryReader { proxy in
                    VStack(spacing: 4.0) {
                        let baseHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - (axis == .vertical ? 58 : 4)
                        VStack(spacing: 0) {
                            Text("stdin:")
                                .foregroundColor(.gray)
                                .font(.system(.footnote))
                                .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                            CodeEditor(
                                source: $model.stdIn,
                                language: .bash,
                                fontSize: .constant(Font.presentationEditorFontSize),
                                indentStyle: .softTab(width: 2),
                                autoscroll: false
                            )
                        }.frame(
                            height: baseHeight * aspectRatio
                        )
                        if axis == .vertical {
                            ButtonView(model: model)
                        }
                        ScrollView {
                            switch model.state {
                            case .idle, .loading:
                                Text("stdout:")
                                    .foregroundColor(.gray)
                                    .font(.system(.footnote))
                                    .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                                Text("")
                                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            case let .result(.success(stdout)):
                                Text("stdout:")
                                    .foregroundColor(.gray)
                                    .font(.system(.footnote))
                                    .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                                Text(stdout ?? "(Empty)")
                                    .monospaced()
                                    .font(.presentationEditorFont)
                                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            case let .result(.failure(ProcessError.endedWith(code: code, error: stderr))):
                                Text("Status: \(code)  stderr:")
                                    .foregroundColor(.gray)
                                    .font(.system(.footnote))
                                    .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                                Text(stderr ?? "(Empty)")
                                    .font(.presentationEditorFont)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            case let .result(.failure(unknownError)):
                                Text("Chyba:")
                                    .foregroundColor(.gray)
                                    .font(.system(.footnote))
                                    .frame(maxWidth: .infinity, maxHeight: 12, alignment: .leading)
                                Text(unknownError.localizedDescription)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                            }
                        }.frame(
                            height: baseHeight * (1.0 - aspectRatio)
                        )
                    }
                }
                if axis == .horizontal {
                    ButtonView(model: model)
                }
            }
        }
    }

    private struct ButtonView: View {
        @ObservedObject var model: Model

        var body: some View {
            if case .loading = model.state {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Button {
                    model.execute()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .foregroundStyle(.primary, .secondary, .green)
                }
                .frame(width: 50, height: 50)
                .buttonStyle(.plain)
            }
        }
    }
}

struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalView(
            model: TerminalView.Model(
                workingPath: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0],
                stdIn: "",
                state: .idle
            ),
            aspectRatio: 0.25,
            axis: .vertical
        )
    }
}
