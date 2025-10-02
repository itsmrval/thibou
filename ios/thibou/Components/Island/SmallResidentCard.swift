import SwiftUI

struct SmallResidentCard: View {
    let villager: VillagerSummary?
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack {
                        if let villager = villager {
                            VillagerImageView(
                                villagerId: villager.id,
                                imageType: "small",
                                width: geo.size.width,
                                height: geo.size.height,
                                cornerRadius: 8,
                                placeholderColor: villager.titleColorValue
                            )
                        } else {
                            Color.clear
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Group {
                            if villager == nil {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                        }
                    )
                }
                .aspectRatio(1, contentMode: .fit)

                if let villager = villager {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else {
                    Text(" ")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
