import WebKit

@MainActor
class GraphQLParser {
    private let webview = WKWebView()
    
    init() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let jsUrl = Bundle.module.url(forResource: "graphql", withExtension: "js")!
                let jsContent = try! String(contentsOf: jsUrl)
                self.webview.evaluateJavaScript(jsContent) { res, err in
                    if let err {
                        fatalError(err.localizedDescription)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    public func parse(source: String) async -> Any {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let source = source.replacingOccurrences(of: "`", with: "\\`")
                self.webview.evaluateJavaScript("window.__GRAPHQL__.parse(`\(source)`)") { res, err in
                    if let err {
                        fatalError(err.localizedDescription)
                    }
                    guard let res else {
                        fatalError("Cannot retrieve parsed GraphQL AST")
                    }
                    continuation.resume(returning: res)
                }
            }
        }
    }
}
