/**
 
 Ref: https://spec.graphql.org/October2021/#sec-Schema-Introspection.Schema-Introspection-Schema
 
 ```
 type __Schema {
   description: String
   types: [__Type!]!
   queryType: __Type!
   mutationType: __Type
   subscriptionType: __Type
   directives: [__Directive!]!
 }

 type __Type {
   kind: __TypeKind!
   name: String
   description: String
   # must be non-null for OBJECT and INTERFACE, otherwise null.
   fields(includeDeprecated: Boolean = false): [__Field!]
   # must be non-null for OBJECT and INTERFACE, otherwise null.
   interfaces: [__Type!]
   # must be non-null for INTERFACE and UNION, otherwise null.
   possibleTypes: [__Type!]
   # must be non-null for ENUM, otherwise null.
   enumValues(includeDeprecated: Boolean = false): [__EnumValue!]
   # must be non-null for INPUT_OBJECT, otherwise null.
   inputFields: [__InputValue!]
   # must be non-null for NON_NULL and LIST, otherwise null.
   ofType: __Type
   # may be non-null for custom SCALAR, otherwise null.
   specifiedByURL: String
 }

 enum __TypeKind {
   SCALAR
   OBJECT
   INTERFACE
   UNION
   ENUM
   INPUT_OBJECT
   LIST
   NON_NULL
 }

 type __Field {
   name: String!
   description: String
   args: [__InputValue!]!
   type: __Type!
   isDeprecated: Boolean!
   deprecationReason: String
 }

 type __InputValue {
   name: String!
   description: String
   type: __Type!
   defaultValue: String
 }

 type __EnumValue {
   name: String!
   description: String
   isDeprecated: Boolean!
   deprecationReason: String
 }

 type __Directive {
   name: String!
   description: String
   locations: [__DirectiveLocation!]!
   args: [__InputValue!]!
   isRepeatable: Boolean!
 }

 enum __DirectiveLocation {
   QUERY
   MUTATION
   SUBSCRIPTION
   FIELD
   FRAGMENT_DEFINITION
   FRAGMENT_SPREAD
   INLINE_FRAGMENT
   VARIABLE_DEFINITION
   SCHEMA
   SCALAR
   OBJECT
   FIELD_DEFINITION
   ARGUMENT_DEFINITION
   INTERFACE
   UNION
   ENUM
   ENUM_VALUE
   INPUT_OBJECT
   INPUT_FIELD_DEFINITION
 }
 ```
 
 */


public class __Schema: Codable {
    public let description: String?
    public let types: [__Type]
    public let queryType: __Type
    public let mutationType: __Type?
    public let subscriptionType: __Type?
    public let directives: [__Directive]

    public init(description: String?, types: [__Type], queryType: __Type, mutationType: __Type?, subscriptionType: __Type?, directives: [__Directive]) {
        self.description = description
        self.types = types
        self.queryType = queryType
        self.mutationType = mutationType
        self.subscriptionType = subscriptionType
        self.directives = directives
    }
}

public class __Type: Codable {
    public let kind: __TypeKind
    public let name: String?
    public let description: String?
    public let fields: [__Field]?
    public let interfaces: [__Type]?
    public let possibleTypes: [__Type]?
    public let enumValues: [__EnumValue]?
    public let inputFields: [__InputValue]?
    public let ofType: __Type?
    public let specifiedByURL: String?

    public init(kind: __TypeKind, name: String?, description: String?, fields: [__Field]?, interfaces: [__Type]?, possibleTypes: [__Type]?, enumValues: [__EnumValue]?, inputFields: [__InputValue]?, ofType: __Type?, specifiedByURL: String?) {
        self.kind = kind
        self.name = name
        self.description = description
        self.fields = fields
        self.interfaces = interfaces
        self.possibleTypes = possibleTypes
        self.enumValues = enumValues
        self.inputFields = inputFields
        self.ofType = ofType
        self.specifiedByURL = specifiedByURL
    }
}

public enum __TypeKind: String, Codable {
    case SCALAR
    case OBJECT
    case INTERFACE
    case UNION
    case ENUM
    case INPUT_OBJECT
    case LIST
    case NON_NULL
}

public class __Field: Codable {
    public let name: String
    public let description: String?
    public let args: [__InputValue]
    public let type: __Type
    public let isDeprecated: Bool
    public let deprecationReason: String?

    public init(name: String, description: String?, args: [__InputValue], type: __Type, isDeprecated: Bool, deprecationReason: String?) {
        self.name = name
        self.description = description
        self.args = args
        self.type = type
        self.isDeprecated = isDeprecated
        self.deprecationReason = deprecationReason
    }
}

public class __InputValue: Codable {
    public let name: String
    public let description: String?
    public let type: __Type
    public let defaultValue: String?

    public init(name: String, description: String?, type: __Type, defaultValue: String?) {
        self.name = name
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
    }
}

public class __EnumValue: Codable {
    public let name: String
    public let description: String?
    public let isDeprecated: Bool
    public let deprecationReason: String?

    public init(name: String, description: String?, isDeprecated: Bool, deprecationReason: String?) {
        self.name = name
        self.description = description
        self.isDeprecated = isDeprecated
        self.deprecationReason = deprecationReason
    }
}

public class __Directive: Codable {
    public let name: String
    public let description: String?
    public let locations: [__DirectiveLocation]
    public let args: [__InputValue]
    public let isRepeatable: Bool

    public init(name: String, description: String?, locations: [__DirectiveLocation], args: [__InputValue], isRepeatable: Bool) {
        self.name = name
        self.description = description
        self.locations = locations
        self.args = args
        self.isRepeatable = isRepeatable
    }
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
