#if canImport(Foundation)
    import Foundation

    enum FoundationURLCodingError: Swift.Error {
        case failedToParseURL(URL)
        case invalidURLComponents(URLComponents)
    }

    extension CodableURL {
        public static func decode(url: Foundation.URL) throws -> Self {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw FoundationURLCodingError.failedToParseURL(url)
            }
            let queryMap = (components.queryItems ?? []).reduce(into: [:]) {
                $0[$1.name] = $1.value
            }
            return try Self.decode(
                pathComponents: Array(url.pathComponents.dropFirst()),
                queryParameter: { key in queryMap[key] })
        }

        public func encode(baseURL: URL) throws -> URL {
            let (pathComponents, queryParameters) = try encode()
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
                throw FoundationURLCodingError.failedToParseURL(baseURL)
            }
            if !pathComponents.isEmpty {
                components.path = "/" + pathComponents.joined(separator: "/")
            }
            if !queryParameters.isEmpty {
                components.queryItems = queryParameters.map {
                    URLQueryItem(name: $0.key, value: $0.value)
                }
            }
            guard let url = components.url else {
                throw FoundationURLCodingError.invalidURLComponents(components)
            }
            return url
        }
    }
#endif
