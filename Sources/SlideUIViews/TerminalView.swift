import SwiftUI
import CodeEditor

/// `TerminalView` allows you to execute non-interactive CLI programs. It contains a text view from `CodeEditor` Swift Package
/// for entry and displays the result in non-interactive view.
///
/// On background it uses provided extension on `Process` to execute `zsh` commands in working directory specified in construcor.
public struct TerminalView: View {

    /// - Parameters:
    ///   - axis: Whether elements should be organized horizontally or vertically
    ///   - workingPath: Working directory for each executed command
    ///   - aspectRatio:Value 0...1 which determines what portion of the view is taken by the entry field
    ///   - stdIn: String containing stdin
    ///   - state: State of the execution
    public init(workingPath: URL, stdIn: Binding<String>, state: Binding<TerminalView.State>, aspectRatio: CGFloat = 0.75, axis: TerminalView.Axis = .vertical) {
        self.axis = axis
        self.workingPath = workingPath
        self.aspectRatio = aspectRatio
        self._stdIn = stdIn
        self._state = state
    }

    public enum Axis {
        case horizontal, vertical
    }

    public enum State {
        case idle, loading, result(Result<String?, Error>)
    }

    /// Whether elements should be organized horizontally or vertially
    public let axis: Axis

    /// Working directory for each executed command
    public let workingPath: URL

    /// Value 0...1 which determines what portion of the view is taken by the entry field
    public let aspectRatio: CGFloat

    /// String containing current value passed to zsh
    @Binding public var stdIn: String

    /// State of the execution
    @Binding public var state: State
    
    public var body: some View {
        OutlineView(title: "zsh in:\(workingPath.path) %") {
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
                                source: $stdIn,
                                language: .bash,
                                fontSize: .constant(Font.presentationEditorFontSize),
                                indentStyle: .softTab(width: 2),
                                autoscroll: false
                            )
                        }.frame(
                            height: baseHeight * aspectRatio
                        )
                        if axis == .vertical {
                            ButtonView(workingPath: workingPath, stdIn: $stdIn, state: $state)
                        }
                        ScrollView {
                            switch state {
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
                    ButtonView(workingPath: workingPath, stdIn: $stdIn, state: $state)
                }
            }
        }
    }

    private struct ButtonView: View {
        public let workingPath: URL
        @Binding public var stdIn: String
        @Binding public var state: State

        var body: some View {
            if case .loading = state {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Button {
                    state = .loading
                    Task {
                        state = .result(Result {
                            try Process.executeAndWait("zsh", arguments: ["-c", stdIn], workingDir: workingPath)
                        })
                    }
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
        TerminalView(workingPath: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0], stdIn: .constant(""), state: .constant(.idle), aspectRatio: 0.25, axis: .vertical)
    }
}
