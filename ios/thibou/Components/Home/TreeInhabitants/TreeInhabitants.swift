import SwiftUI

struct TreeInhabitants: View {
    let characters: [Villager]

    var body: some View {
        ZStack {
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { index in
                    let islandXOffset = getIslandXOffset(for: index)
                    let islandYOffset = getIslandYOffset(for: index)

                    Image("HomeIcons/island\(index + 1)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 100)
                        .opacity(0.6)
                        .offset(x: islandXOffset, y: islandYOffset)
                }
            }
            .offset(y: -30)

            HStack(spacing: 0) {
                ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                    let characterXOffset = getCharacterXOffset(for: index)
                    let characterYOffset = getCharacterYOffset(for: index)

                    CharacterCard(
                        character: character,
                        size: .medium
                    )
                    .offset(x: characterXOffset, y: characterYOffset)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func getIslandXOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return 30
        case 2: return -30
        default: return 0
        }
    }

    private func getIslandYOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return 10
        case 2: return 10
        default: return -10
        }
    }

    private func getCharacterRelativeXOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return -5
        case 1: return 20
        case 2: return 40
        default: return 0
        }
    }

    private func getCharacterRelativeYOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return -50
        case 1: return -50
        case 2: return -50
        default: return 0
        }
    }

    private func getCharacterXOffset(for index: Int) -> CGFloat {
        return getIslandXOffset(for: index) + getCharacterRelativeXOffset(for: index)
    }

    private func getCharacterYOffset(for index: Int) -> CGFloat {
        return getIslandYOffset(for: index) + getCharacterRelativeYOffset(for: index)
    }
}
