@propertyWrapper
public struct Query<Value>: Codable, URLComponentWrapper {
    var wrapperState: WrapperState<Value>
    public init(_ key: String? = nil, default: Value? = nil)
    where Value: LosslessStringConvertible {
        let converter = StringLosslessConverter<Value>(
            factory: { Value($0) }, convert: { $0.description }
        )
        wrapperState = .definition(.query(key: key, default: `default`, converter))
    }

    public init(_ key: String? = nil, default: Value? = nil)
    where Value: RawRepresentable, Value.RawValue == String {
        let converter = StringLosslessConverter<Value>(
            factory: { Value(rawValue: $0) }, convert: { $0.rawValue }
        )
        wrapperState = .definition(.query(key: key, default: `default`, converter))
    }

    public init<T>(_ key: String? = nil, default: Value = nil)
    where Value == T?, T: LosslessStringConvertible {
        let converter = StringLosslessConverter<Value>(
            factory: { T($0) },
            convert: { $0?.description }
        )
        wrapperState = .definition(.query(key: key, default: `default`, converter))
    }

    public init<T>(_ key: String? = nil, default: Value = nil)
    where Value == T?, T: RawRepresentable, T.RawValue == String {
        let converter = StringLosslessConverter<Value>(
            factory: { T(rawValue: $0) },
            convert: { $0?.rawValue }
        )
        wrapperState = .definition(.query(key: key, default: `default`, converter))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .query(customKey, defaultValue, converterBox) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }
        let converter = converterBox as! StringLosslessConverter<Value>
        let queryKey = customKey ?? context.key.rawValue
        guard let stringValue = context.decoder.queryParameter(queryKey) else {
            wrapperState = try .value(
                Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue))
            return
        }

        guard let value = converter.factory(stringValue) else {
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
        guard case let .query(customKey, defaultValue, converterBox) = context.definition else {
            throw CodingError.invalidState("Query should have .query definition")
        }
        let converter = converterBox as! StringLosslessConverter<Value>

        let queryKey = customKey ?? context.key.rawValue
        guard case let .value(value) = wrapperState else {
            let value = try Self.provideDefaultValue(for: queryKey, defaultValue: defaultValue)
            if let value = converter.convert(value) {
                context.encoder.add(queryKey, value: value)
            }
            return
        }
        if let value = converter.convert(value) {
            context.encoder.add(queryKey, value: value)
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
