//
//  https://github.com/graphql/graphql-js/blob/v16.8.1/src/language/ast.ts
//

public protocol ASTNode {
    var kind: Kind { get }
    var loc: Location? { get }
    var children: [ASTNode] { get }
}

public protocol ProxyNode {
    var node: ASTNode { get }
}

// MARK: Name

public class NameNode: ASTNode, Decodable {
    public var kind: Kind { .NAME }
    public let loc: Location?
    public let value: String

    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
    
    public var children: [any ASTNode] { [] }
}

// MARK: Document

public class DocumentNode: ASTNode, Decodable {
    public var kind: Kind { .DOCUMENT }
    public let loc: Location?
    public let definitions: [DefinitionNode]

    public init(loc: Location?, definitions: [DefinitionNode]) {
        self.loc = loc
        self.definitions = definitions
    }
    
    public var children: [any ASTNode] { definitions.map(\.node) }
}

public enum DefinitionNode: ProxyNode, Decodable {
    case executable(ExecutableDefinitionNode)
    case typeSystem(TypeSystemDefinitionNode)
    case typeSystemExtension(TypeSystemExtensionNode)

    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case 
            .OPERATION_DEFINITION,
            .FRAGMENT_DEFINITION:
            self = .executable(try ExecutableDefinitionNode(from: decoder))
        case 
            .SCHEMA_DEFINITION,
            .SCALAR_TYPE_DEFINITION,
            .OBJECT_TYPE_DEFINITION,
            .INTERFACE_TYPE_DEFINITION,
            .UNION_TYPE_DEFINITION,
            .ENUM_TYPE_DEFINITION,
            .INPUT_OBJECT_TYPE_DEFINITION,
            .DIRECTIVE_DEFINITION:
            self = .typeSystem(try TypeSystemDefinitionNode(from: decoder))
        case 
            .SCHEMA_EXTENSION,
            .SCALAR_TYPE_EXTENSION,
            .OBJECT_TYPE_EXTENSION,
            .INTERFACE_TYPE_EXTENSION,
            .UNION_TYPE_EXTENSION,
            .ENUM_TYPE_EXTENSION,
            .INPUT_OBJECT_TYPE_EXTENSION:
            self = .typeSystemExtension(try TypeSystemExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown DefinitionNode kind")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .executable(let a): return a.node
        case .typeSystem(let a): return a.node
        case .typeSystemExtension(let a): return a.node
        }
    }
}

public enum ExecutableDefinitionNode: ProxyNode, Decodable {
    case operation(OperationDefinitionNode)
    case fragment(FragmentDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .OPERATION_DEFINITION:
            self = .operation(try OperationDefinitionNode(from: decoder))
        case .FRAGMENT_DEFINITION:
            self = .fragment(try FragmentDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown ExecutableDefinitionNode kind")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .operation(let a):
            return a
        case .fragment(let a):
            return a
        }
    }
}

public class OperationDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OPERATION_DEFINITION }
    public let loc: Location?
    public let operation: OperationTypeNode
    public let name: NameNode?
    public let variableDefinitions: [VariableDefinitionNode]?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode

    public init(loc: Location?,
                operation: OperationTypeNode,
                name: NameNode?,
                variableDefinitions: [VariableDefinitionNode]?,
                directives: [DirectiveNode]?,
                selectionSet: SelectionSetNode) {
        self.loc = loc
        self.operation = operation
        self.name = name
        self.variableDefinitions = variableDefinitions
        self.directives = directives
        self.selectionSet = selectionSet
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let name { rv.append(name) }
        if let variableDefinitions { rv.append(contentsOf: variableDefinitions) }
        if let directives { rv.append(contentsOf: directives) }
        rv.append(selectionSet)
        return rv
    }
}

public enum OperationTypeNode: String, Decodable {
    case query, mutation, subscription
}

