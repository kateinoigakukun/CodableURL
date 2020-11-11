# CodableURL

A declarative URL encoder and decoder.

```swift
import CodableURL

struct ListUserRepository: CodableURL {
    @StaticPath var users: Void
    @DynamicPath var userName: String
    @StaticPath var repos: Void
    
    enum `Type`: String {
        case all, owner, member
    }
    @Query var type: Type?
    
    enum Sort: String {
        case created, updated, pushed, fullName = "full_name"
    }
    @Query var sort: Sort?
}

let url = URL(string: "https://api.github.com/users/kateinoigakukun/repos?type=all")!
let decoded: ListUserRepository = try ListUserRepository.decode(url: url)
prnit(decoded) // userName: "kateinoigakukun", type: .all, sort: nil

let encoded: URL = decoded.encode(baseURL: URL(string: "https://api.github.com")!)
print(encoded) // "https://api.github.com/users/kateinoigakukun/repos?type=all"
```
