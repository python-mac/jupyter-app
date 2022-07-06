import Cocoa
import SwiftUI

class Document: NSDocument, ObservableObject {

    override class var autosavesInPlace: Bool {
        return false
    }
    
    override var isDocumentEdited: Bool {
        // prevents checking at the end
        // (which is pointless, because jupyter handles it)
        return false
    }
    
    override var keepBackupFile: Bool {
        return false
    }

    override func makeWindowControllers() {
        
        if let path = self.fileURL?.path, let jupyter = jupyter {
            
            let url = jupyter.url(for: path)

            let contentView = WebView(url: url)
                .frame(minWidth: 900, minHeight: 600)
            
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            
            window.setFrameAutosaveName("Document")
            
            let windowController = NSWindowController(window: window)
            self.addWindowController(windowController)
        }
    }

    override func read(from data: Data, ofType typeName: String) throws {}
}
