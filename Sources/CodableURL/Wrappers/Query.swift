@propertyWrapper
public struct Query<Value>: Codable, URLComponentWrapper where Value: ExpressibleByURLComponent {
    var wrapperState: WrapperState<Value>

    public init(_ key: String? = nil, default: Value? = nil, placeholder: String? = nil) {
        wrapperState = .definition(.query(key: key, default: `default`, customPlaceholder: placeholder))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .query(customKey, defaultValue, _) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }
        let queryKey = customKey ?? context.key.rawValue
        guard let stringValue = context.decoder.queryParameter(queryKey) else {
            wrapperState = try .value(
                Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue))
            return
        }

        guard let value = Value(urlComponent: stringValue) else {
            throw CodingError.invalidQueryValue(stringValue, forKey: queryKey)
        }
        wrapperState = .value(value)
    }

    private static func provideDefaultValue(for queryKey: String, defaultValue: Any?) throws
        -> Value
    {
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
        guard case let .query(customKey, defaultValue, customPlaceholder) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }

        let queryKey = customKey ?? context.key.rawValue

        switch context.encoder.strategy {
        case .embedValue:
            guard case let .value(value) = wrapperState else {
                let value = try Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue)
                if let value = value.urlComponent {
                    context.encoder.add(queryKey, value: value)
                }
                return
            }
            if let value = value.urlComponent {
                context.encoder.add(queryKey, value: value)
            }
        case .placeholder:
            let placeholder = customPlaceholder ?? ":\(context.key.rawValue)"
            context.encoder.add(queryKey, value: placeholder)
            return
        }
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
