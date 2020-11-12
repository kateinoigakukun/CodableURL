internal class _StringLosslessConverterBox {
    let _factory: (String) -> Any?
    let _convert: (Any) -> String?

    internal init<T>(factory: @escaping (String) -> T?, convert: @escaping (T) -> String?) {
        self._factory = factory
        self._convert = { convert($0 as! T) }
    }
}
internal class StringLosslessConverter<T>: _StringLosslessConverterBox {
    func factory(_ string: String) -> T? { _factory(string) as! T? }
    func convert(_ value: T) -> String? { _convert(value) }
}

@propertyWrapper
public struct DynamicPath<Value>: Codable, URLComponentWrapper {
    var wrapperState: WrapperState<Value>
    public init() where Value: LosslessStringConvertible {
        let converter: _StringLosslessConverterBox = StringLosslessConverter<Value>(
            factory: { Value($0) }, convert: { $0.description }
        )
        wrapperState = .definition(.dynamicPath(converter))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .dynamicPath(converterBox) = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
        let converter = converterBox as! StringLosslessConverter<Value>

        guard let head = context.decoder.consumePathComponent() else {
            throw CodingError.missingDynamicPath(Value.self, forKey: context.key.rawValue)
        }
        guard let value = converter.factory(head) else {
            throw CodingError.invalidDynamicPathValue(
                head, forType: Value.self, forKey: context.key.rawValue)
        }
        wrapperState = .value(value)
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case let .dynamicPath(converterBox) = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
        let converter = converterBox as! StringLosslessConverter<Value>
        guard case let .value(value) = wrapperState else {
            throw CodingError.noValue(forKey: context.key.rawValue)
        }
        if let path = converter.convert(value) {
            context.encoder.appendPath(path)
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
