import Foundation

struct AmiiboGameUsage: Codable, Hashable {
    let name: String
    let ids: [String]?
    let usage: [String]
}

struct AmiiboGamePlatformUsage: Codable, Hashable {
    let n3ds: [AmiiboGameUsage]?
    let wiiu: [AmiiboGameUsage]?
    let switchGames: [AmiiboGameUsage]?

    enum CodingKeys: String, CodingKey {
        case n3ds = "3DS"
        case wiiu = "WiiU"
        case switchGames = "Switch"
    }
}
struct GameUsage: Hashable {
    let name: String
    let usage: [String]
}
struct AmiiboGames: Codable, Hashable {
    let games: AmiiboGamePlatformUsage
}

struct GamesInfoCompact: Codable {
    let amiibos: [String: AmiiboGames]
}
