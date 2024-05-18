//

import GraphQLParser

func extractNodeString(ctx: Context, node: ASTNode) throws -> String {
    guard let loc = node.loc else { throw CodegenErrors.missingLocationInfoInAST }
    return ctx.rawDocument.subString(from: loc.start, to: loc.end)
}

func lowercaseFirstLetter(_ string: String) -> String {
    guard !string.isEmpty else {
        return string
    }
    return string.prefix(1).lowercased() + string.dropFirst()
}

fileprivate extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex..<endIndex])
    }
}
