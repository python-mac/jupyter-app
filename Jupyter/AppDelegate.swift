import Cocoa
import SwiftUI

var jupyter: Jupyter?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // I don't like it, but I didn't find anything better
    var windows: [NSWindow] = []
    
    @IBAction func newBrowserWindow(_ sender: NSMenuItem) {
        if let jupyter = jupyter {
            launchBrowserWindow(with: jupyter.url())
        }
    }

    func applicationDidFinishLaunching(_: Notification) {
        
        // check commandline
        for argument in CommandLine.arguments {
            if argument.starts(with: "--link=") {
                let file = argument.get(after: "--link=")
                
                if let url = try? Jupyter.getURL(from: file) {
                    jupyter = Jupyter(fromURL: url)
                    
                    NSWorkspace.shared.open(URL(string: "jupyter-app:" + url.get(until: "?token="))!)
                }
            }
        }
        
        // launch jupyter ourselves
        while jupyter == nil {
            do { jupyter = try Jupyter() }
            catch {
                if !display(error, text: "Retry launching jupyter notebook?") {
                    exit(1)
                }
            }
        }
        
        // if there are no open windows I want to open a browser
        // so I call applicationShouldHandleReopen
        openApp()
    }

    func applicationWillTerminate(_: Notification) {
        jupyter = nil
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows, let jupyter = jupyter {
            launchBrowserWindow(with: jupyter.url())
        }
        
        return true
    }
    
    func application(_ app: NSApplication, open urls: [URL]) {
        
        for recievedURL in urls {
            let url = recievedURL.absoluteString.get(after: "jupyter-app:")
            
            if url.hasSuffix(".ipynb") {
                // I haven't found another way to open a new document
                let fileURL = "file://" + Jupyter.root + url.get(after: "notebooks")
                openApp(with: [fileURL])
                
            } else if url.contains("/tree") {
                launchBrowserWindow(with: url)

            } else {
                // try to launch in other app
                if let extrernalURL = URL(string: url) {
                    NSWorkspace.shared.open(extrernalURL)
                }
            }
        }
    }
    
    func launchBrowserWindow(with url: String = "") {
        let contentView = WebView(url: url)
            .frame(minWidth: 900, minHeight: 600)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        
        window.title = "Browser"
        
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        
        window.setFrameAutosaveName("Browser")
        window.makeKeyAndOrderFront(nil)
        
        windows.append(window)
    }
    
    func openApp(with files: [String] = []) {
        // there is probably a better way to do it
        let task = Process()
        
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", Bundle.main.bundlePath] + files
        
        task.launch()
    }
}

func display(_ error: Error, text: String) -> Bool {
    let alert = NSAlert()
    
    alert.messageText = error.localizedDescription
    alert.informativeText = text
    alert.alertStyle = .warning
    
    alert.addButton(withTitle: "Yes")
    alert.addButton(withTitle: "No")
    
    let response = alert.runModal()
    return response == .alertFirstButtonReturn
}
