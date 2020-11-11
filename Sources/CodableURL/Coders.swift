internal final class URLDecoder: Decoder {
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any] = [:]
    
    let definitionMap: [_CodingKey: Definition]
    private let pathComponents: [String]
    private var pathComponentsOffset: Int
    let queryParameter: (String) -> String?

    init(
        definitionMap: [_CodingKey: Definition],
        pathComponents: [String],
        queryParameter: @escaping (String) -> String?
    ) {
        self.definitionMap = definitionMap
        self.pathComponents = pathComponents
        self.pathComponentsOffset = pathComponents.startIndex
        self.queryParameter = queryParameter
    }
    
    internal func consumePathComponent() -> String? {
        guard pathComponentsOffset < pathComponents.count else { return nil }
        defer { pathComponentsOffset += 1 }
        return pathComponents[pathComponentsOffset]
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Container<Key>(decoder: self, codingPath: codingPath))
    }

    final class Container<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
        var allKeys: [Key] { fatalError("unavailable") }
        let codingPath: [CodingKey]
        let decoder: URLDecoder
        init(decoder: URLDecoder, codingPath: [CodingKey]) {
            self.decoder = decoder
            self.codingPath = codingPath
        }

        func contains(_ codingKey: Key) -> Bool {
            decoder.definitionMap[_CodingKey(codingKey)] != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            !contains(key)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let definition = decoder.definitionMap[_CodingKey(key)] else {
                fatalError("definitionMap should have '\(key)'")
            }
            let context = SingleValueDecoder(
                codingPath: codingPath + [key], userInfo: decoder.userInfo,
                key: _CodingKey(key), definition: definition, decoder: decoder
            )
            return try T(from: context)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("unavailable")
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError("unavailable")
        }
        
        func superDecoder() throws -> Decoder {
            fatalError("unavailable")
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError("unavailable")
        }
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("unavailable")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("unavailable")
    }
}

internal struct SingleValueDecoder: Decoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let key: _CodingKey
    let definition: Definition
    let decoder: URLDecoder

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError("unavailable")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("unavailable")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("unavailable")
    }
}


final class URLEncoder: Encoder {
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any] = [:]
    let definitionMap: [_CodingKey: Definition]
    private(set) var pathComponents: [String] = []
    private(set) var queryParameters: [String: String] = [:]
    
    init(definitionMap: [_CodingKey: Definition]) {
        self.definitionMap = definitionMap
    }
    
    func add(_ key: String, value: String) {
        queryParameters[key] = value
    }
    func appendPath(_ component: String) {
        pathComponents.append(component)
    }
    func appendPath(components: [String]) {
        pathComponents.append(contentsOf: components)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(Container<Key>(codingPath: codingPath, encoder: self))
    }
    
    final class Container<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey]
        let encoder: URLEncoder
        init(codingPath: [CodingKey], encoder: URLEncoder) {
            self.codingPath = codingPath
            self.encoder = encoder
        }

        func encodeNil(forKey key: Key) throws {}
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            guard let definition = encoder.definitionMap[_CodingKey(key)] else {
                fatalError("definitionMap should have '\(key)'")
            }
            let context = SingleValueEncoder(
                codingPath: codingPath + [key], userInfo: encoder.userInfo,
                key: _CodingKey(key), definition: definition, encoder: encoder
            )
            try value.encode(to: context)
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError("unavailable")
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError("unavailable")
        }
        
        func superEncoder() -> Encoder {
            fatalError("unavailable")
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            fatalError("unavailable")
        }
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("unavailable")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("unavailable")
    }
}

internal struct SingleValueEncoder: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let key: _CodingKey
    let definition: Definition
    let encoder: URLEncoder

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        fatalError("unavailable")
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("unavailable")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("unavailable")
    }
}
