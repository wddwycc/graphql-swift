import Foundation
public struct ContinentFilterInput: Codable {
    public var code: StringQueryOperatorInput?
}
public struct CountryFilterInput: Codable {
    public var code: StringQueryOperatorInput?
    public var continent: StringQueryOperatorInput?
    public var currency: StringQueryOperatorInput?
    public var name: StringQueryOperatorInput?
}
public struct LanguageFilterInput: Codable {
    public var code: StringQueryOperatorInput?
}
public struct StringQueryOperatorInput: Codable {
    public var eq: String?
    public var `in`: [String]?
    public var ne: String?
    public var nin: [String]?
    public var regex: String?
}
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
}
public struct IntrospectionQueryResponse: Codable {
    public let __schema: __Schema?
    public struct __Schema: Codable {
        public let description: String?
        /// The type that query operations will be rooted at.
        public let queryType: __Type
        public struct __Type: Codable {
            public let name: String?
        }
        /// If this server supports mutation, the type that mutation operations will be rooted at.
        public let mutationType: __Type?
        /// If this server support subscription, the type that subscription operations will be rooted at.
        public let subscriptionType: __Type?
        /// A list of all types supported by this server.
        public let types: [__Type]
        /// A list of all directives supported by this server.
        public let directives: [__Directive]
        public struct __Directive: Codable {
            public let name: String
            public let description: String?
            public let isRepeatable: Bool
            public let locations: [__DirectiveLocation]
            public let args: [__InputValue]
            public struct __InputValue: Codable {
                public let name: String
                public let description: String?
                public let type: __Type
                public struct __Type: Codable {
                    public let kind: __TypeKind
                    public let name: String?
                    public let ofType: __Type?
                    public struct __Type: Codable {
                        public let kind: __TypeKind
                        public let name: String?
                        public let ofType: __Type?
                        public struct __Type: Codable {
                            public let kind: __TypeKind
                            public let name: String?
                            public let ofType: __Type?
                            public struct __Type: Codable {
                                public let kind: __TypeKind
                                public let name: String?
                                public let ofType: __Type?
                                public struct __Type: Codable {
                                    public let kind: __TypeKind
                                    public let name: String?
                                    public let ofType: __Type?
                                    public struct __Type: Codable {
                                        public let kind: __TypeKind
                                        public let name: String?
                                        public let ofType: __Type?
                                        public struct __Type: Codable {
                                            public let kind: __TypeKind
                                            public let name: String?
                                            public let ofType: __Type?
                                            public struct __Type: Codable {
                                                public let kind: __TypeKind
                                                public let name: String?
                                                public let ofType: __Type?
                                                public struct __Type: Codable {
                                                    public let kind: __TypeKind
                                                    public let name: String?
                                                    public let ofType: __Type?
                                                    public struct __Type: Codable {
                                                        public let kind: __TypeKind
                                                        public let name: String?
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                /// A GraphQL-formatted string representing the default value for this input value.
                public let defaultValue: String?
                public let isDeprecated: Bool
                public let deprecationReason: String?
            }
        }
    }
}
public struct AllCountriesResponse: Codable {
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
public struct CountriesByCodeRequest: Codable {
    public var code: String
}
public struct CountriesByCodeResponse: Codable {
    public let countries: [Country]
    public struct Country: Codable {
        public let code: String
    }
}
public struct CountriesByRequest: Codable {
    public var filter: CountryFilterInput
}
public struct CountriesByResponse: Codable {
    public let countries: [Country]
    public struct Country: Codable {
        public let code: String
    }
}
public struct GraphQLRequestSimplePayload: Codable {
    public let query: String
}
public struct GraphQLRequestPayload<T: Codable>: Codable {
    public let query: String
    public let variables: T
}
public struct GraphQLResponsePayload<T: Codable>: Codable {
    public let data: T
}
public class GraphQLClient {
    private let url: URL = URL(string: "https://countries.trevorblades.com")!
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()
    private var requestInterceptor: ((inout URLRequest) -> Void)?
    /// Set custom request interceptor, the given closure would run before every request is sent. Most common use case is add authentication header
    public func setRequestInterceptor(_ interceptor: @escaping (inout URLRequest) -> Void) {
        self.requestInterceptor = interceptor
    }
    public init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    private func sendRequest<RequestPayload: Codable, ResponsePayload: Codable>(payload: RequestPayload) async throws -> ResponsePayload {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        requestInterceptor?(&request)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try jsonDecoder.decode(GraphQLResponsePayload<ResponsePayload> .self, from: data).data
    }
    public func introspectionQuery() async throws -> IntrospectionQueryResponse {
        let query = "query IntrospectionQuery {\n  __schema {\n    description\n    queryType { name }\n    mutationType { name }\n    subscriptionType { name }\n    types {\n      ...FullType\n    }\n    directives {\n      name\n      description\n      isRepeatable\n      locations\n      args(includeDeprecated: true) {\n        ...InputValue\n      }\n    }\n  }\n}"
        let payload = GraphQLRequestSimplePayload(query: query)
        return try await sendRequest(payload: payload)
    }
    public func allCountries() async throws -> AllCountriesResponse {
        let query = "query AllCountries {\n  countries {\n    code\n    name\n    currency\n    emoji\n    states {\n        name\n    }\n  }\n}"
        let payload = GraphQLRequestSimplePayload(query: query)
        return try await sendRequest(payload: payload)
    }
    public func countriesByCode(variables: CountriesByCodeRequest) async throws -> CountriesByCodeResponse {
        let query = "query CountriesByCode($code: String!) {\n  countries(filter: { code: { eq: $code } }) {\n    code\n  }\n}"
        let payload = GraphQLRequestPayload<CountriesByCodeRequest>(query: query, variables: variables)
        return try await sendRequest(payload: payload)
    }
    public func countriesBy(variables: CountriesByRequest) async throws -> CountriesByResponse {
        let query = "query CountriesBy($filter: CountryFilterInput!) {\n  countries(filter: $filter) {\n    code\n  }\n}"
        let payload = GraphQLRequestPayload<CountriesByRequest>(query: query, variables: variables)
        return try await sendRequest(payload: payload)
    }
}