public class VariableDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .VARIABLE_DEFINITION }
    public let loc: Location?
    public let variable: VariableNode
    public let type: TypeNode
    public let defaultValue: ConstValueNode?
    public let directives: [ConstDirectiveNode]?

    public init(loc: Location?,
                variable: VariableNode,
                type: TypeNode,
                defaultValue: ConstValueNode?,
                directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.variable = variable
        self.type = type
        self.defaultValue = defaultValue
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(variable)
        rv.append(type.node)
        if let defaultValue { rv.append(defaultValue.node) }
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class VariableNode: ASTNode, Decodable {
    public var kind: Kind { .VARIABLE }
    public let loc: Location?
    public let name: NameNode

    public init(loc: Location?,
                name: NameNode) {
        self.loc = loc
        self.name = name
    }
    
    public var children: [any ASTNode] { [name] }
}

public class SelectionSetNode: ASTNode, Decodable {
    public var kind: Kind { .SELECTION_SET }
    public let loc: Location?
    public let selections: [SelectionNode]

    public init(loc: Location?,
                selections: [SelectionNode]) {
        self.loc = loc
        self.selections = selections
    }
    
    public var children: [any ASTNode] { selections.map(\.node) }
}

public enum SelectionNode: ProxyNode, Decodable {
    case field(FieldNode)
    case fragmentSpread(FragmentSpreadNode)
    case inlineFragment(InlineFragmentNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .FIELD:
            self = .field(try FieldNode(from: decoder))
        case .FRAGMENT_SPREAD:
            self = .fragmentSpread(try FragmentSpreadNode(from: decoder))
        case .INLINE_FRAGMENT:
            self = .inlineFragment(try InlineFragmentNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown SelectionNode kind")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .field(let a): return a
        case .fragmentSpread(let a): return a
        case .inlineFragment(let a): return a
        }
    }
}

public class FieldNode: ASTNode, Decodable {
    public var kind: Kind { .FIELD }
    public let loc: Location?
    public let alias: NameNode?
    public let name: NameNode
    public let arguments: [ArgumentNode]?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode?
    
    public init(loc: Location?, alias: NameNode?, name: NameNode, arguments: [ArgumentNode]?, directives: [DirectiveNode]?, selectionSet: SelectionSetNode?) {
        self.loc = loc
        self.alias = alias
        self.name = name
        self.arguments = arguments
        self.directives = directives
        self.selectionSet = selectionSet
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let alias { rv.append(alias) }
        rv.append(name)
        if let arguments { rv.append(contentsOf: arguments) }
        if let directives { rv.append(contentsOf: directives) }
        if let selectionSet { rv.append(selectionSet) }
        return rv
    }
}

public class ArgumentNode: ASTNode, Decodable {
    public var kind: Kind { .ARGUMENT }
    public let loc: Location?
    public let name: NameNode
    public let value: ValueNode
    
    public init(loc: Location?, name: NameNode, value: ValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
    
    public var children: [any ASTNode] {
        [
            name,
            value.node
        ]
    }
}

public class ConstArgumentNode: ASTNode, Decodable {
    public var kind: Kind { .ARGUMENT }
    public let loc: Location?
    public let name: NameNode
    public let value: ConstValueNode
    
    public init(loc: Location?, name: NameNode, value: ConstValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
    
    public var children: [any ASTNode] {
        [
            name,
            value.node,
        ]
    }
}

// MARK: Fragments

public class FragmentSpreadNode: ASTNode, Decodable {
    public var kind: Kind { .FRAGMENT_SPREAD }
    public let loc: Location?
    public let name: NameNode
    public let directives: [DirectiveNode]?
    
    public init(loc: Location?, name: NameNode, directives: [DirectiveNode]?) {
        self.loc = loc
        self.name = name
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class InlineFragmentNode: ASTNode, Decodable {
    public var kind: Kind { .INLINE_FRAGMENT }
    public let loc: Location?
    public let typeCondition: NamedTypeNode?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode
    
    public init(loc: Location?, typeCondition: NamedTypeNode?, directives: [DirectiveNode]?, selectionSet: SelectionSetNode) {
        self.loc = loc
        self.typeCondition = typeCondition
        self.directives = directives
        self.selectionSet = selectionSet
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let typeCondition { rv.append(typeCondition) }
        if let directives { rv.append(contentsOf: directives) }
        rv.append(selectionSet)
        return rv
    }
}

public class FragmentDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .FRAGMENT_DEFINITION }
    public let loc: Location?
    public let name: NameNode
    public let variableDefinitions: [VariableDefinitionNode]?
    public let typeCondition: NamedTypeNode
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode
    
    public init(loc: Location?, name: NameNode, variableDefinitions: [VariableDefinitionNode]?, typeCondition: NamedTypeNode, directives: [DirectiveNode]?, selectionSet: SelectionSetNode) {
        self.loc = loc
        self.name = name
        self.variableDefinitions = variableDefinitions
        self.typeCondition = typeCondition
        self.directives = directives
        self.selectionSet = selectionSet
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let variableDefinitions { rv.append(contentsOf: variableDefinitions) }
        rv.append(typeCondition)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(selectionSet)
        return rv
    }
}

// MARK: Values

public enum ValueNode: ProxyNode, Decodable {
    case variable(VariableNode)
    case intValue(IntValueNode)
    case floatValue(FloatValueNode)
    case stringValue(StringValueNode)
    case booleanValue(BooleanValueNode)
    case nullValue(NullValueNode)
    case enumValue(EnumValueNode)
    case listValue(ListValueNode)
    case objectValue(ObjectValueNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .VARIABLE:
            self = .variable(try VariableNode(from: decoder))
        case .INT:
            self = .intValue(try IntValueNode(from: decoder))
        case .FLOAT:
            self = .floatValue(try FloatValueNode(from: decoder))
        case .STRING:
            self = .stringValue(try StringValueNode(from: decoder))
        case .BOOLEAN:
            self = .booleanValue(try BooleanValueNode(from: decoder))
        case .NULL:
            self = .nullValue(try NullValueNode(from: decoder))
        case .ENUM:
            self = .enumValue(try EnumValueNode(from: decoder))
        case .LIST:
            self = .listValue(try ListValueNode(from: decoder))
        case .OBJECT:
            self = .objectValue(try ObjectValueNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for ValueNode")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .variable(let a): return a
        case .intValue(let a): return a
        case .floatValue(let a): return a
        case .stringValue(let a): return a
        case .booleanValue(let a): return a
        case .nullValue(let a): return a
        case .enumValue(let a): return a
        case .listValue(let a): return a
        case .objectValue(let a): return a
        }
    }
}

public enum ConstValueNode: ProxyNode, Decodable {
    case intValue(IntValueNode)
    case floatValue(FloatValueNode)
    case stringValue(StringValueNode)
    case booleanValue(BooleanValueNode)
    case nullValue(NullValueNode)
    case enumValue(EnumValueNode)
    case constListValue(ConstListValueNode)
    case constObjectValue(ConstObjectValueNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .INT:
            self = .intValue(try IntValueNode(from: decoder))
        case .FLOAT:
            self = .floatValue(try FloatValueNode(from: decoder))
        case .STRING:
            self = .stringValue(try StringValueNode(from: decoder))
        case .BOOLEAN:
            self = .booleanValue(try BooleanValueNode(from: decoder))
        case .NULL:
            self = .nullValue(try NullValueNode(from: decoder))
        case .ENUM:
            self = .enumValue(try EnumValueNode(from: decoder))
        case .LIST:
            self = .constListValue(try ConstListValueNode(from: decoder))
        case .OBJECT:
            self = .constObjectValue(try ConstObjectValueNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for ConstValueNode")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .intValue(let a): return a
        case .floatValue(let a): return a
        case .stringValue(let a): return a
        case .booleanValue(let a): return a
        case .nullValue(let a): return a
        case .enumValue(let a): return a
        case .constListValue(let a): return a
        case .constObjectValue(let a): return a
        }
    }
}

public class IntValueNode: ASTNode, Decodable {
    public var kind: Kind { .INT }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
    
    public var children: [any ASTNode] { [] }
}

public class FloatValueNode: ASTNode, Decodable {
    public var kind: Kind { .FLOAT }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
    
    public var children: [any ASTNode] { [] }
}

public class StringValueNode: ASTNode, Decodable {
    public var kind: Kind { .STRING }
    public let loc: Location?
    public let value: String
    public let block: Bool?
    
    public init(loc: Location?, value: String, block: Bool?) {
        self.loc = loc
        self.value = value
        self.block = block
    }
    
    public var children: [any ASTNode] { [] }
}

public class BooleanValueNode: ASTNode, Decodable {
    public var kind: Kind { .BOOLEAN }
    public let loc: Location?
    public let value: Bool
    
    public init(loc: Location?, value: Bool) {
        self.loc = loc
        self.value = value
    }
    
    public var children: [any ASTNode] { [] }
}

public class NullValueNode: ASTNode, Decodable {
    public var kind: Kind { .NULL }
    public let loc: Location?
    
    public init(loc: Location?) {
        self.loc = loc
    }
    
    public var children: [any ASTNode] { [] }
}

public class EnumValueNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
    
    public var children: [any ASTNode] { [] }
}

public class ListValueNode: ASTNode, Decodable {
    public var kind: Kind { .LIST }
    public let loc: Location?
    public let values: [ValueNode]
    
    public init(loc: Location?, values: [ValueNode]) {
        self.loc = loc
        self.values = values
    }
    
    public var children: [any ASTNode] { values.map(\.node) }
}

public class ConstListValueNode: ASTNode, Decodable {
    public var kind: Kind { .LIST }
    public let loc: Location?
    public let values: [ConstValueNode]
    
    public init(loc: Location?, values: [ConstValueNode]) {
        self.loc = loc
        self.values = values
    }
    
    public var children: [any ASTNode] { values.map(\.node) }
}

public class ObjectValueNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT }
    public let loc: Location?
    public let fields: [ObjectFieldNode]
    
    public init(loc: Location?, fields: [ObjectFieldNode]) {
        self.loc = loc
        self.fields = fields
    }
    
    public var children: [any ASTNode] { fields }
}

