import Foundation

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

    init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    func countriesByCode(variables: CountriesByCodeRequest) async throws -> CountriesByCodeResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let query =
        """
        query CountriesByCode($code: String!) {
          countries(filter: { code: { eq: $code } }) {
            code
          }
        }
        """
        let requestPayload = GraphQLRequestPayload<CountriesByCodeRequest>(query: query, variables: variables)
        request.httpBody = try JSONEncoder().encode(requestPayload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // TODO: Error handling for graphql server message
        return try jsonDecoder.decode(GraphQLResponsePayload<CountriesByCodeResponse>.self, from: data).data
    }
}

let client = GraphQLClient()
let response = try await client.countriesByCode(variables: .init(code: "AE"))
debugPrint(response)
