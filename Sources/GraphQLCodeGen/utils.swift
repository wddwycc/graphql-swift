import GraphQLParser

func extractNodeString(ctx: Context, node: ASTNode) throws -> String {
    guard let loc = node.loc else { throw CodegenErrors.missingLocationInfoInAST }
    return ctx.rawDocument.subString(from: loc.start, to: loc.end)
}

extension String {
    func subString(from: Int, to: Int) -> String {
       let startIndex = self.index(self.startIndex, offsetBy: from)
       let endIndex = self.index(self.startIndex, offsetBy: to)
       return String(self[startIndex..<endIndex])
    }
    
    func firstLetterLowercased() -> String {
        guard !self.isEmpty else {
            return self
        }
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}
