import XCTest
@testable import GraphQLCodeGen

class CodeGenTests: XCTestCase {
    func testResponse() async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let query =
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
        """
        let result = try await generate(
            schema: schema,
            query: query
        )
        XCTAssertEqual(
            result,
            """
            struct ExampleQueryResponse {
                let countries: [Country]
                struct Country {
                    let code: String
                    let name: String
                    let currency: String?
                    let emoji: String
                    let states: [State]
                    struct State {
                        let name: String
                    }
                }
            }
            """
        )
    }
    
    func testResponseWithFragmentSpread() async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let query =
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
        """
        let result = try await generate(
            schema: schema,
            query: query
        )
        XCTAssertEqual(
            result,
            """
            struct ExampleQueryResponse {
                let countries: [Country]
                struct Country {
                    let code: String
                    let name: String
                    let currency: String?
                    let emoji: String
                    let states: [State]
                    struct State {
                        let name: String
                    }
                }
            }
            """
        )
    }
    
    func testResponseWithInlineFragment() async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let query =
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
        """
        let result = try await generate(
            schema: schema,
            query: query
        )
        XCTAssertEqual(
            result,
            """
            struct ExampleQueryResponse {
                let countries: [Country]
                struct Country {
                    let code: String
                    let name: String
                    let currency: String?
                    let emoji: String
                    let states: [State]
                    struct State {
                        let name: String
                    }
                }
            }
            """
        )
    }
}
