import Foundation

// reference: https://github.com/graphql/graphql-js/blob/v16.8.1/src/utilities/getIntrospectionQuery.ts#L41
public func getIntrospectionQuery() -> String {
    // NOTE: For introspection query: queryType, mutationType, subscriptionType only needs name field, here we use `...FullType` because of the model
    // TODO: After we turn introspective query into a codegen-ed module, replace ...FullType to name
    return """
    query IntrospectionQuery {
      __schema {
        description
        queryType { ...FullType }
        mutationType { ...FullType }
        subscriptionType { ...FullType }
        types {
          ...FullType
        }
        directives {
          name
          description
          isRepeatable
          locations
          args(includeDeprecated: true) {
            ...InputValue
          }
        }
      }
    }

    fragment FullType on __Type {
      kind
      name
      description
      specifiedByURL
      fields(includeDeprecated: true) {
        name
        description
        args(includeDeprecated: true) {
          ...InputValue
        }
        type {
          ...TypeRef
        }
        isDeprecated
        deprecationReason
      }
      inputFields(includeDeprecated: true) {
        ...InputValue
      }
      interfaces {
        ...TypeRef
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
      possibleTypes {
        ...TypeRef
      }
    }

    fragment InputValue on __InputValue {
      name
      description
      type { ...TypeRef }
      defaultValue
      isDeprecated
      deprecationReason
    }

    fragment TypeRef on __Type {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                    ofType {
                      kind
                      name
                      ofType {
                        kind
                        name
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
    """
}

struct GraphQLRequestPayload: Codable {
    let query: String
}

struct GraphQLResponsePayload<T: Codable>: Codable {
    let data: T
}

struct IntrospectionQueryResponse: Codable {
    let __schema: __Schema
}

public func sendIntrospectionRequest(url: String) async throws -> __Schema {
    guard let url = URL(string: url) else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(GraphQLRequestPayload(query: getIntrospectionQuery()))
    
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(GraphQLResponsePayload<IntrospectionQueryResponse>.self, from: data).data.__schema
}
