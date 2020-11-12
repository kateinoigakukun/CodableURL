import XCTest

@testable import CodableURL

final class CodableURLTests: XCTestCase {
    let baseURL = URL(string: "https://example.com")!

    @discardableResult
    func decodePath<T: CodableURL>(_: T.Type, path: [String], query: [String: String] = [:]) throws
        -> T
    {
        return try T.decode(pathComponents: path, queryParameter: { query[$0] })
    }

    func encodePath<T: CodableURL>(_ value: T, base: URL) throws -> URL {
        try value.encode(baseURL: base)
    }

    func testStaticPath() throws {
        struct X1: CodableURL {
            @StaticPath("foo") var foo: Void
        }

        XCTAssertNoThrow(try decodePath(X1.self, path: ["foo"]))
        XCTAssertEqual(try encodePath(X1(), base: baseURL), URL(string: "https://example.com/foo")!)

        struct X2: CodableURL {
            @StaticPath("foo", "bar", "fizz") var foo: Void
        }

        XCTAssertNoThrow(try decodePath(X2.self, path: ["foo", "bar", "fizz"]))
        XCTAssertEqual(
            try encodePath(X2(), base: baseURL), URL(string: "https://example.com/foo/bar/fizz")!)
        XCTAssertThrowsError(try decodePath(X2.self, path: ["foo", "bar"])) { error in
            guard let error = error as? CodingError,
                case let .missingStaticPath(path) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(path, "fizz")
        }

        struct X3: CodableURL {
            @StaticPath("foo") var foo: Void
            @StaticPath("bar") var bar: Void
            @StaticPath("fizz") var fizz: Void
        }
        XCTAssertNoThrow(try decodePath(X3.self, path: ["foo", "bar", "fizz"]))
        XCTAssertEqual(
            try encodePath(X3(), base: baseURL), URL(string: "https://example.com/foo/bar/fizz")!)
    }

    func testDynamicPath() throws {
        struct X1: CodableURL {
            @DynamicPath var bar: String
        }

        var x1 = try decodePath(X1.self, path: ["123"])
        XCTAssertEqual(x1.bar, "123")
        x1 = X1()
        x1.bar = "fizz"
        XCTAssertEqual(try encodePath(x1, base: baseURL), URL(string: "https://example.com/fizz")!)
        XCTAssertThrowsError(try encodePath(X1(), base: baseURL)) { error in
            guard let error = error as? CodingError,
                case let .noValue(key) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(key, "bar")
        }

        struct X2: CodableURL {
            @DynamicPath var bar: Int
        }

        var x2 = try decodePath(X2.self, path: ["123"])
        XCTAssertEqual(x2.bar, 123)
        x2 = X2()
        x2.bar = 321
        XCTAssertEqual(try encodePath(x2, base: baseURL), URL(string: "https://example.com/321")!)
        XCTAssertThrowsError(try decodePath(X2.self, path: ["foo"])) { error in
            guard let error = error as? CodingError,
                case let .invalidDynamicPathValue(value, type, key) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(value, "foo")
            XCTAssertTrue(type == Int.self)
            XCTAssertEqual(key, "bar")
        }

        struct X3: CodableURL {
            @DynamicPath var v1: String
            @DynamicPath var v2: String
        }

        var x3 = try decodePath(X3.self, path: ["foo", "bar"])
        XCTAssertEqual(x3.v1, "foo")
        XCTAssertEqual(x3.v2, "bar")
        x3 = X3()
        x3.v1 = "fizz"
        x3.v2 = "buzz"
        XCTAssertEqual(
            try encodePath(x3, base: baseURL), URL(string: "https://example.com/fizz/buzz")!)
    }

