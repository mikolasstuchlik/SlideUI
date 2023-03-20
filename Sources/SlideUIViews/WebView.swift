import WebKit
import SwiftUI

/// `WebView` is a SwiftUI wrapper for `WKWebView`. It only accepts one URL during initialization.
public struct WebView: NSViewRepresentable {

    /// - Parameter url: URL of an WWW web page.
    public init(url: URL) {
        self.url = url
    }

    public var url: URL

    public static func dismantleNSView(_ nsView: WKWebView, coordinator: Self.Coordinator) {
        nsView.load(URLRequest(url: URL(string:"about:blank")!))
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    public func updateNSView(_ webView: WKWebView, context: Context) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
