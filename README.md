# CodableURL

A declarative URL encoder and decoder.

```swift
import CodableURL

struct ListUserRepository: CodableURL {
    @StaticPath  var users: Void
    @DynamicPath var userName: String
    @StaticPath  var repos: Void
    
    enum Kind: String, ExpressibleByURLComponent {
        case all, owner, member
    }
    @Query("type") var kind: Kind?
    
    enum Sort: String, ExpressibleByURLComponent {
        case created, updated, pushed, fullName = "full_name"
    }
    @Query var sort: Sort?
    
    enum Direction: String, ExpressibleByURLComponent {
        case asc, desc
    }
    @Query(default: .asc) var direction: Direction
}

let url = URL(string: "https://api.github.com/users/kateinoigakukun/repos?type=all")!
let decoded: ListUserRepository = try ListUserRepository.decode(url: url)
print(decoded) // ListUserRepository(userName: "kateinoigakukun", type: .all, sort: nil, direction: .asc)

let encoded: URL = try decoded.encode(baseURL: URL(string: "https://api.github.com")!)
print(encoded) // "https://api.github.com/users/kateinoigakukun/repos?type=all&direction=asc"

```
