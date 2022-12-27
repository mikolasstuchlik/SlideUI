import SwiftUI
import CodeEditor

public struct TextEditorView: View {
    public init(axis: TextEditorView.Axis, filePath: String, format: Binding<CodeEditor.Language>, content: Binding<String>) {
        self.axis = axis
        self.filePath = filePath
        self._format = format
        self._content = content
    }

    public enum Axis {
        case horizontal, vertical
    }

    public let axis: Axis
    public let filePath: String
    @Binding public var format: CodeEditor.Language
    @Binding public var content: String
    @State public var saveError: Bool = false
    @State public var loadError: Bool = false
    
    @ViewBuilder public var body: some View {
        OutlineView(title: filePath) {
            if axis == .vertical {
                VStack {
                    viewContent
                    HStack(spacing: 32) { controls }
                }
            } else {
                HStack {
                    viewContent
                    VStack(spacing: 32) { controls }
                }
            }
        }
    }
    
    @ViewBuilder private var viewContent: some View {
        editor
    }
    
    @ViewBuilder private var editor: some View {
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
    
    @ViewBuilder private var controls: some View {
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

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(
            axis: .vertical,
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
