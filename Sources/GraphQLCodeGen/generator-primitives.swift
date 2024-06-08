//

import SwiftSyntax
import GraphQLParser

func safeFieldName(_ fieldName: String) -> String {
    if isSwiftKeyword(fieldName) {
        return "`\(fieldName)`"
    }
    return fieldName
}

func getQueryType(schema: __Schema) throws -> __Type {
    guard let queryTypeName = schema.queryType.name else {
        throw CodegenErrors.missingQueryTypeName
    }
    guard let queryType = schema.types.first(where: { $0.name == queryTypeName }) else {
        throw CodegenErrors.missingQueryType
    }
    return queryType
}

func convertSchemaTypeToSwiftType(ctx: Context, type: __Type, nonNull: Bool = false) throws -> TypeSyntaxProtocol {
    let tp: TypeSyntaxProtocol
    switch type.kind {
    case .SCALAR:
        if let scalarType = GraphQLBuiltInScalarType(rawValue: type.name!) {
            tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(scalarType.swiftType))
        } else {
            // TODO: Support custom scalars
            // https://spec.graphql.org/October2021/#sec-Scalars.Custom-Scalars
            throw CodegenErrors.TODO("support convertSchemaTypeToSwiftType for custom scalars")
        }
    case .OBJECT:
        ctx.visitedTypes.insert(type.name!)
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(type.name!))
    case .INTERFACE:
        throw CodegenErrors.TODO("support convertSchemaTypeToSwiftType for INTERFACE")
    case .UNION:
        throw CodegenErrors.TODO("support convertSchemaTypeToSwiftType for UNION")
    case .ENUM:
        ctx.visitedTypes.insert(type.name!)
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(name))
    case .INPUT_OBJECT:
        ctx.visitedTypes.insert(type.name!)
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        tp = IdentifierTypeSyntax(name: TokenSyntax.identifier(name))
    case .LIST:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for LIST type") }
        tp = ArrayTypeSyntax(element: try convertSchemaTypeToSwiftType(ctx: ctx, type: ofType))
    case .NON_NULL:
        if nonNull { throw CodegenErrors.invalidType("NON_NULL type cannot be nested") }
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for NON_NULL type") }
        return try convertSchemaTypeToSwiftType(ctx: ctx, type: ofType, nonNull: true)
    }
    if (nonNull) {
        return tp
    }
    return OptionalTypeSyntax(wrappedType: tp)
}

func getWrappedType(ctx: Context, type: __Type) throws -> __Type {
    switch type.kind {
    case .SCALAR:
        return type
    case .OBJECT:
        guard let name = type.name else { throw CodegenErrors.invalidType("Expect name for OBJECT type") }
        return ctx.schema.types.first(where: { $0.name == name })!
    case .INTERFACE:
        return type
    case .UNION:
        return type
    case .ENUM:
        return type
    case .INPUT_OBJECT:
        return type
    case .LIST:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for LIST type") }
        return try getWrappedType(ctx: ctx, type: ofType)
    case .NON_NULL:
        guard let ofType = type.ofType else { throw CodegenErrors.invalidType("Missing `ofType` for NON_NULL type") }
        return try getWrappedType(ctx: ctx, type: ofType)
    }

}

private func getFields(ctx: Context, selectionSet: SelectionSetNode, schemaType: __Type) throws -> [(FieldNode, __Field)] {
    try selectionSet.selections.flatMap {
        switch $0 {
        case .field(let field):
            // NOTE: __schema doesn't exist in schema fields, but still queriable
            if field.name.value == "__schema" {
                let fieldInSchema = __Field(
                    name: "__schema", description: nil, args: [],
                    type: ctx.schema.types.first(where: { $0.name == "__Schema" })!, isDeprecated: false, deprecationReason: nil
                )
                return [(field, fieldInSchema)]
            }
            guard let fieldInSchema = schemaType.fields?.first(where: { $0.name == field.name.value }) else {
                throw CodegenErrors.missingField(field.name.value)
            }
            return [(field, fieldInSchema)]
        case .fragmentSpread(let fragmentSpread):
            let fragmentName = fragmentSpread.name.value
            let fragmentNode = ctx.document.definitions
                .flatMap { a in
                    if case let .executable(e) = a {
                        return [e]
                    }
                    return []
                }
                .flatMap { a in
                    if case let .fragment(f) = a {
                        return [f]
                    }
                    return []
                }
                .first(where: { a in a.name.value == fragmentName })!
            let schemaType = ctx.schema.types.first(where: { $0.name == fragmentNode.typeCondition.name.value })!
            return try getFields(ctx: ctx, selectionSet: fragmentNode.selectionSet, schemaType: schemaType)
        case .inlineFragment(let inlineFragment):
            guard let fragmentName = inlineFragment.typeCondition?.name.value ?? schemaType.name else {
                throw CodegenErrors.missingQueryTypeName
            }
            let schemaType = ctx.schema.types.first(where: { $0.name == fragmentName })!
            return try getFields(ctx: ctx, selectionSet: inlineFragment.selectionSet, schemaType: schemaType)
        }
    }
}

func generateStructBody(ctx: Context, schemaType: __Type, selectionSet: SelectionSetNode) throws -> MemberBlockItemListSyntax {
    let fields = try getFields(ctx: ctx, selectionSet: selectionSet, schemaType: schemaType)

    var declaredProperties = Set<String>()
    var declaredStructs = Set<String>()
    var body: [MemberBlockItemSyntax] = []
    for (field, fieldInSchema) in fields {
        let swiftType = try convertSchemaTypeToSwiftType(ctx: ctx, type: fieldInSchema.type)
        if (!declaredProperties.contains(field.name.value)) {
            declaredProperties.insert(field.name.value)
            body.append(MemberBlockItemSyntax(
                leadingTrivia: fieldInSchema.description.map(generateCodeComment(description:)),
                decl: DeclSyntax("public let \(raw: safeFieldName(field.name.value)): \(swiftType)")
            ))
        }
        if let nestedSelectionSet = field.selectionSet {
            let wrappedType = try getWrappedType(ctx: ctx, type: fieldInSchema.type)
            if (!declaredStructs.contains(wrappedType.name!)) {
                declaredStructs.insert(wrappedType.name!)
                body.append(MemberBlockItemSyntax(decl: StructDeclSyntax(
                    modifiers: [DeclModifierSyntax(name: .keyword(.public))],
                    name: TokenSyntax.identifier(wrappedType.name!),
                    inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
                    ]),
                    memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, schemaType: wrappedType, selectionSet: nestedSelectionSet))
                )))
            }
        }
    }

    return MemberBlockItemListSyntax(body)
}

func generateCodeComment(description: String) -> Trivia {
    let content: [TriviaPiece] = description
        .split(separator: "\n", omittingEmptySubsequences: false)
        .flatMap { a -> [TriviaPiece] in
            if (a.isEmpty) {
                return [.newlines(1)]
            }
            return [.docLineComment("\(a)"), .newlines(1)]
        }
    let pieces: [TriviaPiece] = 
        [.docBlockComment("/**"), .newlines(1)] 
        +
        content 
        +
        [.docBlockComment("*/"), .newlines(1)]
    return Trivia(pieces: pieces)
}
