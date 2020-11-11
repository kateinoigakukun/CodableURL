public protocol CodableURL: Codable {
    /// Creates an instance of this parsable type using the definitions
    /// given by each property's wrapper.
    init()
}

public extension CodableURL {
    static func decode(pathComponents: [String], queryParameter: @escaping (String) -> String?) throws -> Self {
        let decoder = URLDecoder(
            definitionMap: Self.definitionMap(),
            pathComponents: pathComponents,
            queryParameter: queryParameter
        )
        return try Self(from: decoder)
    }

    func encode() throws -> (pathComponents: [String], queryParameters: [String: String]) {
        let encoder = URLEncoder(definitionMap: Self.definitionMap())
        try encode(to: encoder)
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
    case staticPaths([String])
    case dynamicPath
    case query(key: String?, default: Any?)
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

@propertyWrapper
public struct StaticPath: Codable, URLComponentWrapper {
    var wrapperState: WrapperState<Void>

    public init<S: StringProtocol>(_ components: S...) {
        wrapperState = .definition(.staticPaths(components.map { String($0) }))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .staticPaths(expectedComponents) = context.definition else {
            throw CodingError.invalidState("StaticPath should have .staticPath definition")
        }
        var components = ArraySlice(expectedComponents)
        while let expected = components.first {
            guard let head = context.decoder.consumePathComponent() else {
                throw CodingError.missingStaticPath(expected)
            }
            guard expected == head else {
                throw CodingError.staticPathMismatch(expected: expected, actual: head)
            }
            components = components.dropFirst()
        }
        wrapperState = .value(())
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case let .staticPaths(components) = context.definition else {
            throw CodingError.invalidState("StaticPath should have .staticPath definition")
        }
        context.encoder.appendPath(components: components)
    }

    public var wrappedValue: Void {
        return
    }
}

@propertyWrapper
public struct DynamicPath<Value>: Codable, URLComponentWrapper where Value: LosslessStringConvertible {
    var wrapperState: WrapperState<Value>
    public init() {
        wrapperState = .definition(.dynamicPath)
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case .dynamicPath = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
        guard let head = context.decoder.consumePathComponent() else {
            throw CodingError.missingDynamicPath(Value.self, forKey: context.key.rawValue)
        }
        guard let value = Value(head) else {
            throw CodingError.invalidDynamicPathValue(head, forType: Value.self, forKey: context.key.rawValue)
        }
        wrapperState = .value(value)
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case .dynamicPath = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
        guard case let .value(value) = wrapperState else {
            throw CodingError.noValue(forKey: context.key.rawValue)
        }
        context.encoder.appendPath(String(value))
    }

    public var wrappedValue: Value {
        get {
            switch wrapperState {
            case let .value(value):
                return value
            case .definition:
                fatalError()
            }
        }
        set {
            wrapperState = .value(newValue)
        }
    }
}

@propertyWrapper
public struct Query<Value>: Codable, URLComponentWrapper where Value: LosslessStringConvertible {
    var wrapperState: WrapperState<Value>
    public init(_ key: String? = nil, default: Value? = nil) {
        wrapperState = .definition(.query(key: key, default: `default`))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .query(customKey, defaultValue) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }
        let queryKey = customKey ?? context.key.rawValue
        guard let stringValue = context.decoder.queryParameter(queryKey) else {
            wrapperState = try .value(Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue))
            return
        }

        guard let value = Value(stringValue) else {
            throw CodingError.invalidQueryValue(stringValue, forKey: queryKey)
        }
        wrapperState = .value(value)
    }

    private static func provideDefaultValue(for queryKey: String, defaultValue: Any?) throws -> Value {
        if let optionalType = Value.self as? OptionalProtocol.Type {
            return optionalType.provideNil() as! Value
        }
        guard let defaultValue = defaultValue else {
            throw CodingError.noValue(forKey: queryKey)
        }
        guard let typedDefaultValue = defaultValue as? Value else {
            throw CodingError.invalidState("type of defaultValue should be \(Value.self)")
        }
        return typedDefaultValue
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case let .query(customKey, defaultValue) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }
        let queryKey = customKey ?? context.key.rawValue
        guard case let .value(value) = wrapperState else {
            let value = try Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue)
            context.encoder.add(queryKey, value: String(value))
            return
        }
        context.encoder.add(queryKey, value: String(value))
    }

    public var wrappedValue: Value {
        get {
            switch wrapperState {
            case let .value(value):
                return value
            case .definition:
                fatalError()
            }
        }
        set {
            wrapperState = .value(newValue)
        }
    }
}
