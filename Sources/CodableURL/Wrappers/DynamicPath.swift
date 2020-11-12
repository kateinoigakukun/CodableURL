internal typealias _StringLosslessConverter = (
    factory: (String) -> Any?, convert: (Any) -> String?
)

@propertyWrapper
public struct DynamicPath<Value>: Codable, URLComponentWrapper {
    var wrapperState: WrapperState<Value>
    public init() where Value: LosslessStringConvertible {
        let converter: _StringLosslessConverter = (
            factory: { Value($0) }, convert: { ($0 as! Value).description }
        )
        wrapperState = .definition(.dynamicPath(converter))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .dynamicPath(converter) = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
        guard let head = context.decoder.consumePathComponent() else {
            throw CodingError.missingDynamicPath(Value.self, forKey: context.key.rawValue)
        }
        guard let value = converter.factory(head) as? Value else {
            throw CodingError.invalidDynamicPathValue(
                head, forType: Value.self, forKey: context.key.rawValue)
        }
        wrapperState = .value(value)
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case let .dynamicPath(converter) = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }
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
