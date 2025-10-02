import SwiftUI

struct IslandCharacterInfoCard: View {
    let character: Villager
    let onViewDetails: () -> Void
    let onManageVillagers: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                VStack {
                    Spacer()

                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            VillagerImageView(
                                villagerId: character.id,
                                imageType: "full",
                                width: 120,
                                height: 120,
                                cornerRadius: 16,
                                placeholderColor: character.titleColorValue
                            )
                            .shadow(color: character.titleColorValue.opacity(0.3), radius: 10, x: 0, y: 4)

                            VStack(spacing: 8) {
                                Text(character.nameForLanguage(languageManager.selectedLanguage.rawValue))
                                    .font(ThibouTheme.Typography.largeTitle)
                                    .foregroundColor(textColorForBackground(character.titleColorValue))

                                Text(LocalizedKey.speciesName(character.species))
                                    .font(ThibouTheme.Typography.body)
                                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                                if let rank = character.popularityRank, rank != "unranked" {
                                    HStack(spacing: 6) {
                                        Text("★")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(character.popularityRankColor)

                                        Text(rank)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(character.popularityRankColor)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        character.popularityRankColor.opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(character.popularityRankColor.opacity(0.3), lineWidth: 0.5)
                                    )
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            Button(action: {
                                dismiss()
                                onViewDetails()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(LocalizedKey.islandViewMoreDetails)
                                        .font(ThibouTheme.Typography.subheadline)
                                }
                                .foregroundColor(textColorForBackground(character.titleColorValue))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [character.titleColorValue, character.titleColorValue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .shadow(color: character.titleColorValue.opacity(0.4), radius: 8, x: 0, y: 4)

                            Button(action: {
                                dismiss()
                                onManageVillagers()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(LocalizedKey.manageVillager)
                                        .font(ThibouTheme.Typography.subheadline)
                                }
                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ThibouTheme.Colors.leafGreen.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.leafGreen)
                    }
                }
            }
        }
    }

    private func textColorForBackground(_ color: Color) -> Color {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let luminance = (0.299 * red + 0.587 * green + 0.114 * blue)

        return luminance < 0.5 ? .white : .black
    }
}
