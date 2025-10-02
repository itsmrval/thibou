import SwiftUI

enum ResidentCardState {
    case empty
    case emptyWithText
    case defineFavorite
    case villager(VillagerSummary)
}

struct ResidentCard: View {
    let state: ResidentCardState
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: onTap) {
            ZStack {
                switch state {
                case .villager(let villager):
                    VStack(spacing: 8) {
                        VillagerImageView(
                            villagerId: villager.id,
                            imageType: "full",
                            width: 90,
                            height: 90,
                            cornerRadius: 12,
                            placeholderColor: villager.titleColorValue
                        )

                        Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                            .font(ThibouTheme.Typography.boldCallout)
                            .foregroundColor(villager.titleColorValue)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)

                case .defineFavorite:
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)

                        Text(LocalizedKey.defineFavorite)
                            .font(ThibouTheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                case .emptyWithText:
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(LocalizedKey.addResident)
                            .font(ThibouTheme.Typography.caption)
                            .foregroundColor(.secondary.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                case .empty:
                    Color.clear
                }
            }
            .frame(width: 110, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: villagerColor.opacity(0.25),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                Group {
                    if !isVillagerState {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var villagerColor: Color {
        if case .villager(let villager) = state {
            return villager.titleColorValue
        }
        return .clear
    }

    private var isVillagerState: Bool {
        if case .villager = state {
            return true
        }
        return false
    }
}
