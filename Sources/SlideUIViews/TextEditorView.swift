import SwiftUI
import CodeEditor

/// `TextEditorView` wraps Swift Package `CodeEditor` and provides file write/load functionality. It allows you to
/// present and edit code and save it to a file.
public struct TextEditorView: View {

    /// - Parameters:
    ///   - axis: Whether editor and controls should be arranged horizontally or vertically
    ///   - filePath: Path of the file for loading and saving
    ///   - format: Format for syntax higliting
    ///   - content: Content of the editor
    public init(filePath: String, format: Binding<CodeEditor.Language>, axis: TextEditorView.Axis = .vertical, content: Binding<String>) {
        self.axis = axis
        self.filePath = filePath
        self._format = format
        self._content = content
    }

    public enum Axis {
        case horizontal, vertical
    }

    /// Describes, whether the buttons and editor should be arranged horizontally or vertically
    public let axis: Axis

    /// Path for saving and loading the content of the editor
    public let filePath: String

    /// Langauge for syntax highliting. Swift has custom behavior.
    @Binding public var format: CodeEditor.Language

    /// Text, that is displayed inside of the editor
    @Binding public var content: String

    /// Whether last saving operation was a success (default false)
    @State public var saveError: Bool = false

    /// Whether last loading operation was a success (default false)
    @State public var loadError: Bool = false

    @ViewBuilder public var body: some View {
        OutlineView(title: filePath) {
            if axis == .vertical {
                VStack {
                    Editor(format: $format, content: $content)
                    HStack(spacing: 32) { Controls(filePath: filePath, format: $format, content: $content, saveError: $saveError, loadError: $loadError) }
                }
            } else {
                HStack {
                    Editor(format: $format, content: $content)
                    VStack(spacing: 32) { Controls(filePath: filePath, format: $format, content: $content, saveError: $saveError, loadError: $loadError) }
                }
            }
        }
    }

    private struct Editor: View {
        @Binding public var format: CodeEditor.Language
        @Binding public var content: String

        var body: some View {
            if format == .swift {
                CodeEditor(
                    source: $content,
                    language: format,
                    theme: format == .swift
                        ? CodeEditor.ThemeName(rawValue: "xcode")
                        : .default,
                    fontSize: .constant(Font.presentationEditorFontSize),
                    indentStyle: .softTab(width: 2)
                ).colorScheme(.light)
            } else {
                CodeEditor(
                    source: $content,
                    language: format,
                    theme: format == .swift
                        ? CodeEditor.ThemeName(rawValue: "xcode")
                        : .default,
                    fontSize: .constant(Font.presentationEditorFontSize),
                    indentStyle: .softTab(width: 2)
                )
            }
        }
    }

    private struct Controls: View {
        let filePath: String
        @Binding var format: CodeEditor.Language
        @Binding var content: String
        @Binding var saveError: Bool
        @Binding var loadError: Bool

        var body: some View {
            Button {
                do  {
                    content = try String(contentsOfFile: filePath)
                    loadError = false
                } catch {
                    loadError = true
                }
            } label: {
                if loadError {
                    Text("Načti").foregroundColor(.red)
                } else {
                    Text("Načti")
                }
            }
            Button {
                do {
                    try content.write(toFile: filePath, atomically: true, encoding: .utf8)
                    saveError = false
                } catch {
                    saveError = true
                }
            } label: {
                if saveError {
                    Text("Ulož").foregroundColor(.red)
                } else {
                    Text("Ulož")
                }
            }
            Menu(format.rawValue) {
                ForEach(CodeEditor.Language.knownCases.indices) { index in
                    Button(CodeEditor.Language.knownCases[index].rawValue) {
                        format = CodeEditor.Language.knownCases[index]
                    }
                }
            }.frame(width: 100)
        }
    }

}

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(
            filePath: "~/nothing.txt",
            format: .constant(.c),
            content: .constant(
"""
#include <stdlib.h>
#include <stdio.h>

int main(void) {
    printf("Ahoj %s", "Miki");
    return 0;
}
"""
            )
        )
    }
}
