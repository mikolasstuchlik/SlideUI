import Darwin
import Foundation
import SwiftUI

/// `RuntimeViewProvider` allows you to compile a SwiftUI View and load it as an instance of AnyView at runtime.
///
/// Notice, that both `Hardened Runtime` and `Application Sandbox` needs to be turned off in order for this
/// feature to work, otherwise the provider crashes the app.
///
/// Provider takes a Swift code as an input and adds a prefix which contains a C-compatible API. The it compiles
/// the code via direct call to the Swift compiler and produces `.dylib`. The `.dylib` is then loaded by the presentation
/// via call to `dlopen`, symbol is resolved via `dlsym` and executed.
public final class RuntimeViewProvider {
    public enum Error: Swift.Error {
        case failedToLoadLibrary
        case failedToOpenSymbol
        /// Library was loaded and symbol was found, but the result of the call to the symbol filed to produce correct result. If you see this error, the memory of this program may already be corrupt.
        case abiMismatch
    }

    /// Function declaration, that was emmited to the library. Notice, that the function has all the Swift calling conventions.
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

        guard let handle = dlopen(libraryPath, RTLD_NOW) else {
            throw Error.failedToLoadLibrary
        }
        existingHandle = handle

        guard let symbol = dlsym(handle, symbolName) else {
            throw Error.failedToOpenSymbol
        }

        let callable = unsafeBitCast(symbol, to: FunctionPrototype.self)
        guard let result = callable() as? AnyView else {
            assertionFailure("Result of call to the symbol of runtime-compiler library failed to cast properly. At this point, the program runtime may be corrupt!")
            throw Error.abiMismatch
        }

        return result
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