public class ConstObjectValueNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT }
    public let loc: Location?
    public let fields: [ConstObjectFieldNode]
    
    public init(loc: Location?, fields: [ConstObjectFieldNode]) {
        self.loc = loc
        self.fields = fields
    }
    
    public var children: [any ASTNode] { fields }
}

public class ObjectFieldNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_FIELD }
    public let loc: Location?
    public let name: NameNode
    public let value: ValueNode
    
    public init(loc: Location?, name: NameNode, value: ValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
    
    public var children: [any ASTNode] { [name, value.node] }
}

public class ConstObjectFieldNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_FIELD }
    public let loc: Location?
    public let name: NameNode
    public let value: ConstValueNode
    
    public init(loc: Location?, name: NameNode, value: ConstValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
    
    public var children: [any ASTNode] { [name, value.node] }
}

/** Directives */

public class DirectiveNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE }
    public let loc: Location?
    public let name: NameNode
    public let arguments: [ArgumentNode]?
    
    public init(loc: Location?, name: NameNode, arguments: [ArgumentNode]?) {
        self.loc = loc
        self.name = name
        self.arguments = arguments
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let arguments { rv.append(contentsOf: arguments) }
        return rv
    }
}

public class ConstDirectiveNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE }
    public let loc: Location?
    public let name: NameNode
    public let arguments: [ConstArgumentNode]?
    
    public init(loc: Location?, name: NameNode, arguments: [ConstArgumentNode]?) {
        self.loc = loc
        self.name = name
        self.arguments = arguments
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let arguments { rv.append(contentsOf: arguments) }
        return rv
    }
}

