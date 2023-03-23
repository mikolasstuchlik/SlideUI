import SwiftUI
import CodeEditor

/// `TextEditorView` wraps Swift Package `CodeEditor` and provides file write/load functionality. It allows you to
/// present and edit code and save it to a file.
public struct TextEditorView: View {

    public enum Axis {
        case horizontal, vertical
    }

    public final class Model: ObservableObject {
        /// Langauge for syntax highliting. Swift has custom behavior.
        @Published public var format: CodeEditor.Language

        /// Text, that is displayed inside of the editor
        @Published public var content: String

        /// Whether last saving operation was a success (default false)
        @Published public private(set) var saveError: Bool = false

        /// Whether last loading operation was a success (default false)
        @Published public private(set) var loadError: Bool = false

        /// Path for saving and loading the content of the editor
        public let filePath: String

        public init(filePath: String, format: CodeEditor.Language, content: String) {
            self.filePath = filePath
            self.format = format
            self.content = content
        }

        public func save() {
            do {
                try content.write(toFile: filePath, atomically: true, encoding: .utf8)
                saveError = false
            } catch {
                saveError = true
            }
        }

        public func load() {
            do  {
                content = try String(contentsOfFile: filePath)
                loadError = false
            } catch {
                loadError = true
            }
        }
    }

    /// - Parameters:
    ///   - axis: Whether editor and controls should be arranged horizontally or vertically
    ///   - filePath: Path of the file for loading and saving
    ///   - format: Format for syntax higliting
    ///   - content: Content of the editor
    public init(model: Model, axis: TextEditorView.Axis = .vertical) {
        self.axis = axis
        self.model = model
    }

    @ObservedObject var model: Model

    /// Describes, whether the buttons and editor should be arranged horizontally or vertically
    public let axis: Axis


    @ViewBuilder public var body: some View {
        OutlineView(title: model.filePath) {
            if axis == .vertical {
                VStack {
                    Editor(format: $model.format, content: $model.content)
                    HStack(spacing: 32) { Controls(model: model) }
                }
            } else {
                HStack {
                    Editor(format: $model.format, content: $model.content)
                    VStack(spacing: 32) { Controls(model: model) }
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
        @ObservedObject var model: Model

        var body: some View {
            Button {
                model.load()
            } label: {
                if model.loadError {
                    Text("Načti").foregroundColor(.red)
                } else {
                    Text("Načti")
                }
            }
            Button {
                model.save()
            } label: {
                if model.saveError {
                    Text("Ulož").foregroundColor(.red)
                } else {
                    Text("Ulož")
                }
            }
            Menu(model.format.rawValue) {
                ForEach(CodeEditor.Language.knownCases.indices) { index in
                    Button(CodeEditor.Language.knownCases[index].rawValue) {
                        model.format = CodeEditor.Language.knownCases[index]
                    }
                }
            }.frame(width: 100)
        }
    }

}

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(model: TextEditorView.Model(
            filePath: "~/nothing.txt",
            format: .c,
            content:
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
