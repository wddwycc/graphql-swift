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
                public var code: String
            }
            """
        )
    }
    
    func testRequestWithOptionalRequest() async throws {
        try await codegenEqual(
            """
            query ExampleQuery($code: String) {
              countries(filter: { code: { eq: $code } }) {
                code
              }
            }
            """,
            """
            public struct ExampleQueryRequest: Codable {
                public var code: String?
            }
            """
        )
    }
    
    func testRquestWithOptionalName() async throws {
        try await codegenEqual(
            """
            query ExampleQuery($filter: CountryFilterInput!) {
              countries(filter: $filter) {
                code
              }
            }
            """,
            """
            public struct ExampleQueryRequest: Codable {
                public var filter: CountryFilterInput
            }
            """
        )
    }
    
    private func codegenEqual(_ query: String, _ result: String) async throws {
        let schema = getSchema()
        let parser = try await GraphQLParser()
        let document = try await parser.parse(source: query)
        let ctx = Context(schema: schema, document: document, rawDocument: query)
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
        let generated = try generateRequestModelForOperationDefinitionNode(ctx: ctx, operation: operation)!.formatted().description
        XCTAssertEqual(
            generated,
            result
        )
    }
}
