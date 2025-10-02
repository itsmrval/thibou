import SwiftUI

enum SelectionMode {
    case residents
    case likes
}

struct VillagerSelectionSheet: View {
    let mode: SelectionMode
    let onConfirm: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var villagerService = VillagerService.shared
    @StateObject private var islandService = IslandService.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var searchText = ""
    @State private var selectedVillagerNames: Set<String> = []
    @State private var expandedSpecies: Set<String> = []

    private var filteredVillagers: [VillagerSummary] {
        guard !searchText.isEmpty else {
            return villagerService.villagerSummaries
        }
        return villagerService.villagerSummaries.filter { villager in
            villager.nameForLanguage(languageManager.selectedLanguage.rawValue)
                .lowercased()
                .contains(searchText.lowercased())
        }
    }

    private var groupedVillagers: [(String, [VillagerSummary])] {
        let grouped = Dictionary(grouping: filteredVillagers) { $0.species }
        let sortedKeys = grouped.keys.sorted { $0.lowercased() < $1.lowercased() }
        return sortedKeys.map { (species: $0, villagers: grouped[$0] ?? []) }
    }

    private var maxCount: Int {
        mode == .residents ? 10 : Int.max
    }

    private var canSelectMore: Bool {
        selectedVillagerNames.count < maxCount
    }

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                VStack(spacing: 0) {
                    HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField(LocalizedKey.searchPlaceholder.localized, text: $searchText)
                    .font(ThibouTheme.Typography.body)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .padding()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedVillagers, id: \.0) { speciesData in
                            let (species, villagers) = speciesData
                            VStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        if expandedSpecies.contains(species) {
                                            expandedSpecies.remove(species)
                                        } else {
                                            expandedSpecies.insert(species)
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text(LocalizedKey.speciesName(species))
                                            .font(ThibouTheme.Typography.body)
                                            .foregroundColor(.primary)

                                        Text("(\(villagers.count))")
                                            .font(ThibouTheme.Typography.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .rotationEffect(.degrees(expandedSpecies.contains(species) ? 90 : 0))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if expandedSpecies.contains(species) {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 8) {
                                        ForEach(villagers) { villager in
                                            SelectableVillagerCard(
                                                villager: villager,
                                                isSelected: selectedVillagerNames.contains(villager.name.en),
                                                canSelect: canSelectMore || selectedVillagerNames.contains(villager.name.en),
                                                mode: mode
                                            ) {
                                                toggleSelection(villager.name.en)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Button(action: {
                    if mode == .likes {
                        Task {
                            let currentLikes = Set(islandService.likeVillagers.map { $0.name.en })
                            let toAdd = selectedVillagerNames.subtracting(currentLikes)
                            let toRemove = currentLikes.subtracting(selectedVillagerNames)

                            for name in toAdd {
                                _ = await islandService.addLike(name)
                            }
                            for name in toRemove {
                                _ = await islandService.removeLike(name)
                            }
                            dismiss()
                        }
                    } else {
                        onConfirm(Array(selectedVillagerNames))
                        dismiss()
                    }
                }) {
                    Text(mode == .residents ? LocalizedKey.updateResidents.localized : LocalizedKey.updateLikes.localized)
                        .font(ThibouTheme.Typography.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ThibouTheme.Colors.leafGreen)
                        )
                }
                .padding()
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
                ToolbarItem(placement: .principal) {
                    Text(LocalizedKey.selectFromAll.localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            expandedSpecies = Set(groupedVillagers.map(\.0))
            if mode == .likes {
                selectedVillagerNames = Set(islandService.likeVillagers.map { $0.name.en })
            } else if mode == .residents {
                selectedVillagerNames = Set(islandService.residentVillagers.map { $0.name.en })
            }
        }
    }

    private func toggleSelection(_ villagerName: String) {
        if selectedVillagerNames.contains(villagerName) {
            selectedVillagerNames.remove(villagerName)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            if canSelectMore {
                selectedVillagerNames.insert(villagerName)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }
}

struct SelectableVillagerCard: View {
    let villager: VillagerSummary
    let isSelected: Bool
    let canSelect: Bool
    let mode: SelectionMode
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                VillagerImageView(
                    villagerId: villager.id,
                    imageType: "full",
                    width: 60,
                    height: 60,
                    cornerRadius: 12,
                    placeholderColor: villager.titleColorValue
                )

                VStack(spacing: 2) {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.boldCallout)
                        .foregroundColor(villager.titleColorValue)
                        .lineLimit(1)

                    Text(LocalizedKey.speciesName(villager.species))
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? villager.titleColorValue.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? villager.titleColorValue : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(!canSelect && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canSelect && !isSelected)
    }
}
