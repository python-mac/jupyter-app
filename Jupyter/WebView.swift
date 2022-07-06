import SwiftUI
import WebKit

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}

class WebViewController: NSViewController, WKUIDelegate {
    var webView = WKWebView()
    
    public func load(_ url: String) {
        webView.load(url)
    }

    override func loadView() {
        webView.uiDelegate = self
        view = webView
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if let url = navigationAction.request.url?.absoluteString {
            if url != "" {
                NSWorkspace.shared.open(URL(string: "jupyter-app:" + url)!)
            }
        }
        
        return nil
    }
}

struct WebView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = WebViewController
    
    var url: String
    var controller = WebViewController()
    
    func makeNSViewController(context: Context) -> WebViewController {
        controller.load(url)
        return controller
    }
    
    func updateNSViewController(_: WebViewController, context: Context) {}
}
