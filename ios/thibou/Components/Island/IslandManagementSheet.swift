import SwiftUI

struct IslandManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var islandService = IslandService.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showAddResident = false

    private var favoriteResidents: [VillagerSummary] {
        islandService.favoriteVillagers
    }

    private var allResidents: [VillagerSummary] {
        islandService.residentVillagers
    }

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                ZStack {
                    ThibouTheme.Colors.backgroundGradient
                        .ignoresSafeArea()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(LocalizedKey.favorites)
                                        .font(ThibouTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("(\(favoriteResidents.count)/3)")
                                        .font(ThibouTheme.Typography.caption)
                                        .foregroundColor(favoriteResidents.count >= 3 ? .orange : .secondary)

                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    ForEach(0..<3) { index in
                                        if index < favoriteResidents.count {
                                            ReadOnlyFavoriteCard(villager: favoriteResidents[index])
                                        } else {
                                            EmptyFavoriteSlot()
                                        }
                                    }
                                }
                                .frame(height: 136)
                            }
                            .padding(.horizontal, 20)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "house.fill")
                                        .foregroundColor(ThibouTheme.Colors.leafGreen)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(LocalizedKey.islandResidents)
                                        .font(ThibouTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("(\(allResidents.count)/10)")
                                        .font(ThibouTheme.Typography.caption)
                                        .foregroundColor(allResidents.count >= 10 ? .orange : .secondary)

                                    Spacer()
                                }

                                if allResidents.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "house")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(.secondary.opacity(0.5))

                                        VStack(spacing: 8) {
                                            Text(LocalizedKey.noResidentsTitle)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(LocalizedKey.noResidentsDescription)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }

                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showAddResident = true
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "plus")
                                                Text(LocalizedKey.addResident)
                                            }
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(ThibouTheme.Colors.leafGreen)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(allResidents) { villager in
                                            ResidentListRow(
                                                villager: villager,
                                                isFavorite: islandService.isFavorite(villager.name.en),
                                                canFavorite: favoriteResidents.count < 3 || islandService.isFavorite(villager.name.en),
                                                onToggleFavorite: {
                                                    Task {
                                                        _ = await islandService.toggleFavorite(villager)
                                                    }
                                                },
                                                onRemove: {
                                                    Task {
                                                        _ = await islandService.removeResident(villager)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            Color.clear.frame(height: 40)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.leafGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(LocalizedKey.manageIsland.localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if allResidents.count < 10 {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showAddResident = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddResident) {
            VillagerSelectionSheet(mode: .residents) { selectedNames in
                Task { @MainActor in
                    var updatedResidents: [IslandResident] = []

                    for name in selectedNames {
                        if let existing = islandService.residents.first(where: { $0.name == name }) {
                            updatedResidents.append(existing)
                        } else {
                            if let villager = VillagerService.shared.villagerSummaries.first(where: { $0.name.en == name }) {
                                updatedResidents.append(IslandResident(id: villager.id, name: name, favorite: false))
                            }
                        }
                    }

                    _ = await islandService.updateResidents(updatedResidents)
                }
            }
            .presentationDragIndicator(.visible)
        }
    }
}

struct ReadOnlyFavoriteCard: View {
    let villager: VillagerSummary
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 8) {
            VillagerImageView(
                villagerId: villager.id,
                imageType: "full",
                width: 80,
                height: 80,
                cornerRadius: 16,
                placeholderColor: villager.titleColorValue
            )
            .shadow(color: villager.titleColorValue.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

struct EmptyFavoriteSlot: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundColor(.yellow.opacity(0.3))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ResidentListRow: View {
    let villager: VillagerSummary
    let isFavorite: Bool
    let canFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRemove: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                VillagerImageView(
                    villagerId: villager.id,
                    imageType: "small",
                    width: 50,
                    height: 50,
                    cornerRadius: 12,
                    placeholderColor: villager.titleColorValue
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(LocalizedKey.speciesName(villager.species))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    if canFavorite {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onToggleFavorite()
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isFavorite ? .yellow : (canFavorite ? .secondary : .gray.opacity(0.4)))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canFavorite)
                .opacity(canFavorite ? 1.0 : 0.5)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onRemove()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

