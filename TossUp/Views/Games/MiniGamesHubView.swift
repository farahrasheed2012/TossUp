import SwiftUI

struct MiniGamesHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mini-Games")
                        .font(GameFont.title2())
                        .foregroundStyle(AppTheme.primaryText)
                    Text("90-second science resets between drill sessions.")
                        .font(GameFont.body())
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .gameCard()

                ForEach(MiniGameID.allCases) { game in
                    NavigationLink {
                        MiniGameDestinationView(game: game)
                    } label: {
                        MiniGameRow(game: game)
                    }
                    #if os(macOS)
                    .buttonStyle(.borderless)
                    #else
                    .buttonStyle(.plain)
                    #endif
                }
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Games")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Dedicated sidebar / tab root for mini-games.
struct GamesTabView: View {
    var body: some View {
        MiniGamesHubView()
    }
}

/// Routes to a single mini-game view (used by hub links and programmatic navigation).
struct MiniGameDestinationView: View {
    let game: MiniGameID

    var body: some View {
        switch game {
        case .scienceWordle:
            ScienceWordleGameView()
        case .trueOrFalseBlitz:
            TrueOrFalseBlitzGameView()
        case .elementBlitz:
            ElementBlitzGameView()
        case .moleculeMatch:
            MoleculeMatchGameView()
        case .cellBuilder:
            CellBuilderGameView()
        }
    }
}

extension View {
    @ViewBuilder
    func miniGameNavigationDestinations() -> some View {
        navigationDestination(for: MiniGameID.self) { game in
            MiniGameDestinationView(game: game)
        }
    }
}

private struct MiniGameRow: View {
    let game: MiniGameID

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: game.icon)
                .font(.title2)
                .foregroundStyle(gameColor)
                .frame(width: 44, height: 44)
                .background(gameColor.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(GameFont.headline())
                    .foregroundStyle(AppTheme.primaryText)
                Text(game.subtitle)
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(GameFont.caption())
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameCard()
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var gameColor: Color {
        switch game {
        case .scienceWordle: return GameColors.physics
        case .trueOrFalseBlitz: return GameColors.tabAccent
        case .elementBlitz: return GameColors.chemistry
        case .moleculeMatch: return GameColors.biology
        case .cellBuilder: return GameColors.biology
        }
    }
}
