public protocol ExpressibleByURLComponent {
    init?(urlComponent: String)
    var urlComponent: String? { get }
}

extension Optional: ExpressibleByURLComponent where Wrapped: ExpressibleByURLComponent {
    public init?(urlComponent: String) {
        guard let wrapped = Wrapped.init(urlComponent: urlComponent) else {
            return nil
        }
        self = .some(wrapped)
    }

    public var urlComponent: String? {
        switch self {
        case .some(let wrapped): return wrapped.urlComponent
        case .none: return nil
        }
    }
}

extension ExpressibleByURLComponent where Self: LosslessStringConvertible {
    public init?(urlComponent: String) {
        self.init(urlComponent)
    }

    public var urlComponent: String? {
        description
    }
}

extension String: ExpressibleByURLComponent {}

extension ExpressibleByURLComponent
where Self: RawRepresentable, Self.RawValue: ExpressibleByURLComponent {
    public init?(urlComponent: String) {
        guard let rawValue = RawValue(urlComponent: urlComponent) else { return nil }
        self.init(rawValue: rawValue)
    }

    public var urlComponent: String? {
        rawValue.urlComponent
    }
}

extension Int: ExpressibleByURLComponent {}
extension Int8: ExpressibleByURLComponent {}
extension Int16: ExpressibleByURLComponent {}
extension Int32: ExpressibleByURLComponent {}
extension Int64: ExpressibleByURLComponent {}
extension UInt: ExpressibleByURLComponent {}
extension UInt8: ExpressibleByURLComponent {}
extension UInt16: ExpressibleByURLComponent {}
extension UInt32: ExpressibleByURLComponent {}
extension UInt64: ExpressibleByURLComponent {}

extension Float: ExpressibleByURLComponent {}
extension Double: ExpressibleByURLComponent {}

extension Bool: ExpressibleByURLComponent {}
