import SwiftUI
import UIKit
import Combine
enum LibraryCategory: String, CaseIterable {
    case villageois = "villagers"
    case poissons = "fish"
    case insectes = "bugs"
    case fossiles = "fossils"

    var localizedName: String {
        switch self {
        case .villageois: return LocalizedKey.villagers.localized
        case .poissons: return LocalizedKey.fish.localized
        case .insectes: return LocalizedKey.bugs.localized
        case .fossiles: return LocalizedKey.fossils.localized
        }
    }

    var customImage: String {
        switch self {
        case .villageois: return "villager"
        case .poissons: return "fish"
        case .insectes: return "bug"
        case .fossiles: return "fossil"
        }
    }
}

struct LibraryTabView: View {
    @Binding var selectedCategory: LibraryCategory
    @StateObject private var villagerService = VillagerService.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var favoriteVillagers: Set<String> = []
    @State private var favoriteFishes: Set<String> = []
    @State private var favoriteBugs: Set<String> = []
    @State private var favoriteFossils: Set<String> = []

    private var categories: [LibraryCategory] { LibraryCategory.allCases }

    private var selectedIndex: Int {
        categories.firstIndex(of: selectedCategory) ?? 0
    }

    var body: some View {
        TabView(selection: Binding(
            get: { selectedIndex },
            set: { newIndex in
                if newIndex >= 0 && newIndex < categories.count {
                    selectedCategory = categories[newIndex]
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
        )) {
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                LibraryContentView(category: category)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ToggleFavoriteVillager"))) { notification in
            if let villager = notification.object as? Villager {
                if favoriteVillagers.contains(villager.id) {
                    favoriteVillagers.remove(villager.id)
                } else {
                    favoriteVillagers.insert(villager.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShareVillager"))) { notification in
            if let villager = notification.object as? Villager {
                shareVillager(villager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ToggleFavoriteFish"))) { notification in
            if let fish = notification.object as? Fish {
                if favoriteFishes.contains(fish.id) {
                    favoriteFishes.remove(fish.id)
                } else {
                    favoriteFishes.insert(fish.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShareFish"))) { notification in
            if let fish = notification.object as? Fish {
                shareFish(fish)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ToggleFavoriteBug"))) { notification in
            if let bug = notification.object as? Bug {
                if favoriteBugs.contains(bug.id) {
                    favoriteBugs.remove(bug.id)
                } else {
                    favoriteBugs.insert(bug.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShareBug"))) { notification in
            if let bug = notification.object as? Bug {
                shareBug(bug)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ToggleFavoriteFossil"))) { notification in
            if let fossil = notification.object as? Fossil {
                if favoriteFossils.contains(fossil.id) {
                    favoriteFossils.remove(fossil.id)
                } else {
                    favoriteFossils.insert(fossil.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShareFossil"))) { notification in
            if let fossil = notification.object as? Fossil {
                shareFossil(fossil)
            }
        }
    }

    private func shareVillager(_ villager: Villager) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let shareText = LocalizedKey.sharingTextTodo.localized
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        window.rootViewController?.present(activityController, animated: true)
    }

    private func shareFish(_ fish: Fish) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let shareText = LocalizedKey.sharingTextTodo.localized
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        window.rootViewController?.present(activityController, animated: true)
    }

    private func shareBug(_ bug: Bug) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let shareText = LocalizedKey.sharingTextTodo.localized
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        window.rootViewController?.present(activityController, animated: true)
    }

    private func shareFossil(_ fossil: Fossil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let shareText = LocalizedKey.sharingTextTodo.localized
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        window.rootViewController?.present(activityController, animated: true)
    }
}
struct LibraryContentView: View {
    let category: LibraryCategory

    var body: some View {
        switch category {
        case .villageois:
            VillagersContentView()
        case .poissons:
            FishContentView()
        case .insectes:
            BugContentView()
        case .fossiles:
            FossilContentView()
        }
    }
}

struct VillagersContentView: View {
    @StateObject private var villagerService = VillagerService.shared
    @State private var expandedSpecies: Set<String> = []
    @State private var currentVisibleSpecies: String? = nil
    @State private var scrollAction: ((String) -> Void)?

    private var groupedVillagers: [(String, [VillagerSummary])] {
        let grouped = Dictionary(grouping: villagerService.villagerSummaries) { $0.species }
        let sortedKeys = grouped.keys.sorted { species1, species2 in
            species1.lowercased() < species2.lowercased()
        }
        return sortedKeys.map { (species: $0, villagers: grouped[$0] ?? []) }
    }

    private var availableSpecies: [String] {
        return groupedVillagers.map { $0.0 }.sorted { $0.lowercased() < $1.lowercased() }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(LocalizedKey.villagers)
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary)

                Text("(\(villagerService.villagerSummaries.count))")
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary.opacity(0.7))

                Spacer()

                Menu {
                    ForEach(availableSpecies, id: \.self) { species in
                        Button(action: {
                            scrollAction?(species)
                        }) {
                            HStack {
                                Text(LocalizedKey.speciesName(species))

                                if currentVisibleSpecies == species {
                                    Spacer()
                                    Image(systemName: "eye.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentVisibleSpecies.map { LocalizedKey.speciesName($0) } ?? LocalizedKey.navigation.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if villagerService.villagerSummaries.isEmpty {
                        VStack(spacing: 16) {
                            if villagerService.isLoading && villagerService.villagerSummaries.isEmpty {
                                ProgressView(LocalizedKey.loadingVillagers.localized)
                                    .foregroundColor(.secondary)
                            } else if let error = villagerService.error {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)

                                    Text(LocalizedKey.errorOccurred)
                                        .font(ThibouTheme.Typography.body)
                                        .foregroundColor(.primary)

                                    Text(error)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                                    Button(LocalizedKey.retry.localized) {
                                        Task { await villagerService.fetchVillagerSummaries() }
                                    }
                                }
                                .padding()
                            } else {
                                Image("villager")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.secondary.opacity(0.6))

                                Text(LocalizedKey.noVillagersFound)
                                    .font(ThibouTheme.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 400)
                        .frame(maxHeight: .infinity)
                    } else {
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
                                                .font(ThibouTheme.Typography.body)
                                                .foregroundColor(.secondary.opacity(0.7))

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.secondary)
                                                .rotationEffect(.degrees(expandedSpecies.contains(species) ? 90 : 0))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            GeometryReader { geometry in
                                                Color.clear
                                                    .onAppear {
                                                        updateVisibleSpecies(for: species, geometry: geometry)
                                                    }
                                                    .onChange(of: geometry.frame(in: .global)) { _, _ in
                                                        updateVisibleSpecies(for: species, geometry: geometry)
                                                    }
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if expandedSpecies.contains(species) {
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 6) {
                                            ForEach(villagers) { villager in
                                                LibraryVillagerCard(villager: villager)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 12)
                                    }
                                }
                                .id(species)
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
                .refreshable {
                    await refreshVillagers()
                }
                .onAppear {
                    scrollAction = { species in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(species, anchor: .top)
                        }
                    }
                }
            }
        }
        .task {
            if villagerService.villagerSummaries.isEmpty {
                await villagerService.fetchVillagerSummaries()
            }
        }
        .onAppear {
            if !groupedVillagers.isEmpty {
                expandedSpecies = Set(groupedVillagers.map(\.0))
            }
        }
        .onChange(of: groupedVillagers.map(\.0)) { _, currentSpecies in
            if !currentSpecies.isEmpty {
                expandedSpecies = Set(currentSpecies)
            }
        }
    }

    private func refreshVillagers() async {
        villagerService.clearAllCaches()
        await villagerService.fetchVillagerSummaries()
    }
    private func updateVisibleSpecies(for species: String, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        let screenHeight = UIScreen.main.bounds.height
        let visibleRange = 100...screenHeight * 0.4

        if visibleRange.contains(frame.midY) {
            DispatchQueue.main.async {
                if currentVisibleSpecies != species {
                    currentVisibleSpecies = species
                }
            }
        }
    }
}


struct LibraryVillagerCard: View {
    let villager: VillagerSummary
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationLink(destination: VillagerDetailView(
            villager: villager.toVillager(),
            allVillagers: VillagerService.shared.villagerSummaries.map { $0.toVillager() },
            onToggleFavorite: { villager in
                NotificationCenter.default.post(
                    name: Notification.Name("ToggleFavoriteVillager"),
                    object: villager
                )
            },
            onShare: { villager in
                NotificationCenter.default.post(
                    name: Notification.Name("ShareVillager"),
                    object: villager
                )
            }
        )) {
            HStack(spacing: 16) {
                VillagerImageView(
                    villagerId: villager.id,
                    imageType: "full",
                    width: 60,
                    height: 60,
                    cornerRadius: 12,
                    placeholderColor: villager.titleColorValue
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(villager.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.boldCallout)
                        .foregroundColor(villager.titleColorValue)
                        .lineLimit(1)

                    Text(LocalizedKey.speciesName(villager.species))
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(ThibouTheme.Colors.leafGreen.opacity(0.8))
                        .lineLimit(1)

                    Text(villager.birthdayDate)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(LocalizedKey.genderName(villager.gender))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: villager.titleColorValue.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

struct FishContentView: View {
    @StateObject private var fishService = FishService.shared
    @State private var expandedLocations: Set<String> = []
    @State private var currentVisibleLocation: String? = nil
    @State private var scrollAction: ((String) -> Void)?

    private var groupedFishes: [(String, [FishSummary])] {
        let grouped = Dictionary(grouping: fishService.fishSummaries) { $0.location }
        let sortedKeys = grouped.keys.sorted { location1, location2 in
            location1.lowercased() < location2.lowercased()
        }
        return sortedKeys.map { location in
            let fishesInLocation = grouped[location] ?? []
            let sortedFishes = fishesInLocation.sorted { fish1, fish2 in
                let rarityOrder = ["common": 0, "uncommon": 1, "rare": 2]
                let rarity1 = rarityOrder[fish1.rarity.lowercased()] ?? 3
                let rarity2 = rarityOrder[fish2.rarity.lowercased()] ?? 3
                if rarity1 != rarity2 {
                    return rarity1 < rarity2
                }
                return fish1.displayName.lowercased() < fish2.displayName.lowercased()
            }
            return (location: location, fishes: sortedFishes)
        }
    }

    private var availableLocations: [String] {
        return groupedFishes.map { $0.0 }.sorted { $0.lowercased() < $1.lowercased() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(LocalizedKey.fish)
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary)

                Text("(\(fishService.fishSummaries.count))")
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary.opacity(0.7))

                Spacer()

                Menu {
                        ForEach(availableLocations, id: \.self) { location in
                            Button(action: {
                                scrollAction?(location)
                            }) {
                                HStack {
                                    Text(LocalizedKey.fishLocation(location))

                                    if currentVisibleLocation == location {
                                        Spacer()
                                        Image(systemName: "eye.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentVisibleLocation.map { LocalizedKey.fishLocation($0) } ?? LocalizedKey.navigation.localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if fishService.fishSummaries.isEmpty {
                            VStack(spacing: 16) {
                                if fishService.isLoading && fishService.fishSummaries.isEmpty {
                                    ProgressView(LocalizedKey.loading.localized)
                                        .foregroundColor(.secondary)
                                } else if let error = fishService.error {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.orange)

                                        Text(LocalizedKey.errorOccurred)
                                            .font(ThibouTheme.Typography.body)
                                            .foregroundColor(.primary)

                                        Text(error)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                                        Button(LocalizedKey.retry.localized) {
                                            Task { await fishService.fetchFishSummaries() }
                                        }
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    Image("fish")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.secondary.opacity(0.6))

                                    Text(LocalizedKey.noFishFound.localized)
                                        .font(ThibouTheme.Typography.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                                    ForEach(groupedFishes, id: \.0) { location, fishes in
                                    VStack(alignment: .leading, spacing: 0) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                if expandedLocations.contains(location) {
                                                    expandedLocations.remove(location)
                                                } else {
                                                    expandedLocations.insert(location)
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Text(LocalizedKey.fishLocation(location))
                                                    .font(ThibouTheme.Typography.subheadline)
                                                    .foregroundColor(.primary)

                                                Text("(\(fishes.count))")
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(.secondary)

                                                Spacer()

                                                Image(systemName: expandedLocations.contains(location) ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                GeometryReader { geometry in
                                                    Color.clear
                                                        .onAppear {
                                                            updateVisibleLocation(for: location, geometry: geometry)
                                                        }
                                                        .onChange(of: geometry.frame(in: .global)) { _, _ in
                                                            updateVisibleLocation(for: location, geometry: geometry)
                                                        }
                                                }
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if expandedLocations.contains(location) {
                                            LazyVGrid(columns: [
                                                GridItem(.flexible()),
                                                GridItem(.flexible())
                                            ], spacing: 6) {
                                                ForEach(fishes) { fish in
                                                    LibraryFishCard(fish: fish)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                        }
                                    }
                                    .id(location)
                                }
                                .padding(.vertical, 16)
                        }
                    }
                }
                .refreshable {
                    await refreshFishSummaries()
                }
                .onAppear {
                    scrollAction = { location in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(location, anchor: .top)
                        }
                    }
                }
            }
        }
        .task {
            if fishService.fishSummaries.isEmpty {
                await fishService.fetchFishSummaries()
            }
        }
        .onAppear {
            if !groupedFishes.isEmpty {
                expandedLocations = Set(groupedFishes.map(\.0))
            }
        }
        .onChange(of: groupedFishes.map(\.0)) { _, currentLocations in
            if !currentLocations.isEmpty {
                expandedLocations = Set(currentLocations)
            }
        }
    }

    private func refreshFishSummaries() async {
        fishService.clearAllCaches()
        await fishService.fetchFishSummaries()
    }

    private func updateVisibleLocation(for location: String, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        let screenHeight = UIScreen.main.bounds.height
        let visibleRange = 100...screenHeight * 0.4

        if visibleRange.contains(frame.midY) {
            DispatchQueue.main.async {
                if currentVisibleLocation != location {
                    currentVisibleLocation = location
                }
            }
        }
    }
}

struct LibraryFishCard: View {
    let fish: FishSummary
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationLink(destination: FishDetailView(
            fish: fish.toFish(),
            allFishes: FishService.shared.fishSummaries.map { $0.toFish() },
            onToggleFavorite: { fish in
                NotificationCenter.default.post(
                    name: Notification.Name("ToggleFavoriteFish"),
                    object: fish
                )
            },
            onShare: { fish in
                NotificationCenter.default.post(
                    name: Notification.Name("ShareFish"),
                    object: fish
                )
            }
        )) {
            HStack(spacing: 16) {
                FishImageView(
                    fishId: fish.id,
                    imageType: "full",
                    width: 60,
                    height: 60,
                    cornerRadius: 12,
                    placeholderColor: fish.titleColorValue
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(fish.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.boldCallout)
                        .foregroundColor(fish.titleColorValue)
                        .lineLimit(1)

                    Text(LocalizedKey.fishLocation(fish.displayLocation))
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(ThibouTheme.Colors.leafGreen.opacity(0.8))
                        .lineLimit(1)

                    Text("\(fish.shopPrice) Bells")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(LocalizedKey.fishRarity(fish.displayRarity))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: fish.titleColorValue.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

struct BugContentView: View {
    @StateObject private var bugService = BugService.shared
    @State private var expandedLocations: Set<String> = []
    @State private var currentVisibleLocation: String? = nil
    @State private var scrollAction: ((String) -> Void)?

    private var groupedBugs: [(String, [BugSummary])] {
        let grouped = Dictionary(grouping: bugService.bugSummaries) { $0.location }
        let sortedKeys = grouped.keys.sorted { location1, location2 in
            location1.lowercased() < location2.lowercased()
        }
        return sortedKeys.map { location in
            let bugsInLocation = grouped[location] ?? []
            let sortedBugs = bugsInLocation.sorted { bug1, bug2 in
                let rarityOrder = ["common": 0, "uncommon": 1, "rare": 2]
                let rarity1 = rarityOrder[bug1.rarity.lowercased()] ?? 3
                let rarity2 = rarityOrder[bug2.rarity.lowercased()] ?? 3
                if rarity1 != rarity2 {
                    return rarity1 < rarity2
                }
                return bug1.displayName.lowercased() < bug2.displayName.lowercased()
            }
            return (location: location, bugs: sortedBugs)
        }
    }

    private var availableLocations: [String] {
        return groupedBugs.map { $0.0 }.sorted { $0.lowercased() < $1.lowercased() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(LocalizedKey.bugs)
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary)

                Text("(\(bugService.bugSummaries.count))")
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary.opacity(0.7))

                Spacer()

                Menu {
                        ForEach(availableLocations, id: \.self) { location in
                            Button(action: {
                                scrollAction?(location)
                            }) {
                                HStack {
                                    Text(LocalizedKey.bugLocation(location))

                                    if currentVisibleLocation == location {
                                        Spacer()
                                        Image(systemName: "eye.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentVisibleLocation.map { LocalizedKey.bugLocation($0) } ?? LocalizedKey.navigation.localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if bugService.bugSummaries.isEmpty {
                            VStack(spacing: 16) {
                                if bugService.isLoading && bugService.bugSummaries.isEmpty {
                                    ProgressView(LocalizedKey.loading.localized)
                                        .foregroundColor(.secondary)
                                } else if let error = bugService.error {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.orange)

                                        Text(LocalizedKey.errorOccurred)
                                            .font(ThibouTheme.Typography.body)
                                            .foregroundColor(.primary)

                                        Text(error)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                                        Button(LocalizedKey.retry.localized) {
                                            Task { await bugService.fetchBugSummaries() }
                                        }
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    Image("bug")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.secondary.opacity(0.6))

                                    Text(LocalizedKey.noBugsFound.localized)
                                        .font(ThibouTheme.Typography.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                                    ForEach(groupedBugs, id: \.0) { location, bugs in
                                    VStack(alignment: .leading, spacing: 0) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                if expandedLocations.contains(location) {
                                                    expandedLocations.remove(location)
                                                } else {
                                                    expandedLocations.insert(location)
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Text(LocalizedKey.bugLocation(location))
                                                    .font(ThibouTheme.Typography.subheadline)
                                                    .foregroundColor(.primary)

                                                Text("(\(bugs.count))")
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(.secondary)

                                                Spacer()

                                                Image(systemName: expandedLocations.contains(location) ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                GeometryReader { geometry in
                                                    Color.clear
                                                        .onAppear {
                                                            updateVisibleLocation(for: location, geometry: geometry)
                                                        }
                                                        .onChange(of: geometry.frame(in: .global)) { _, _ in
                                                            updateVisibleLocation(for: location, geometry: geometry)
                                                        }
                                                }
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if expandedLocations.contains(location) {
                                            LazyVGrid(columns: [
                                                GridItem(.flexible()),
                                                GridItem(.flexible())
                                            ], spacing: 6) {
                                                ForEach(bugs) { bug in
                                                    LibraryBugCard(bug: bug)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                        }
                                    }
                                    .id(location)
                                }
                                .padding(.vertical, 16)
                        }
                    }
                }
                .refreshable {
                    await refreshBugSummaries()
                }
                .onAppear {
                    scrollAction = { location in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(location, anchor: .top)
                        }
                    }
                }
            }
        }
        .task {
            if bugService.bugSummaries.isEmpty {
                await bugService.fetchBugSummaries()
            }
        }
        .onAppear {
            if !groupedBugs.isEmpty {
                expandedLocations = Set(groupedBugs.map(\.0))
            }
        }
        .onChange(of: groupedBugs.map(\.0)) { _, currentLocations in
            if !currentLocations.isEmpty {
                expandedLocations = Set(currentLocations)
            }
        }
    }

    private func refreshBugSummaries() async {
        bugService.clearAllCaches()
        await bugService.fetchBugSummaries()
    }

    private func updateVisibleLocation(for location: String, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        let screenHeight = UIScreen.main.bounds.height
        let visibleRange = 100...screenHeight * 0.4

        if visibleRange.contains(frame.midY) {
            DispatchQueue.main.async {
                if currentVisibleLocation != location {
                    currentVisibleLocation = location
                }
            }
        }
    }
}

struct LibraryBugCard: View {
    let bug: BugSummary
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationLink(destination: BugDetailView(
            bug: bug.toBug(),
            allBugs: BugService.shared.bugSummaries.map { $0.toBug() },
            onToggleFavorite: { bug in
                NotificationCenter.default.post(
                    name: Notification.Name("ToggleFavoriteBug"),
                    object: bug
                )
            },
            onShare: { bug in
                NotificationCenter.default.post(
                    name: Notification.Name("ShareBug"),
                    object: bug
                )
            }
        )) {
            HStack(spacing: 16) {
                BugImageView(
                    bugId: bug.id,
                    imageType: "full",
                    width: 60,
                    height: 60,
                    cornerRadius: 12,
                    placeholderColor: bug.titleColorValue
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(bug.nameForLanguage(languageManager.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.boldCallout)
                        .foregroundColor(bug.titleColorValue)
                        .lineLimit(1)

                    Text(LocalizedKey.bugLocation(bug.displayLocation))
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(ThibouTheme.Colors.leafGreen.opacity(0.8))
                        .lineLimit(1)

                    Text("\(bug.shopPrice) Bells")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(LocalizedKey.bugRarity(bug.displayRarity))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: bug.titleColorValue.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

struct FossilContentView: View {
    @StateObject private var fossilService = FossilService.shared

    private var sortedFossils: [FossilSummary] {
        let grouped = Dictionary(grouping: fossilService.fossilSummaries) { $0.room }
        let sortedRooms = grouped.keys.sorted()

        var result: [FossilSummary] = []
        for room in sortedRooms {
            let fossilsInRoom = grouped[room] ?? []
            let sortedFossilsInRoom = fossilsInRoom.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            result.append(contentsOf: sortedFossilsInRoom)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(LocalizedKey.fossils)
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary)

                Text("(\(fossilService.fossilSummaries.count))")
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary.opacity(0.7))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if fossilService.fossilSummaries.isEmpty {
                        VStack(spacing: 16) {
                            if fossilService.isLoading && fossilService.fossilSummaries.isEmpty {
                                ProgressView(LocalizedKey.loading.localized)
                                    .foregroundColor(.secondary)
                            } else if let error = fossilService.error {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)

                                    Text(LocalizedKey.errorOccurred)
                                        .font(ThibouTheme.Typography.body)
                                        .foregroundColor(.primary)

                                    Text(error)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                                    Button(LocalizedKey.retry.localized) {
                                        Task { await fossilService.fetchFossilSummaries() }
                                    }
                                    .foregroundColor(.blue)
                                }
                            } else {
                                Image("fossil")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.secondary.opacity(0.6))

                                Text(LocalizedKey.noFossilsFound.localized)
                                    .font(ThibouTheme.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 6) {
                            ForEach(sortedFossils) { fossil in
                                LibraryFossilCard(fossil: fossil)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .refreshable {
                await refreshFossilSummaries()
            }
        }
        .task {
            if fossilService.fossilSummaries.isEmpty {
                await fossilService.fetchFossilSummaries()
            }
        }
    }

    private func refreshFossilSummaries() async {
        fossilService.clearAllCaches()
        await fossilService.fetchFossilSummaries()
    }
}

struct LibraryFossilCard: View {
    let fossil: FossilSummary

    var body: some View {
        NavigationLink(destination: FossilDetailView(
            fossil: fossil.toFossil(),
            allFossils: FossilService.shared.fossilSummaries.map { $0.toFossil() },
            onToggleFavorite: { fossil in
                NotificationCenter.default.post(
                    name: Notification.Name("ToggleFavoriteFossil"),
                    object: fossil
                )
            },
            onShare: { fossil in
                NotificationCenter.default.post(
                    name: Notification.Name("ShareFossil"),
                    object: fossil
                )
            }
        )) {
            VStack(alignment: .leading, spacing: 8) {
                Text(fossil.displayName)
                    .font(ThibouTheme.Typography.boldCallout)
                    .foregroundColor(fossil.titleColorValue)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(fossil.parts_count)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            Text(LocalizedKey.parts_count.localized)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("\(fossil.total_price)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            Image("bells_single")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }

                        Text(fossil.displayRoom)
                            .font(ThibouTheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(fossil.titleColorValue.opacity(0.2))
                            )
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(Array(fossil.parts.prefix(2).enumerated()), id: \.offset) { index, part in
                            FossilImageView(
                                fossilId: fossil.id,
                                partName: part.name,
                                width: 40,
                                height: 40,
                                cornerRadius: 8,
                                placeholderColor: fossil.titleColorValue
                            )
                        }

                        if fossil.parts.count > 2 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(fossil.titleColorValue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("+\(fossil.parts.count - 2)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(fossil.titleColorValue)
                                )
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: fossil.titleColorValue.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
