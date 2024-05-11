import XCTest
@testable import GraphQLCodeGen

class CodeGenTests: XCTestCase {
    func testResponse() async throws {
        try await codegenAssertEqual(
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
    
    func testTwoQueries() async throws {
        try await codegenAssertEqual(
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
        try await codegenAssertEqual(
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
        try await codegenAssertEqual(
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
        try await codegenAssertEqual(
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
    
    private func codegenAssertEqual(_ query: String, _ result: String) async throws {
        let schema = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
        let generated = try await generate(
            schema: schema,
            query: query
        )
        let enumDecls = 
        """
        public enum __DirectiveLocation: String, Codable {
            /// Location adjacent to a query operation.
            case QUERY
            /// Location adjacent to a mutation operation.
            case MUTATION
            /// Location adjacent to a subscription operation.
            case SUBSCRIPTION
            /// Location adjacent to a field.
            case FIELD
            /// Location adjacent to a fragment definition.
            case FRAGMENT_DEFINITION
            /// Location adjacent to a fragment spread.
            case FRAGMENT_SPREAD
            /// Location adjacent to an inline fragment.
            case INLINE_FRAGMENT
            /// Location adjacent to a variable definition.
            case VARIABLE_DEFINITION
            /// Location adjacent to a schema definition.
            case SCHEMA
            /// Location adjacent to a scalar definition.
            case SCALAR
            /// Location adjacent to an object type definition.
            case OBJECT
            /// Location adjacent to a field definition.
            case FIELD_DEFINITION
            /// Location adjacent to an argument definition.
            case ARGUMENT_DEFINITION
            /// Location adjacent to an interface definition.
            case INTERFACE
            /// Location adjacent to a union definition.
            case UNION
            /// Location adjacent to an enum definition.
            case ENUM
            /// Location adjacent to an enum value definition.
            case ENUM_VALUE
            /// Location adjacent to an input object type definition.
            case INPUT_OBJECT
            /// Location adjacent to an input object field definition.
            case INPUT_FIELD_DEFINITION
        }
        public enum __TypeKind: String, Codable {
            /// Indicates this type is a scalar.
            case SCALAR
            /// Indicates this type is an object. `fields` and `interfaces` are valid fields.
            case OBJECT
            /// Indicates this type is an interface. `fields`, `interfaces`, and `possibleTypes` are valid fields.
            case INTERFACE
            /// Indicates this type is a union. `possibleTypes` is a valid field.
            case UNION
            /// Indicates this type is an enum. `enumValues` is a valid field.
            case ENUM
            /// Indicates this type is an input object. `inputFields` is a valid field.
            case INPUT_OBJECT
            /// Indicates this type is a list. `ofType` is a valid field.
            case LIST
            /// Indicates this type is a non-null. `ofType` is a valid field.
            case NON_NULL
        }\n
        """
        XCTAssertEqual(
            generated,
            enumDecls + result
        )

    }
}
