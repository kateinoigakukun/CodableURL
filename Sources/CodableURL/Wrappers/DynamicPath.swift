@propertyWrapper
public struct DynamicPath<Value>: Codable, URLComponentWrapper
where Value: ExpressibleByURLComponent {
    var wrapperState: WrapperState<Value>
    public init(placeholder: String? = nil) {
        wrapperState = .definition(.dynamicPath(customPlaceholder: placeholder))
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
        guard let value = Value(urlComponent: head) else {
            throw CodingError.invalidDynamicPathValue(
                head, forType: Value.self, forKey: context.key.rawValue)
        }
        wrapperState = .value(value)
    }

    public func encode(to encoder: Encoder) throws {
        guard let context = encoder as? SingleValueEncoder else {
            throw CodingError.invalidState("Invalid context type: \(encoder)")
        }
        guard case .dynamicPath(let customPlaceholder) = context.definition else {
            throw CodingError.invalidState("DynamicPath should have .dynamicPath definition")
        }

        switch context.encoder.strategy {
        case .embedValue:
            guard case let .value(value) = wrapperState else {
                throw CodingError.noValue(forKey: context.key.rawValue)
            }
            if let path = value.urlComponent {
                context.encoder.appendPath(path)
            }
        case .placeholder:
            let placeholder = customPlaceholder ?? ":\(context.key.rawValue)"
            context.encoder.appendPath(placeholder)
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
