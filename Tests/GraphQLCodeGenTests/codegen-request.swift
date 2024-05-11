import XCTest
@testable import GraphQLCodeGen
import GraphQLParser
import SwiftSyntax

class CodeGenRequestTests: XCTestCase {
    func testRequst() async throws {
        try await codegenEqual(
            """
            query ExampleQuery($code: String!) {
              countries(filter: { code: { eq: $code } }) {
                code
              }
            }
            """,
            """
            public struct ExampleQueryRequest: Codable {
                public let code: String
            }
            """
        )
    }
    
    
    private func codegenEqual(_ query: String, _ result: String) async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let parser = try await GraphQLParser()
        let document = try await parser.parse(source: query)
        let ctx = Context(schema: schema, document: document)
        let operation = document.definitions
            .flatMap { a in
                if case let .executable(e) = a {
                    return [e]
                }
                return []
            }
            .flatMap { a in
                if case let .operation(o) = a {
                    return [o]
                }
                return []
            }.first!
        let generated = try generateRequestForOperationDefinitionNode(ctx: ctx, operation: operation)!.formatted().description
        XCTAssertEqual(
            generated,
            result
        )
    }
}
