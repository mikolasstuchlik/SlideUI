import SwiftUI
import CodeEditor

public struct TerminalView: View {
    public enum Axis {
        case horizontal, vertical
    }
    
    public enum State {
        case idle, loading, result(Result<String?, Error>)
    }
    
    public let axis: Axis
    public let workingPath: URL
    public let aspectRatio: CGFloat
    @Binding public var stdIn: String
    @Binding public var state: State
    
    public var body: some View {
        OutlineView(title: "zsh in:\(workingPath.path) %") {
            elements
        }
    }
    
    @ViewBuilder private var elements: some View {
        HStack {
            GeometryReader { proxy in
                VStack(spacing: 4.0) {
                    let baseHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom - (axis == .vertical ? 58 : 4)
                    inputView.frame(
                        height: baseHeight * aspectRatio
                    )
                    if axis == .vertical {
                        buttonView
                    }
                    resultView.frame(
                        height: baseHeight * (1.0 - aspectRatio)
                    )
                }
            }
            if axis == .horizontal {
                buttonView
            }
        }
    }
    
    @ViewBuilder private var inputView: some View {
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
        }
    }
    
    @ViewBuilder private var resultView: some View {
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
                if #available(macOS 13.0, *) {
                    Text(stdout ?? "(Empty)")
                        .monospaced()
                        .font(.presentationEditorFont)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                } else {
                    Text(stdout ?? "(Empty)")
                        .font(.presentationEditorFont)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                }
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
        }
    }
    
    @ViewBuilder private var buttonView: some View {
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

struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalView(axis: .vertical, workingPath: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0], aspectRatio: 0.25, stdIn: .constant(""), state: .constant(.idle))
    }
}