// MARK: Type Reference

public indirect enum TypeNode: ProxyNode, Decodable {
    case named(NamedTypeNode)
    case list(ListTypeNode)
    case nonNull(NonNullTypeNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .NAMED_TYPE:
            self = .named(try NamedTypeNode(from: decoder))
        case .LIST_TYPE:
            self = .list(try ListTypeNode(from: decoder))
        case .NON_NULL_TYPE:
            self = .nonNull(try NonNullTypeNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for TypeNode")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .named(let a): return a
        case .list(let a): return a
        case .nonNull(let a): return a
        }
    }
}

public class NamedTypeNode: ASTNode, Decodable {
    public var kind: Kind { .NAMED_TYPE }
    public let loc: Location?
    public let name: NameNode
    
    public init(loc: Location?, name: NameNode) {
        self.loc = loc
        self.name = name
    }
    
    public var children: [any ASTNode] { [name] }
}

public class ListTypeNode: ASTNode, Decodable {
    public var kind: Kind { .LIST_TYPE }
    public let loc: Location?
    public let type: TypeNode
    
    public init(loc: Location?, type: TypeNode) {
        self.loc = loc
        self.type = type
    }
    
    public var children: [any ASTNode] { [type.node] }
}

public class NonNullTypeNode: ASTNode, Decodable {
    public var kind: Kind { .NON_NULL_TYPE }
    public let loc: Location?
    public let type: TypeNode
    
    public init(loc: Location?, type: TypeNode) {
        self.loc = loc
        self.type = type
    }
    
    public var children: [any ASTNode] { [type.node] }
}

// MARK: Type System Definition

