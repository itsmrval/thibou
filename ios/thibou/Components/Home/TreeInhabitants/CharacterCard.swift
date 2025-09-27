import SwiftUI

enum CharacterCardSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        }
    }
}

struct CharacterCard: View {
    let character: Villager
    let size: CharacterCardSize
    @State private var showInfo = false

    var body: some View {
        Button(action: {
            showInfo.toggle()
        }) {
            VillagerImageView(
                villagerId: character.id,
                imageType: "full",
                width: size.dimension,
                height: size.dimension,
                cornerRadius: 12,
                placeholderColor: character.titleColorValue
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showInfo) {
            CharacterInfoCard(character: character, onViewDetails: {
                showInfo = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: Notification.Name("NavigateToVillagerDetail"),
                        object: character
                    )
                }
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
