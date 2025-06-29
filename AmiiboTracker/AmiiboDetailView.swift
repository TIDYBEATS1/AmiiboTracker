import SwiftUI

struct AmiiboDetailView: View {
    let amiibo: Amiibo
    @EnvironmentObject var service: AmiiboService
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: amiibo.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit() // preserves aspect ratio
                            .frame(maxWidth: 160, maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure(_):
                        Color.red.opacity(0.2)
                            .frame(width: 160, height: 160)
                            .overlay(Image(systemName: "xmark.octagon"))
                    default:
                        ProgressView()
                            .frame(width: 160, height: 160)
                    }
                }

                Text("**Name:** \(amiibo.name)")
                Text("**Amiibo Series:** \(amiibo.amiiboSeries)")
                Text("**Game Series:** \(amiibo.gameSeries)")
                Text("**Type:** \(amiibo.type)")
                Text("**Character:** \(amiibo.character)")

                Divider()
                Text("Compatible Games")
                    .font(.title2.bold())

                if let usage = service.usageInfo(for: amiibo) {
                    GameUsageSection(title: "Switch", games: filtered(usage.switchGames))
                    GameUsageSection(title: "3DS", games: filtered(usage.n3ds))
                    GameUsageSection(title: "Wii U", games: filtered(usage.wiiu))
                } else {
                    Text("No usage information available.")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .navigationTitle(amiibo.name)
        .searchable(text: $searchText, prompt: "Search game usage")
    }

    func filtered(_ games: [AmiiboGameUsage]?) -> [AmiiboGameUsage]? {
        guard let games = games else { return nil }
        if searchText.isEmpty { return games }

        return games.compactMap { game in
            let filteredUsage = game.usage.filter { $0.localizedCaseInsensitiveContains(searchText) }
            if game.name.localizedCaseInsensitiveContains(searchText) || !filteredUsage.isEmpty {
                return AmiiboGameUsage(name: game.name, ids: game.ids, usage: filteredUsage)
            }
            return nil
        }
    }
}
struct GameUsageSection: View {
    let title: String
    let games: [AmiiboGameUsage]?

    var platformIcon: String {
        switch title {
        case "Switch": return "gamecontroller.fill"
        case "3DS": return "gamecontroller"
        case "Wii U": return "tv"
        default: return "questionmark.circle"
        }
    }

    var body: some View {
        if let games = games, !games.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: platformIcon)
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.headline)
                }

                ForEach(games, id: \.name) { game in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .bold()
                        ForEach(game.usage, id: \.self) { usageText in
                            Text("• \(usageText)")
                                .font(.subheadline)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.top, 8)
        }
    }
}