public enum TypeSystemDefinitionNode: ProxyNode, Decodable {
    case schema(SchemaDefinitionNode)
    case type(TypeDefinitionNode)
    case directive(DirectiveDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCHEMA_DEFINITION:
            self = .schema(try SchemaDefinitionNode(from: decoder))
        case .SCALAR_TYPE_DEFINITION, .OBJECT_TYPE_DEFINITION, .INTERFACE_TYPE_DEFINITION, .UNION_TYPE_DEFINITION, .ENUM_TYPE_DEFINITION, .INPUT_OBJECT_TYPE_DEFINITION:
            self = .type(try TypeDefinitionNode(from: decoder))
        case .DIRECTIVE_DEFINITION:
            self = .directive(try DirectiveDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for TypeSystemDefinitionNode")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .schema(let a): return a
        case .type(let a): return a.node
        case .directive(let a): return a
        }
    }
}

public class SchemaDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .SCHEMA_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let directives: [ConstDirectiveNode]?
    public let operationTypes: [OperationTypeDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, directives: [ConstDirectiveNode]?, operationTypes: [OperationTypeDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.directives = directives
        self.operationTypes = operationTypes
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: operationTypes)
        return rv
    }
}

public class OperationTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OPERATION_TYPE_DEFINITION }
    public let loc: Location?
    public let operation: OperationTypeNode
    public let type: NamedTypeNode
    
    public init(loc: Location?, operation: OperationTypeNode, type: NamedTypeNode) {
        self.loc = loc
        self.operation = operation
        self.type = type
    }
    
    public var children: [any ASTNode] { [type] }
}

// MARK: Type Definition

public enum TypeDefinitionNode: ProxyNode, Decodable {
    case scalar(ScalarTypeDefinitionNode)
    case object(ObjectTypeDefinitionNode)
    case interface(InterfaceTypeDefinitionNode)
    case union(UnionTypeDefinitionNode)
    case `enum`(EnumTypeDefinitionNode)
    case inputObject(InputObjectTypeDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCALAR_TYPE_DEFINITION:
            self = .scalar(try ScalarTypeDefinitionNode(from: decoder))
        case .OBJECT_TYPE_DEFINITION:
            self = .object(try ObjectTypeDefinitionNode(from: decoder))
        case .INTERFACE_TYPE_DEFINITION:
            self = .interface(try InterfaceTypeDefinitionNode(from: decoder))
        case .UNION_TYPE_DEFINITION:
            self = .union(try UnionTypeDefinitionNode(from: decoder))
        case .ENUM_TYPE_DEFINITION:
            self = .enum(try EnumTypeDefinitionNode(from: decoder))
        case .INPUT_OBJECT_TYPE_DEFINITION:
            self = .inputObject(try InputObjectTypeDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown TypeDefinitionNode kind")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .scalar(let a):
            return a
        case .object(let a):
            return a
        case .interface(let a):
            return a
        case .union(let a):
            return a
        case .enum(let a):
            return a
        case .inputObject(let a):
            return a
        }
    }
}

public class ScalarTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .SCALAR_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class ObjectTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let interfaces { rv.append(contentsOf: interfaces) }
        if let directives { rv.append(contentsOf: directives) }
        if let fields { rv.append(contentsOf: fields) }
        return rv
    }
}

public class InterfaceTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INTERFACE_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let interfaces { rv.append(contentsOf: interfaces) }
        if let directives { rv.append(contentsOf: directives) }
        if let fields { rv.append(contentsOf: fields) }
        return rv
    }
}

public class UnionTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .UNION_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let types: [NamedTypeNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, types: [NamedTypeNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.types = types
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: types)
        return rv
    }
}

public class EnumTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let values: [EnumValueDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, values: [EnumValueDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.values = values
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: values)
        return rv
    }
}

public class EnumValueDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_VALUE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class InputObjectTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_OBJECT_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let fields: [InputValueDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, fields: [InputValueDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: fields)
        return rv
    }
}

public class FieldDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .FIELD_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let arguments: [InputValueDefinitionNode]?
    public let type: TypeNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, arguments: [InputValueDefinitionNode]?, type: TypeNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.arguments = arguments
        self.type = type
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        if let arguments { rv.append(contentsOf: arguments) }
        rv.append(type.node)
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class InputValueDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_VALUE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let type: TypeNode
    public let defaultValue: ConstValueNode?
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, type: TypeNode, defaultValue: ConstValueNode?, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        rv.append(type.node)
        if let defaultValue { rv.append(defaultValue.node) }
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

// MARK: Directive Definitions

