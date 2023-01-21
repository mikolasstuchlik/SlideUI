import Darwin
import Foundation
import CodeEditor
import SwiftUI
import SlideUI

public final class RuntimeViewProvider {
    public enum Error: Swift.Error {
        case failedToOpenSymbol
    }

    private typealias FunctionPrototype = @convention(c) () -> Any

    public static let defaultCommand = "swiftc -parse-as-library -emit-library %file%"
    
    public let rootViewName: String
    public let workingURL = FileManager.default.temporaryDirectory
    public let workingPath = FileManager.default.temporaryDirectory.path

    private let symbolName = "loadViewFunc"
    private lazy var fileTemplate: String =
"""
import SwiftUI

@_cdecl("\(symbolName)")
public func \(symbolName)() -> Any {
    return AnyView(\(rootViewName).init())
}


"""

    private var sourceFileName: String { rootViewName + ".swift" }
    private var sourceFilePath: String { workingPath + "/" + sourceFileName}
    private var libraryPath: String { workingPath + "/" + "lib" + rootViewName + ".dylib"}

    private var existingHandle: UnsafeMutableRawPointer?

    public init(rootViewName: String) {
        self.rootViewName = rootViewName
    }

    public func compileAndLoad(code: String, command: String = RuntimeViewProvider.defaultCommand) throws -> AnyView {
        dispose()
        try writeFile(code: code)

        let filledCommand = command.replacingOccurrences(of: "%file%", with: sourceFileName)
        
        _ = try Process.executeAndWait(
            "zsh",
            arguments: ["-c", filledCommand],
            workingDir: workingURL
        )

        try deleteSourceFile()

        let handle = dlopen(libraryPath, RTLD_NOW)!
        existingHandle = handle

        guard let symbol = dlsym(handle, symbolName) else {
            throw Error.failedToOpenSymbol
        }

        let callable = unsafeBitCast(symbol, to: FunctionPrototype.self)

        return callable() as! AnyView
    }

    private func writeFile(code: String) throws {
        let file = fileTemplate + code
        try file.write(toFile: sourceFilePath, atomically: true, encoding: .utf8)
    }

    private func deleteSourceFile() throws {
        try FileManager.default.removeItem(atPath: sourceFilePath)
    }

    private func dispose() {
        _ = existingHandle.flatMap(dlclose(_:))
        existingHandle = nil
        try? FileManager.default.removeItem(atPath: libraryPath)
    }

    deinit { dispose() }
}

public struct CompilerView: View {
    public init(axis: CompilerView.Axis, uniqueName: String, code: Binding<String>, state: Binding<CompilerView.State>, buildCommand: Binding<String>, editBuildCommand: Bool = false) {
        self.axis = axis
        self.uniqueName = uniqueName
        self._code = code
        self._state = state
        self._buildCommand = buildCommand
        self.editBuildCommand = editBuildCommand
    }

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
    
    public enum Axis {
        case horizontal, vertical
    }
    
    public enum State {
        case idle, loading, exception(Error), view(AnyView)
    }
    
    public let axis: Axis
    public let uniqueName: String
    @Binding public var code: String
    @Binding public var state: State
    @Binding public var buildCommand: String
    @SwiftUI.State public var editBuildCommand: Bool = false
    
    public var body: some View {
        OutlineView(title: "SwiftUI View: \(uniqueName)") {
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
                source: $code,
                language: .swift,
                theme: CodeEditor.ThemeName(rawValue: "xcode"),
                fontSize: .constant(Font.presentationEditorFontSize),
                indentStyle: .softTab(width: 2)
            ).colorScheme(.light)
            if editBuildCommand {
                TextEditor(text: $buildCommand)
                    .frame(height: 50)
            }
        }
        if case .loading = state {
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
            state = .loading
            Task {
                do {
                    state = .view(try Providers[uniqueName].compileAndLoad(code: code, command: buildCommand))
                } catch {
                    state = .exception(error)
                }
            }
        } label: {
            Image(systemName: "play.circle.fill")
                .resizable()
                .foregroundStyle(.primary, .secondary, .green)
        }
        .frame(width: 50, height: 50)
        .buttonStyle(.plain)
        Button {
            editBuildCommand.toggle()
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
        CompilerView(axis: .vertical, uniqueName: "preview", code: .constant(""), state: .constant(.idle), buildCommand: .constant("xyz"))
    }
}
