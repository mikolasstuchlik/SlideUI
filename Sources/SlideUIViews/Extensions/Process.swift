import Foundation

public enum ProcessError: Error {
    case endedWith(code: Int, error: String?)
    case couldNotBeSpawned
    case programNotFound
}

private extension ProcessInfo {
    var environmentPaths: [String]? {
        environment["PATH"].flatMap { $0.split(separator: ":", omittingEmptySubsequences: true) }?.map(String.init)
    }
}

private extension Pipe {
    var stringContents: String? {
        String(
            data: self.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func urlForExecutable(named executable: String, in path: [String]) -> URL? {
    path.map {
        URL(fileURLWithPath: $0).appendingPathComponent(executable, isDirectory: false)
    }.first { file in
        var directory = ObjCBool(false)
        return  FileManager.default.fileExists(atPath: file.path, isDirectory: &directory)
                && !directory.boolValue
            && FileManager.default.isExecutableFile(atPath: file.path)
    }
}

private func createProcess(
    command: String,
    in path: [String] = ProcessInfo.processInfo.environmentPaths ?? [],
    arguments: [String] = [],
    workingDir: URL? = nil,
    standardInput: Any,
    standardOutput: Any,
    standardError: Any,
    fallbackToEnv: Bool
) throws -> Process {
    let process = Process()
    var arguments = arguments

    guard
        let url = urlForExecutable(named: command, in: path) ?? {
           arguments.insert(command, at: 0)
               return fallbackToEnv
               ? urlForExecutable(named: "env", in: path)
                         : nil
          }()
    else { throw ProcessError.programNotFound }

    if !arguments.isEmpty {
        process.arguments = arguments
    }

    workingDir.flatMap { process.currentDirectoryURL = $0 }
    process.standardInput = standardInput
    process.standardOutput = standardOutput
    process.standardError = standardError
    process.executableURL = url

    return process
}

public extension Process {
    /// Executes desired program and
    /// - Parameters:
    ///   - program: The name of the program
    ///   - arguments: List of arguments
    /// - Throws: Throws in case, that the process could not be executed or returned non-zero code.
    /// - Returns: The contents of std-out
    static func executeAndWait(_ program: String, arguments: [String], fallbackToEnv: Bool = false, workingDir: URL? = nil) throws -> String? {
        let outPipe = Pipe()
        let inPipe = Pipe()
        let errorPipe = Pipe()
        let process = try createProcess(
            command: program,
            arguments: arguments,
            workingDir: workingDir,
            standardInput: inPipe,
            standardOutput: outPipe,
            standardError: errorPipe,
            fallbackToEnv: fallbackToEnv
        )

        if #available(macOS 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ProcessError.endedWith(code: Int(process.terminationStatus), error: errorPipe.stringContents)
        }

        return outPipe.stringContents
    }
}