    func testQuery() throws {
        struct X1: CodableURL {
            @Query var bar: String
        }

        var x1 = try decodePath(X1.self, path: [], query: ["bar": "foo"])
        XCTAssertEqual(x1.bar, "foo")
        x1 = X1()
        x1.bar = "fizz"
        XCTAssertEqual(
            try encodePath(x1, base: baseURL), URL(string: "https://example.com?bar=fizz")!)
        XCTAssertThrowsError(try encodePath(X1(), base: baseURL)) { error in
            guard let error = error as? CodingError,
                case let .noValue(key) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(key, "bar")
        }

        struct X2: CodableURL {
            @Query var bar: Int
        }

        var x2 = try decodePath(X2.self, path: [], query: ["bar": "123"])
        XCTAssertEqual(x2.bar, 123)
        x2 = X2()
        x2.bar = 321
        XCTAssertEqual(
            try encodePath(x2, base: baseURL), URL(string: "https://example.com?bar=321")!)
        XCTAssertThrowsError(try decodePath(X2.self, path: [])) { error in
            guard let error = error as? CodingError,
                case let .noValue(key) = error
            else {
                XCTFail()
                return
            }
            XCTAssertEqual(key, "bar")
        }

        struct X3: CodableURL {
            @Query("param1") var bar: Int
        }

        var x3 = try decodePath(X3.self, path: [], query: ["param1": "123"])
        XCTAssertEqual(x3.bar, 123)
        x3 = X3()
        x3.bar = 321
        XCTAssertEqual(
            try encodePath(x3, base: baseURL), URL(string: "https://example.com?param1=321")!)

        struct X4: CodableURL {
            @Query("key") var v1: String
            @Query("key") var v2: String
        }

        var x4 = try decodePath(X4.self, path: [], query: ["key": "xyz"])
        XCTAssertEqual(x4.v1, "xyz")
        XCTAssertEqual(x4.v2, "xyz")
        x4 = X4()
        x4.v1 = "abc"
        x4.v2 = "abc"
        XCTAssertEqual(
            try encodePath(x4, base: baseURL), URL(string: "https://example.com?key=abc")!)

        struct X5: CodableURL {
            @Query("param1", default: 1) var bar: Int
        }

        var x5 = try decodePath(X5.self, path: [])
        XCTAssertEqual(x5.bar, 1)
        x5 = try decodePath(X5.self, path: [], query: ["param1": "2"])
        XCTAssertEqual(x5.bar, 2)
        x5 = X5()
        XCTAssertEqual(
            try encodePath(x5, base: baseURL), URL(string: "https://example.com?param1=1")!)
        x5.bar = 2
        XCTAssertEqual(
            try encodePath(x5, base: baseURL), URL(string: "https://example.com?param1=2")!)
    }

    func testComposition() throws {
        struct X1: CodableURL {
            @StaticPath("foo") var foo: Void
            @DynamicPath var param1: Int
            @Query var param2: String
            @StaticPath("bar") var bar: Void
            @DynamicPath var param3: Int
        }

        let x1 = try decodePath(X1.self, path: ["foo", "1", "bar", "3"], query: ["param2": "2"])
        XCTAssertEqual(x1.param1, 1)
        XCTAssertEqual(x1.param2, "2")
        XCTAssertEqual(x1.param3, 3)
        XCTAssertEqual(
            try encodePath(x1, base: baseURL),
            URL(string: "https://example.com/foo/1/bar/3?param2=2")!)

        struct ListUserRepository: CodableURL {
            @StaticPath var users: Void
            @DynamicPath var userName: String
            @StaticPath var repos: Void

            enum `Type`: String {
                case all, owner, member
            }

            @Query var type: Type?

            enum Sort: String {
                case created, updated, pushed
                case fullName = "full_name"
            }

            @Query var sort: Sort?
        }

        let t1 = try decodePath(
            ListUserRepository.self, path: ["users", "kateinoigakukun", "repos"],
            query: ["type": "all"])
        XCTAssertEqual(t1.userName, "kateinoigakukun")
        guard case .all = t1.type else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            try encodePath(t1, base: baseURL),
            URL(string: "https://example.com/users/kateinoigakukun/repos?type=all")!)
    }
}