public class DirectiveDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let arguments: [InputValueDefinitionNode]
    public let repeatable: Bool
    public let locations: [NameNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, arguments: [InputValueDefinitionNode], repeatable: Bool, locations: [NameNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.arguments = arguments
        self.repeatable = repeatable
        self.locations = locations
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let description { rv.append(description) }
        rv.append(name)
        rv.append(contentsOf: arguments)
        rv.append(contentsOf: locations)
        return rv
    }
}

// MARK: Type System Extensions

public enum TypeSystemExtensionNode: ProxyNode, Decodable {
    case schema(SchemaExtensionNode)
    case type(TypeExtensionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCHEMA_EXTENSION:
            self = .schema(try SchemaExtensionNode(from: decoder))
        case 
            .SCALAR_TYPE_EXTENSION,
            .OBJECT_TYPE_EXTENSION,
            .INTERFACE_TYPE_EXTENSION,
            .UNION_TYPE_EXTENSION,
            .ENUM_TYPE_EXTENSION,
            .INPUT_OBJECT_TYPE_EXTENSION:
            self = .type(try TypeExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown TypeSystemExtensionNode kind")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .schema(let a): return a
        case .type(let a): return a.node
        }
    }
}

public class SchemaExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .SCHEMA_EXTENSION }
    public let loc: Location?
    public let directives: [ConstDirectiveNode]?
    public let operationTypes: [OperationTypeDefinitionNode]
    
    public init(loc: Location?, directives: [ConstDirectiveNode]?, operationTypes: [OperationTypeDefinitionNode]) {
        self.loc = loc
        self.directives = directives
        self.operationTypes = operationTypes
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: operationTypes)
        return rv
    }
}

// MARK: Type Extensions

public enum TypeExtensionNode: ProxyNode, Decodable {
    case scalar(ScalarTypeExtensionNode)
    case object(ObjectTypeExtensionNode)
    case interface(InterfaceTypeExtensionNode)
    case union(UnionTypeExtensionNode)
    case enumType(EnumTypeExtensionNode)
    case inputObject(InputObjectTypeExtensionNode)

    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCALAR_TYPE_EXTENSION:
            self = .scalar(try ScalarTypeExtensionNode(from: decoder))
        case .OBJECT_TYPE_EXTENSION:
            self = .object(try ObjectTypeExtensionNode(from: decoder))
        case .INTERFACE_TYPE_EXTENSION:
            self = .interface(try InterfaceTypeExtensionNode(from: decoder))
        case .UNION_TYPE_EXTENSION:
            self = .union(try UnionTypeExtensionNode(from: decoder))
        case .ENUM_TYPE_EXTENSION:
            self = .enumType(try EnumTypeExtensionNode(from: decoder))
        case .INPUT_OBJECT_TYPE_EXTENSION:
            self = .inputObject(try InputObjectTypeExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Invalid kind value for TypeExtensionNode")
        }
    }
    
    public var node: any ASTNode {
        switch self {
        case .scalar(let a):
            return a
        case .object(let a):
            return a
        case .interface(let a):
            return a
        case .union(let a):
            return a
        case .enumType(let a):
            return a
        case .inputObject(let a):
            return a
        }
    }
}

public class ScalarTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .SCALAR_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.name = name
        self.directives = directives
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        return rv
    }
}

public class ObjectTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let interfaces { rv.append(contentsOf: interfaces) }
        if let directives { rv.append(contentsOf: directives) }
        if let fields { rv.append(contentsOf: fields) }
        return rv
    }
}

public class InterfaceTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .INTERFACE_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let interfaces { rv.append(contentsOf: interfaces) }
        if let directives { rv.append(contentsOf: directives) }
        if let fields { rv.append(contentsOf: fields) }
        return rv
    }
}

public class UnionTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .UNION_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let types: [NamedTypeNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, types: [NamedTypeNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.types = types
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: types)
        return rv
    }
}

public class EnumTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let values: [EnumValueDefinitionNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, values: [EnumValueDefinitionNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.values = values
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: values)
        return rv
    }
}

public class InputObjectTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_OBJECT_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let fields: [InputValueDefinitionNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, fields: [InputValueDefinitionNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.fields = fields
    }
    
    public var children: [any ASTNode] {
        var rv: [ASTNode] = []
        rv.append(name)
        if let directives { rv.append(contentsOf: directives) }
        rv.append(contentsOf: fields)
        return rv
    }
}
