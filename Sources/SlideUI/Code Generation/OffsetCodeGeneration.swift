import Foundation
import RegexBuilder

final class OffsetCodeManipulator {
    enum Error: Swift.Error {
        case fileNotFound
    }

    static let xReference = Reference(Substring.self)
    static let yReference = Reference(Substring.self)
    static let nameReference = Reference(Substring.self)
    static let regex = {
        let real = Regex {
            Optionally { "-" }
            OneOrMore(.digit)
            Optionally {
                "."
                OneOrMore(.digit)
            }
        }

        return Regex {
            "// @offset("
            Capture(as: nameReference) {
                ZeroOrMore(.word)
            }
            ")"
            ZeroOrMore(.horizontalWhitespace)
            One(.verticalWhitespace)
            ZeroOrMore(.horizontalWhitespace)
            "static"
            ZeroOrMore(.horizontalWhitespace)
            "var"
            ZeroOrMore(.horizontalWhitespace)
            "offset"
            ZeroOrMore(.horizontalWhitespace)
            "="
            ZeroOrMore(.horizontalWhitespace)
            "CGVector("
            ZeroOrMore(.horizontalWhitespace)
            "dx:"
            ZeroOrMore(.horizontalWhitespace)
            Capture(as: xReference) {
                real
            }
            ZeroOrMore(.horizontalWhitespace)
            ","
            ZeroOrMore(.horizontalWhitespace)
            "dy:"
            ZeroOrMore(.horizontalWhitespace)
            Capture(as: yReference) {
                real
            }
            ZeroOrMore(.horizontalWhitespace)
            ")"
        }
    }()

    let slidesPath: String
    let knownSlides: [any Slide.Type]

    init(slidesPath: String, knowSlides: [any Slide.Type]) {
        self.slidesPath = slidesPath
        self.knownSlides = knowSlides
    }

    func saveUpdatesToSourceCode() -> [String: Result<Void, Swift.Error>] {
        let names = loadFilePathsForNames()

        var result = [String: Result<Void, Swift.Error>]()
        for slide in knownSlides {
            result[slide.name] = Result {
                guard let file = names[slide.name] else {
                    throw Error.fileNotFound
                }

                var content = try String(contentsOfFile: slidesPath + "/" + file, encoding: .utf8)
                if let regexResult = try OffsetCodeManipulator.regex.firstMatch(in: content) {
                    content.replaceSubrange(regexResult[OffsetCodeManipulator.yReference].range, with: "\(slide.offset.dy)")
                    content.replaceSubrange(regexResult[OffsetCodeManipulator.xReference].range, with: "\(slide.offset.dx)")
                }

                try content.write(toFile: slidesPath + "/" + file, atomically: true, encoding: .utf8)

                return ()
            }
        }
        return result
    }

    private func loadFilePathsForNames() -> [String: String] {
        let enumerator = FileManager.default.enumerator(atPath: slidesPath)

        var result = [String:String]()
        while let object = enumerator?.nextObject() as? String {
            guard object.hasSuffix(".swift"), let content = try? String(contentsOfFile: slidesPath + "/" + object, encoding: .utf8) else {
                continue
            }
            if let regexResult = try? OffsetCodeManipulator.regex.firstMatch(in: content) {
                let name = "\(regexResult[OffsetCodeManipulator.nameReference])"
                result[name] = object
            }
        }

        return result
    }

}
