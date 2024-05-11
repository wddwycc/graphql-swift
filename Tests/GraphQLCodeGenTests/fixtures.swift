import Foundation
import GraphQLCodeGen

func getSchema() -> __Schema {
    let url = Bundle.module.url(forResource: "schema", withExtension: "json")!
    return try! JSONDecoder().decode(__Schema.self, from: try! String(contentsOf: url).data(using: .utf8)!)
}
