import Foundation


let client = GraphQLClient()
let allCountries = try await client.allCountries()
debugPrint("client.allCountries", allCountries)
let countriesByCode = try await client.countriesByCode(variables: .init(code: "AE"))
debugPrint("client.countriesByCode", countriesByCode)
