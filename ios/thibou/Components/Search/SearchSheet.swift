import SwiftUI

struct SearchSheet: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    @StateObject private var villagerService = VillagerService.shared
    @StateObject private var fishService = FishService.shared
    @State private var searchResults: SearchResults = SearchResults()
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var suggestedVillagers: [VillagerSummary] = []
    @State private var suggestedFish: [FishSummary] = []

    @State private var selectedVillager: VillagerSummary?
    @State private var showVillagerDetail = false

    @State private var selectedFish: FishSummary?
    @State private var showFishDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    if searchText.isEmpty {
                        SuggestionsView(
                            suggestedVillagers: suggestedVillagers,
                            suggestedFish: suggestedFish,
                            onVillagerTap: { villager in
                                selectedVillager = villager
                                showVillagerDetail = true
                            },
                            onFishTap: { fish in
                                selectedFish = fish
                                showFishDetail = true
                            }
                        )
                        .padding(.top, 20)
                    } else {
                        SearchResultsView(
                            searchResults: searchResults,
                            isSearching: isSearching,
                            onVillagerTap: { villager in
                                selectedVillager = villager
                                showVillagerDetail = true
                            },
                            onFishTap: { fish in
                                selectedFish = fish
                                showFishDetail = true
                            }
                        )
                        .padding(.top, 20)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 17, weight: .medium))

                            TextField(LocalizedKey.searchPlaceholder.localized, text: $searchText)
                                .focused($isSearchFocused)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .onChange(of: searchText) { _, newValue in
                                    performSearch(query: newValue)
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    searchText = ""
                                    searchResults = SearchResults()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 17))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 25)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(
                            .ultraThinMaterial,
                            in: Circle()
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle(LocalizedKey.search.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showVillagerDetail) {
            if let villager = selectedVillager {
                let allSearchVillagers = searchText.isEmpty ?
                    suggestedVillagers.map { $0.toVillager() } :
                    searchResults.villagers.map { $0.toVillager() }

                NavigationStack {
                    VillagerDetailView(
                        villager: villager.toVillager(),
                        allVillagers: allSearchVillagers,
                        onToggleFavorite: { _ in },
                        onShare: { _ in }
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showVillagerDetail = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showFishDetail) {
            if let fish = selectedFish {
                let allSearchFish = searchText.isEmpty ?
                    suggestedFish.map { $0.toFish() } :
                    searchResults.fish.map { $0.toFish() }

                NavigationStack {
                    FishDetailView(
                        fish: fish.toFish(),
                        allFishes: allSearchFish,
                        onToggleFavorite: { _ in },
                        onShare: { _ in }
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showFishDetail = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            loadSuggestions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func loadSuggestions() {
        Task {
            if villagerService.villagerSummaries.isEmpty {
                await villagerService.fetchVillagerSummaries()
            }

            if fishService.fishSummaries.isEmpty {
                await fishService.fetchFishSummaries()
            }

            await MainActor.run {
                suggestedVillagers = Array(villagerService.villagerSummaries.shuffled().prefix(3))
                suggestedFish = Array(fishService.fishSummaries.shuffled().prefix(4))
            }
        }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()

        if query.isEmpty {
            searchResults = SearchResults()
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            let currentLanguage = await LanguageManager.shared.selectedLanguage.rawValue

            let villagerResults = villagerService.villagerSummaries.filter { villager in
                villager.nameForLanguage(currentLanguage).localizedCaseInsensitiveContains(query) ||
                villager.species.localizedCaseInsensitiveContains(query) ||
                (villager.personality?.localizedCaseInsensitiveContains(query) ?? false)
            }

            let fishResults = fishService.fishSummaries.filter { fish in
                fish.nameForLanguage(currentLanguage).localizedCaseInsensitiveContains(query) ||
                fish.location.localizedCaseInsensitiveContains(query) ||
                fish.rarity.localizedCaseInsensitiveContains(query)
            }

            await MainActor.run {
                if !Task.isCancelled {
                    searchResults = SearchResults(
                        villagers: Array(villagerResults.prefix(4)),
                        fish: Array(fishResults.prefix(4))
                    )
                    isSearching = false
                }
            }
        }
    }
}

struct SearchResults {
    var villagers: [VillagerSummary] = []
    var fish: [FishSummary] = []

    var isEmpty: Bool {
        villagers.isEmpty && fish.isEmpty
    }
}

struct SuggestionsView: View {
    let suggestedVillagers: [VillagerSummary]
    let suggestedFish: [FishSummary]
    let onVillagerTap: (VillagerSummary) -> Void
    let onFishTap: (FishSummary) -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !suggestedVillagers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 12) {
                            ForEach(Array(suggestedVillagers.prefix(3))) { villager in
                                VillagerSuggestionCard(villager: villager) {
                                    onVillagerTap(villager)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if !suggestedFish.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 12) {
                            ForEach(Array(suggestedFish.prefix(4))) { fish in
                                FishSuggestionCard(fish: fish) {
                                    onFishTap(fish)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Color.clear.frame(height: 120)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }
}

struct SearchResultsView: View {
    let searchResults: SearchResults
    let isSearching: Bool
    let onVillagerTap: (VillagerSummary) -> Void
    let onFishTap: (FishSummary) -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .scaleEffect(0.8)
                        Text(LocalizedKey.searching.localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        LocalizedKey.noResultsFound.localized,
                        systemImage: "magnifyingglass",
                        description: Text(LocalizedKey.noResultsDescription.localized)
                    )
                    .padding(.top, 40)
                } else {
                    if !searchResults.villagers.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedKey.villagers.localized)
                                .font(ThibouTheme.Typography.title)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)

                            LazyVStack(spacing: 12) {
                                ForEach(searchResults.villagers) { villager in
                                    VillagerSearchCard(villager: villager) {
                                        onVillagerTap(villager)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if !searchResults.fish.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedKey.fish.localized)
                                .font(ThibouTheme.Typography.title)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)

                            LazyVStack(spacing: 12) {
                                ForEach(searchResults.fish) { fish in
                                    FishSearchCard(fish: fish) {
                                        onFishTap(fish)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Color.clear.frame(height: 120)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }
}

struct VillagerSearchCard: View {
    let villager: VillagerSummary
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                VillagerImageView(
                    villagerId: villager.id,
                    imageType: "full",
                    width: 70,
                    height: 70,
                    cornerRadius: 18,
                    placeholderColor: villager.titleColorValue
                )
                .shadow(color: villager.titleColorValue.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Text(LocalizedKey.speciesName(villager.species))
                            .font(ThibouTheme.Typography.callout)
                            .foregroundColor(.secondary)

                        if let personality = villager.personality {
                            Text("•")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(personality)
                                .font(ThibouTheme.Typography.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(16)
            .background(.regularMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FishSearchCard: View {
    let fish: FishSummary
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                FishImageView(
                    fishId: fish.id,
                    imageType: "full",
                    width: 70,
                    height: 70,
                    cornerRadius: 18,
                    placeholderColor: fish.titleColorValue
                )
                .shadow(color: fish.titleColorValue.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(fish.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Text(LocalizedKey.fishLocation(fish.location))
                            .font(ThibouTheme.Typography.callout)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 3) {
                            Text("\(fish.shopPrice)")
                                .font(ThibouTheme.Typography.callout)
                                .foregroundColor(.green)

                            Image("bells_single")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(16)
            .background(.regularMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VillagerSuggestionCard: View {
    let villager: VillagerSummary
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(spacing: 12) {
                VillagerImageView(
                    villagerId: villager.id,
                    imageType: "full",
                    width: 60,
                    height: 60,
                    cornerRadius: 16,
                    placeholderColor: villager.titleColorValue
                )
                .shadow(color: villager.titleColorValue.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(spacing: 3) {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.boldCallout)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(LocalizedKey.speciesName(villager.species))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FishSuggestionCard: View {
    let fish: FishSummary
    let onTap: () -> Void

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                FishImageView(
                    fishId: fish.id,
                    imageType: "full",
                    width: 50,
                    height: 50,
                    cornerRadius: 12,
                    placeholderColor: fish.titleColorValue
                )
                .shadow(color: fish.titleColorValue.opacity(0.2), radius: 6, x: 0, y: 3)

                VStack(spacing: 2) {
                    Text(fish.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 2) {
                        Text("\(fish.shopPrice)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.green)

                        Image("bells_single")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
