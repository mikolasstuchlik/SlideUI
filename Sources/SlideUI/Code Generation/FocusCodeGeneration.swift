import Foundation
import RegexBuilder

final class FocusCodeManipulator {
    enum Error: Swift.Error {
        case fileNotFound
    }

    static let indent = Reference(Substring.self)
    static let startName = Reference(Substring.self)
    static let endName = Reference(Substring.self)
    static let content = Reference(Substring.self)
    static let hintRegex = {
        return Regex {
            Capture(as: indent) {
                ZeroOrMore(.horizontalWhitespace)
            }
            "// @hint("
            Capture(as: startName) {
                ZeroOrMore(.word)
            }
            "){"
            One(.verticalWhitespace)
            Capture(as: content) {
                ZeroOrMore(.any)
            }
            One(.verticalWhitespace)
            ZeroOrMore(.horizontalWhitespace)
            "// }@hint("
            Capture(as: endName) {
                ZeroOrMore(.word)
            }
            ")"
        }
    }()

    static let focusRegex = {
        return Regex {
            Capture(as: indent) {
                ZeroOrMore(.horizontalWhitespace)
            }
            "// @focuses("
            Capture(as: startName) {
                ZeroOrMore(.word)
            }
            "){"
            One(.verticalWhitespace)
            Capture(as: content) {
                ZeroOrMore(.any)
            }
            One(.verticalWhitespace)
            ZeroOrMore(.horizontalWhitespace)
            "// }@focuses("
            Capture(as: endName) {
                ZeroOrMore(.word)
            }
            ")"
        }
    }()

    let rootPath: String
    let knownSlides: [any Slide.Type]
    let knownFocuses: [Focus]

    init(rootPath: String, knowSlides: [any Slide.Type], knownFocuses: [Focus]) {
        self.rootPath = rootPath
        self.knownSlides = knowSlides
        self.knownFocuses = knownFocuses
    }

    func saveUpdatesToSourceCode() -> [String: Result<Void, Swift.Error>] {
        let hints = loadFilePathsForHints()
        let focuses = loadFilePathsForFocuses()

        var result = [String: Result<Void, Swift.Error>]()
        for slide in knownSlides {
            result[slide.name] = Result {
                guard let file = hints[slide.name] else {
                    throw Error.fileNotFound
                }

                try store(slide: slide, at: file)
            }
        }

        result["%focuses%"] = Result {
            guard let file = focuses.values.first else {
                throw Error.fileNotFound
            }

            try storeFocuses(at: file)
        }

        return result
    }

    private func store(slide: any Slide.Type, at file: String) throws {
        var content = try String(contentsOfFile: rootPath + "/" + file, encoding: .utf8)
        let regexResult = try FocusCodeManipulator.hintRegex.firstMatch(in: content)!
        let indentation = "\(regexResult[FocusCodeManipulator.indent])"
        let hintContent = regexResult[FocusCodeManipulator.content].range

        let output =
#"""
\#(indentation)static var hint: String? =
"""

"""#
        +
        (slide.hint.flatMap {$0 + "\n" } ?? "")
        +
#"""
"""
"""#
        content.replaceSubrange(hintContent, with: output)

        try content.write(toFile: rootPath + "/" + file, atomically: true, encoding: .utf8)
    }

    private func storeFocuses(at file: String) throws {
        var content = try String(contentsOfFile: rootPath + "/" + file, encoding: .utf8)
        let regexResult = try FocusCodeManipulator.focusRegex.firstMatch(in: content)!
        let indentation = "\(regexResult[FocusCodeManipulator.indent])"
        let focusesContent = regexResult[FocusCodeManipulator.content].range

        func focusArrayContent() -> String {
            var acumulator: [String] = []
            for (index, focus) in knownFocuses.enumerated() {
                var line = ""

                line += "Focus(kind: "

                switch focus.kind {
                case let .unbound(camera):
                    line += ".unbound(Camera(offset: CGVector(dx: \(camera.offset.dx), dy: \(camera.offset.dy)), scale: \(camera.scale)))"
                case let .specific(slides):
                    line += ".specific(["
                    line += slides.map { String(describing: $0.self) + ".self" }.joined(separator: ", ")
                    line += "])"
                }

                line += ", hint: generated_hint_\(index))"
                acumulator.append(line)
            }

            return acumulator.map { indentation + "    " + $0 }.joined(separator: ",\n")
        }

        func hintContent() -> String {
            var acumulator: [String] = []
            for (index, focus) in knownFocuses.enumerated() {
                let hintString =
#"""
\#(indentation)private let generated_hint_\#(index): String =
"""

"""#
    +
    (focus.hint.flatMap {$0 + "\n" } ?? "")
    +
#"""
"""
"""#
                acumulator.append(hintString)
            }

            return acumulator.joined(separator: "\n\n")
        }

        let output =
#"""
\#(indentation)private var focuses: [Focus] = [
\#(focusArrayContent())
]

\#(hintContent())

"""#

        content.replaceSubrange(focusesContent, with: output)

        try content.write(toFile: rootPath + "/" + file, atomically: true, encoding: .utf8)
    }

    private func loadFilePathsForHints() -> [String: String] {
        let enumerator = FileManager.default.enumerator(atPath: rootPath)

        var result = [String:String]()
        while let object = enumerator?.nextObject() as? String {
            guard object.hasSuffix(".swift"), let content = try? String(contentsOfFile: rootPath + "/" + object, encoding: .utf8) else {
                continue
            }
            if let regexResult = try? FocusCodeManipulator.hintRegex.firstMatch(in: content) {
                let startName = "\(regexResult[FocusCodeManipulator.startName])"
                let endName = "\(regexResult[FocusCodeManipulator.endName])"
                if startName == endName {
                    result[startName] = object
                }
            }
        }

        return result
    }

    private func loadFilePathsForFocuses() -> [String: String] {
        let enumerator = FileManager.default.enumerator(atPath: rootPath)

        var result = [String:String]()
        while let object = enumerator?.nextObject() as? String {
            guard object.hasSuffix(".swift"), let content = try? String(contentsOfFile: rootPath + "/" + object, encoding: .utf8) else {
                continue
            }
            if let regexResult = try? FocusCodeManipulator.focusRegex.firstMatch(in: content) {
                let startName = "\(regexResult[FocusCodeManipulator.startName])"
                let endName = "\(regexResult[FocusCodeManipulator.endName])"
                if startName == endName {
                    result[startName] = object
                }
            }
        }

        return result
    }

}
