import SwiftUI

struct CharacterInfoCard: View {
    let character: Villager
    let onViewDetails: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Namespace private var glassNamespace
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                GeometryReader { geometry in
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

                                }
                            }

                            Button(action: {
                                dismiss()
                                onViewDetails()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(LocalizedKey.viewMoreDetails)
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
                            .padding(.horizontal, 20)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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

struct InfoCard: View {
    let label: String
    let value: String
    let namespace: Namespace.ID
    let id: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(ThibouTheme.Typography.caption)
                .foregroundColor(ThibouTheme.Colors.leafGreen)

            Text(value)
                .font(ThibouTheme.Typography.boldCallout)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .glassEffect()
        .glassEffectID(id, in: namespace)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
