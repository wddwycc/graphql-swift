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

/// Reference: https://github.com/apple/swift-syntax/blob/swift-5.10-RELEASE/Sources/SwiftSyntax/generated/Keyword.swift#L15
/// Copied here for inclusion check
enum SwiftKeyword: String {
    case __consuming
    case __owned
    case __setter_access
    case __shared
    case _alignment
    case _backDeploy
    case _borrow
    case _borrowing
    case _cdecl
    case _Class
    case _compilerInitialized
    case _const
    case _consuming
    case _documentation
    case _dynamicReplacement
    case _effects
    case _expose
    case _forward
    case _implements
    case _linear
    case _local
    case _modify
    case _move
    case _mutating
    case _NativeClass
    case _NativeRefCountedObject
    case _noMetadata
    case _nonSendable
    case _objcImplementation
    case _objcRuntimeName
    case _opaqueReturnTypeOf
    case _optimize
    case _originallyDefinedIn
    case _PackageDescription
    case _private
    case _projectedValueProperty
    case _read
    case _RefCountedObject
    case _semantics
    case _specialize
    case _spi
    case _spi_available
    case _swift_native_objc_runtime_base
    case _Trivial
    case _TrivialAtMost
    case _typeEraser
    case _unavailableFromAsync
    case _underlyingVersion
    case _UnknownLayout
    case _version
    case accesses
    case actor
    case addressWithNativeOwner
    case addressWithOwner
    case any
    case `Any`
    case `as`
    case assignment
    case `associatedtype`
    case associativity
    case async
    case attached
    case autoclosure
    case availability
    case available
    case await
    case backDeployed
    case before
    case block
    case borrowing
    case `break`
    case canImport
    case `case`
    case `catch`
    case `class`
    case compiler
    case consume
    case copy
    case consuming
    case `continue`
    case convenience
    case convention
    case cType
    case `default`
    case `defer`
    case `deinit`
    case deprecated
    case derivative
    case didSet
    case differentiable
    case distributed
    case `do`
    case dynamic
    case each
    case `else`
    case `enum`
    case escaping
    case exclusivity
    case exported
    case `extension`
    case `fallthrough`
    case `false`
    case file
    case `fileprivate`
    case final
    case `for`
    case discard
    case forward
    case `func`
    case get
    case `guard`
    case higherThan
    case `if`
    case `import`
    case `in`
    case indirect
    case infix
    case `init`
    case initializes
    case inline
    case `inout`
    case `internal`
    case introduced
    case `is`
    case isolated
    case kind
    case lazy
    case left
    case `let`
    case line
    case linear
    case lowerThan
    case macro
    case message
    case metadata
    case module
    case mutableAddressWithNativeOwner
    case mutableAddressWithOwner
    case mutating
    case `nil`
    case noasync
    case noDerivative
    case noescape
    case none
    case nonisolated
    case nonmutating
    case objc
    case obsoleted
    case of
    case open
    case `operator`
    case optional
    case override
    case package
    case postfix
    case `precedencegroup`
    case prefix
    case `private`
    case `Protocol`
    case `protocol`
    case `public`
    case reasync
    case renamed
    case `repeat`
    case required
    case `rethrows`
    case `return`
    case reverse
    case right
    case safe
    case `self`
    case `Self`
    case Sendable
    case set
    case some
    case sourceFile
    case spi
    case spiModule
    case `static`
    case `struct`
    case `subscript`
    case `super`
    case swift
    case `switch`
    case target
    case then
    case `throw`
    case `throws`
    case transpose
    case `true`
    case `try`
    case `Type`
    case `typealias`
    case unavailable
    case unchecked
    case unowned
    case unsafe
    case unsafeAddress
    case unsafeMutableAddress
    case `var`
    case visibility
    case weak
    case `where`
    case `while`
    case willSet
    case witness_method
    case wrt
    case yield
}
