import SwiftUI

struct Shortcuts: View {
    @Namespace private var glassNamespace
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 16) {
                ShortcutCard(
                    imageName: "mermaid_rug",
                    title: LocalizedKey.analyzeArtwork.localized,
                    backgroundColor: ThibouTheme.Colors.skyBlue,
                    glassID: "analyser",
                    namespace: glassNamespace
                )

                ShortcutCard(
                    imageName: "pattern",
                    title: LocalizedKey.viewPatterns.localized,
                    backgroundColor: ThibouTheme.Colors.coral,
                    glassID: "patterns",
                    namespace: glassNamespace
                )
            }
        }
    }
}

struct ShortcutCard: View {
    let imageName: String
    let title: String
    let backgroundColor: Color
    let glassID: String
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .contentTransition(.symbolEffect(.replace))

            Text(title)
                .font(ThibouTheme.Typography.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(8)
                .glassEffect()
                .glassEffectID(glassID + "_text", in: namespace)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}
