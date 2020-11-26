public protocol CodableURL: Codable {
    /// Creates an instance of this parsable type using the definitions
    /// given by each property's wrapper.
    init()
}

extension CodableURL {
    public static func decode(
        pathComponents: [String], queryParameter: @escaping (String) -> String?
    )
        throws -> Self
    {
        let decoder = URLDecoder(
            definitionMap: Self.definitionMap(),
            pathComponents: pathComponents,
            queryParameter: queryParameter
        )
        return try Self(from: decoder)
    }

    public func encode() throws -> (pathComponents: [String], queryParameters: [String: String]) {
        let encoder = URLEncoder(definitionMap: Self.definitionMap(), strategy: .embedValue)
        try encode(to: encoder)
        return (encoder.pathComponents, encoder.queryParameters)
    }

    public static func placeholder() throws -> (
        pathComponents: [String], queryParameters: [String: String]
    ) {
        let encoder = URLEncoder(
            definitionMap: Self.definitionMap(), strategy: .placeholder)
        let instance = Self()
        try instance.encode(to: encoder)
        return (encoder.pathComponents, encoder.queryParameters)
    }

    internal static func definitionMap() -> [_CodingKey: Definition] {
        let children = Mirror(reflecting: Self()).children
        return children.reduce(into: [_CodingKey: Definition]()) { result, element in
            guard var key = element.label,
                let field = element.value as? DefinitionProvider
            else {
                return
            }
            // Property wrappers have underscore-prefixed names
            key = String(key.first == "_" ? key.dropFirst(1) : key.dropFirst(0))
            result[_CodingKey(rawValue: key)] = field.provideDefinition()
        }
    }
}

internal enum Definition {
    case staticPaths([String]?)
    case dynamicPath(customPlaceholder: String?)
    case query(key: String?, default: Any?, customPlaceholder: String?)
}

internal enum WrapperState<Value> {
    case value(Value)
    case definition(Definition)
}

internal protocol DefinitionProvider {
    func provideDefinition() -> Definition
}

internal protocol URLComponentWrapper: DefinitionProvider {
    associatedtype Value
    var wrapperState: WrapperState<Value> { get }
}

extension URLComponentWrapper {
    func provideDefinition() -> Definition {
        switch wrapperState {
        case let .definition(definition):
            return definition
        default:
            fatalError()
        }
    }
}

internal protocol OptionalProtocol {
    static func provideNil() -> Self
}

extension Optional: OptionalProtocol {
    static func provideNil() -> Wrapped? { nil }
}

enum CodingError: Error {
    case invalidState(String)
    case missingStaticPath(String)
    case missingDynamicPath(Any.Type, forKey: String)
    case noValue(forKey: String)
    case staticPathMismatch(expected: String, actual: String)
    case invalidQueryValue(String, forKey: String)
    case invalidDynamicPathValue(String, forType: Any.Type, forKey: String)
}

internal struct _CodingKey: Hashable {
    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init<C: CodingKey>(_ codingKey: C) {
        rawValue = codingKey.stringValue
    }
}
