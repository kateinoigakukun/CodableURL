@propertyWrapper
public struct StaticPath: Codable, URLComponentWrapper {
    var wrapperState: WrapperState<Void>

    public init<S: StringProtocol>(_ components: S...) {
        wrapperState = .definition(.staticPaths(components.map { String($0) }))
    }

    public init() {
        wrapperState = .definition(.staticPaths(nil))
    }

    public init(from decoder: Decoder) throws {
        guard let context = decoder as? SingleValueDecoder else {
            throw CodingError.invalidState("Invalid context type: \(decoder)")
        }
        guard case let .staticPaths(expectedComponents) = context.definition else {
            throw CodingError.invalidState("StaticPath should have .staticPath definition")
        }
        var components = ArraySlice(expectedComponents ?? [context.key.rawValue])
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
        context.encoder.appendPath(components: components ?? [context.key.rawValue])
    }

    public var wrappedValue: Void {
        return
    }
}
