import SwiftUI
import WebKit

/// Renders full HTML email bodies, replacing Android's `HtmlText` (a TextView with
/// `Html.fromHtml`). A `WKWebView` handles rich markup/CSS/images; text color adapts to
/// light/dark via `prefers-color-scheme`.
struct HTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrapped(html), baseURL: nil)
    }

    private func wrapped(_ body: String) -> String {
        """
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: -apple-system, sans-serif; font-size: 15px; color: #000;
                 margin: 0; padding: 0; word-wrap: break-word; }
          img { max-width: 100%; height: auto; }
          a { color: #1C7DDD; }
          @media (prefers-color-scheme: dark) { body { color: #FFF; } }
        </style>
        </head><body>\(body)</body></html>
        """
    }
}

extension String {
    /// Lightweight HTML → plain text for list previews (Android shows the body inline in
    /// the inbox item). Cheaper than `NSAttributedString` HTML parsing per row.
    var strippedHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
