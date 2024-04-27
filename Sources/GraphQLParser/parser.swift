import WebKit

@MainActor
public class GraphQLParser {
    private let webview = WKWebView()
    
    public init() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(), Error>) in
            DispatchQueue.main.async {
                let jsUrl = Bundle.module.url(forResource: "graphql", withExtension: "js")!
                guard let jsContent = try? String(contentsOf: jsUrl) else {
                    continuation.resume(throwing: GraphQLParserErrors.failedToLoadJSScript)
                    return
                }
                self.webview.evaluateJavaScript(jsContent) { res, err in
                    if let err {
                        continuation.resume(throwing: GraphQLParserErrors.failedToLoadJSScriptInWebView(err))
                        return
                    }
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    public func parse(source: String) async throws -> DocumentNode {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let source = source.replacingOccurrences(of: "`", with: "\\`")
                self.webview.evaluateJavaScript("window.__GRAPHQL__.parse(`\(source)`)") { res, err in
                    if let err {
                        continuation.resume(throwing: err)
                        return
                    }
                    guard let res = res as? String else {
                        continuation.resume(throwing: GraphQLParserErrors.invalidASTString)
                        return
                    }
                    guard let data = res.data(using: .utf8), let node = try? JSONDecoder().decode(DocumentNode.self, from: data) else {
                        continuation.resume(throwing: GraphQLParserErrors.invalidASTJSON)
                        return
                    }
                    continuation.resume(returning: node)
                }
            }
        }
    }
}

public enum GraphQLParserErrors: Error {
    case failedToLoadJSScript
    case failedToLoadJSScriptInWebView(Error)
    case invalidASTString
    case invalidASTJSON
}
