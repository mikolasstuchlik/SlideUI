//
//  FontPicker.swift
//
//  Created by : Tomoaki Yagishita on 2021/01/09
//  © 2021  SmallDeskSoftware
//

import AppKit
import SwiftUI

public class FontPickerDelegate {
    public var parent: FontPicker

    public init(_ parent: FontPicker) {
        self.parent = parent
    }
    
    @objc
    public func changeFont(_ id: Any) {
        parent.fontSelected()
    }

}

public struct FontPicker: View {
    let labelString: String
    
    @Binding var font: NSFont
    @State var fontPickerDelegate: FontPickerDelegate? = nil
    
    public init(_ label: String, selection: Binding<NSFont>) {
        self.labelString = label
        self._font = selection
    }
    
    public var body: some View {
        HStack {
            Text(labelString)
            
            Button {
                if NSFontPanel.shared.isVisible {
                    NSFontPanel.shared.orderOut(nil)
                    return
                }
                
                self.fontPickerDelegate = FontPickerDelegate(self)
                NSFontManager.shared.target = self.fontPickerDelegate
                NSFontPanel.shared.setPanelFont(self.font, isMultiple: false)
                NSFontPanel.shared.orderBack(nil)
            } label: {
                Image(systemName: "textformat")
                    .resizable()
                    .scaledToFit()
                    .padding(2)
            }
        }
    }
    
    func fontSelected() {
        self.font = NSFontPanel.shared.convert(self.font)
    }
}

struct FontPicker_Previews: PreviewProvider {
    static var previews: some View {
        FontPicker("font", selection: .constant(NSFont.systemFont(ofSize: 24)))
    }
}
