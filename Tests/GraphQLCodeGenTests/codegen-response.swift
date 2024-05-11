import XCTest
@testable import GraphQLCodeGen
import GraphQLParser
import SwiftSyntax

class CodeGenResponseTests: XCTestCase {
    func testResponse() async throws {
        try await codegenResponseEqual(
            """
            query ExampleQuery {
              countries {
                code
                name
                currency
                emoji
                states {
                    name
                }
              }
            }
            """,
            """
            public struct ExampleQueryResponse: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                    public let name: String
                    public let currency: String?
                    public let emoji: String
                    public let states: [State]
                    public struct State: Codable {
                        public let name: String
                    }
                }
            }
            """
        )
    }
    
    func testRequestPayload() async throws {
        // TODO
    }
    
    func testTwoQueries() async throws {
        try await codegenResponseEqual(
            """
            query ExampleQuery {
              countries {
                code
              }
            }
            query ExampleQuery2 {
              countries {
                code
              }
            }
            """,
            """
            public struct ExampleQueryResponse: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                }
            }
            public struct ExampleQuery2Response: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                }
            }
            """
        )

    }
    
    func testResponseWithFragmentSpread() async throws {
        try await codegenResponseEqual(
            """
            query ExampleQuery {
              countries {
                ...CountryProps
              }
            }
            fragment CountryProps on Country {
                code
                name
                currency
                emoji
                states {
                    name
                }
            }
            """,
            """
            public struct ExampleQueryResponse: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                    public let name: String
                    public let currency: String?
                    public let emoji: String
                    public let states: [State]
                    public struct State: Codable {
                        public let name: String
                    }
                }
            }
            """
        )
    }
    
    func testResponseWithInlineFragment() async throws {
        try await codegenResponseEqual(
            """
            query ExampleQuery {
              countries {
                ... on Country {
                    code
                    name
                    currency
                    emoji
                    states {
                        name
                    }
                }
              }
            }

            fragment CountryProps on Country {
                code
                name
                currency
                emoji
                states {
                name
                }
            }
            """,
            """
            public struct ExampleQueryResponse: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                    public let name: String
                    public let currency: String?
                    public let emoji: String
                    public let states: [State]
                    public struct State: Codable {
                        public let name: String
                    }
                }
            }
            """
        )
    }
    
    func testResponseWithDuplicatedFields() async throws {
        try await codegenResponseEqual(
            """
            query ExampleQuery {
              countries {
                code
                name
                ...CountryProps
                ...CountryProps
              }
            }
            
            fragment CountryProps on Country {
                code
                name
                currency
                emoji
                states {
                    name
                }
            }
            """,
            """
            public struct ExampleQueryResponse: Codable {
                public let countries: [Country]
                public struct Country: Codable {
                    public let code: String
                    public let name: String
                    public let currency: String?
                    public let emoji: String
                    public let states: [State]
                    public struct State: Codable {
                        public let name: String
                    }
                }
            }
            """
        )
    }
    
    func testIntrospectionQuery() async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let query = getIntrospectionQuery()
        let result = try await generate(
            schema: schema,
            query: query
        )
        print(result)
    }
    
    private func codegenResponseEqual(_ query: String, _ result: String) async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let parser = try await GraphQLParser()
        let document = try await parser.parse(source: query)
        let ctx = Context(schema: schema, document: document)
        let operations = document.definitions
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
            }
        let structDecls: [StructDeclSyntax] = try operations.map {
            try generateResponseModelForOperationDefinitionNode(ctx: ctx, operation: $0)
        }
        let source = SourceFileSyntax {
            for structDecl in structDecls { structDecl }
        }
        XCTAssertEqual(
            source.formatted().description,
            result
        )
    }
}
