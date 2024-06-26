import XCTest
@testable import GraphQLCodeGen
import GraphQLParser
import SwiftSyntax

class CodeGenResponseTests: XCTestCase {
    func testResponse() async throws {
        try await codegenEqual(
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
                    /**
                    country currency.
                    for example, dollar for the US
                    */
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
    
    func testResponseWithFragmentSpread() async throws {
        try await codegenEqual(
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
                    /**
                    country currency.
                    for example, dollar for the US
                    */
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
        try await codegenEqual(
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
                    /**
                    country currency.
                    for example, dollar for the US
                    */
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
        try await codegenEqual(
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
                    /**
                    country currency.
                    for example, dollar for the US
                    */
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
    
    private func codegenEqual(_ query: String, _ result: String) async throws {
        let schema = getSchema()
        let parser = try await GraphQLParser()
        let document = try await parser.parse(source: query)
        let ctx = Context(serverUrl: "https://countries.trevorblades.com", schema: schema, documents: [document], rawDocuments: [query])
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
        let generated = try generateResponseModelForOperationDefinitionNode(ctx: ctx, operation: operation).formatted().description
        XCTAssertEqual(
            generated,
            result
        )
    }
}
