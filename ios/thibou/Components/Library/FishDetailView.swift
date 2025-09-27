import SwiftUI
import UIKit

struct FishDetailView: View {
    let fish: Fish
    let allFishes: [Fish]
    let onToggleFavorite: (Fish) -> Void
    let onShare: (Fish) -> Void

    @State private var currentFishIndex: Int
    @State private var isFavorite = false
    @State private var refreshTrigger = 0

    init(fish: Fish, allFishes: [Fish], onToggleFavorite: @escaping (Fish) -> Void, onShare: @escaping (Fish) -> Void) {
        self.fish = fish

        let groupedFishes = Dictionary(grouping: allFishes) { $0.location }
        let sortedLocations = groupedFishes.keys.sorted { location1, location2 in
            location1.lowercased() < location2.lowercased()
        }

        var sortedFishes: [Fish] = []
        for location in sortedLocations {
            let fishesInLocation = groupedFishes[location] ?? []
            let sortedFishesInLocation = fishesInLocation.sorted { f1, f2 in
                let rarityOrder = ["common": 0, "uncommon": 1, "rare": 2]
                let rarity1 = rarityOrder[f1.rarity.lowercased()] ?? 3
                let rarity2 = rarityOrder[f2.rarity.lowercased()] ?? 3
                if rarity1 != rarity2 {
                    return rarity1 < rarity2
                }
                return f1.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased() < f2.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased()
            }
            sortedFishes.append(contentsOf: sortedFishesInLocation)
        }

        self.allFishes = sortedFishes
        self.onToggleFavorite = onToggleFavorite
        self.onShare = onShare

        self._currentFishIndex = State(initialValue: sortedFishes.firstIndex(where: { $0.id == fish.id }) ?? 0)
        self._isFavorite = State(initialValue: false)
    }

    private var currentFish: Fish {
        allFishes.indices.contains(currentFishIndex) ? allFishes[currentFishIndex] : fish
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                FishDetailContent(fish: currentFish, refreshTrigger: refreshTrigger)
                    .id(currentFish.id)
            }
            .refreshable {
                await refreshFishDetails()
            }

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFavorite.toggle()
                    }
                    onToggleFavorite(currentFish)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isFavorite ? .red : .primary)
                        .frame(width: 50, height: 50)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .animation(.bouncy(duration: 0.3), value: isFavorite)

                Button(action: {
                    onShare(currentFish)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                Spacer()
            }
            .padding(.leading, 24)
            .padding(.bottom, 0)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    FishImageView(
                        fishId: currentFish.id,
                        imageType: "full",
                        width: 24,
                        height: 24,
                        cornerRadius: 6,
                        placeholderColor: currentFish.titleColorValue
                    )

                    Text(currentFish.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: previousFish) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoPrevious)

                Button(action: nextFish) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoNext)
            }
        }
        .onAppear {
            NotificationCenter.default.post(
                name: Notification.Name("FishDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentFish)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentFish)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )

            preloadAdjacentImages()
        }
        .onDisappear {
            NotificationCenter.default.post(name: Notification.Name("FishDetailDidDisappear"), object: nil)
        }
        .onChange(of: currentFishIndex) { _, _ in
            NotificationCenter.default.post(
                name: Notification.Name("FishDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentFish)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentFish)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )
        }
    }

    private var canGoPrevious: Bool {
        currentFishIndex > 0
    }

    private var canGoNext: Bool {
        currentFishIndex < allFishes.count - 1
    }

    private func previousFish() {
        guard canGoPrevious else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFishIndex -= 1
        }
        preloadAdjacentImages()
    }

    private func nextFish() {
        guard canGoNext else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFishIndex += 1
        }
        preloadAdjacentImages()
    }

    private func preloadAdjacentImages() {
        Task {
            await FishService.shared.fetchFishImage(fishId: currentFish.id, imageType: "full")
            await FishService.shared.fetchFishImage(fishId: currentFish.id, imageType: "small")

            if currentFishIndex + 1 < allFishes.count {
                let nextFish = allFishes[currentFishIndex + 1]
                await FishService.shared.fetchFishImage(fishId: nextFish.id, imageType: "full")
                await FishService.shared.fetchFishImage(fishId: nextFish.id, imageType: "small")
            }

            if currentFishIndex - 1 >= 0 {
                let prevFish = allFishes[currentFishIndex - 1]
                await FishService.shared.fetchFishImage(fishId: prevFish.id, imageType: "full")
                await FishService.shared.fetchFishImage(fishId: prevFish.id, imageType: "small")
            }
        }
    }

    private func refreshFishDetails() async {
        FishService.shared.clearAllCaches()
        refreshTrigger += 1
        preloadAdjacentImages()
    }
}

struct FishDetailContent: View {
    let fish: Fish
    let refreshTrigger: Int
    @State private var fullFish: Fish?
    @State private var isLoadingDetails = false
    @StateObject private var languageManager = LanguageManager.shared

    private var displayFish: Fish {
        fullFish ?? fish
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                FishImageView(
                    fishId: displayFish.id,
                    imageType: "small",
                    width: 160,
                    height: 160,
                    cornerRadius: 20,
                    placeholderColor: displayFish.titleColorValue
                )
                .shadow(
                    color: displayFish.titleColorValue.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 20) {
                FishPriceInfoCard(
                    title: LocalizedKey.fishBasicInformation.localized,
                    items: [
                        (LocalizedKey.location.localized, LocalizedKey.fishLocation(displayFish.location), false, nil),
                        (LocalizedKey.rarity.localized, LocalizedKey.fishRarity(displayFish.rarity), false, nil),
                        (LocalizedKey.shopPrice.localized, "\(displayFish.shopPrice)", true, "bells_single"),
                        (LocalizedKey.cjPrice.localized, "\(displayFish.cjPrice)", true, "bells")
                    ],
                    color: displayFish.titleColorValue
                )

                FishLocationCard(
                    location: displayFish.location,
                    color: ThibouTheme.Colors.leafGreen
                )

                if let fullFishData = fullFish, let availability = fullFishData.availability {
                    FishAvailabilityCard(
                        availability: availability,
                        color: displayFish.titleColorValue
                    )
                }

                if let fullFishData = fullFish {
                    TranslationsFishCard(
                        fishName: fullFishData.name,
                        color: ThibouTheme.Colors.lavender
                    )
                } else if isLoadingDetails {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: displayFish.titleColorValue))
                            .scaleEffect(0.8)
                        Text(LocalizedKey.loading.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 100)
        }
        .task {
            await fetchFullFishDetailsIfNeeded()
        }
        .task(id: refreshTrigger) {
            if refreshTrigger > 0 {
                fullFish = nil
                await fetchFullFishDetailsIfNeeded()
            }
        }
    }

    private func fetchFullFishDetailsIfNeeded() async {
        guard fullFish == nil else { return }

        isLoadingDetails = true
        let fetchedFish = await FishService.shared.fetchFishById(id: fish.id)
        if let fetchedFish = fetchedFish {
            fullFish = fetchedFish
        }
        isLoadingDetails = false
    }
}

struct FishLocationCard: View {
    let location: String
    let color: Color

    private var locationIconName: String {
        switch location.lowercased() {
        case "sea":
            return "FishIcons/sea"
        case "river":
            return "FishIcons/river"
        case "pond":
            return "FishIcons/pond"
        case "pier":
            return "FishIcons/pier"
        default:
            return "FishIcons/sea"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedKey.location.localized)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            HStack(spacing: 16) {
                Image(locationIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedKey.fishLocation(location))
                        .font(ThibouTheme.Typography.subheadline)
                        .foregroundColor(.primary)

                    Text(LocalizedKey.fishLocationDescription(location))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FishAvailabilityCard: View {
    let availability: FishAvailability
    let color: Color
    @State private var selectedHemisphere: Hemisphere = .north

    enum Hemisphere: String, CaseIterable {
        case north = "north"
        case south = "south"

        var localizedName: String {
            switch self {
            case .north: return LocalizedKey.northernHemisphere.localized
            case .south: return LocalizedKey.southernHemisphere.localized
            }
        }

        var icon: String {
            switch self {
            case .north: return "globe.americas"
            case .south: return "globe.asia.australia"
            }
        }
    }

    private var currentAvailability: FishMonthlyAvailability {
        switch selectedHemisphere {
        case .north: return availability.north
        case .south: return availability.south
        }
    }

    private var monthlyData: [(month: String, timeRange: FishTimeRange?)] {
        [
            (LocalizedKey.january.localized, currentAvailability.january),
            (LocalizedKey.february.localized, currentAvailability.february),
            (LocalizedKey.march.localized, currentAvailability.march),
            (LocalizedKey.april.localized, currentAvailability.april),
            (LocalizedKey.may.localized, currentAvailability.may),
            (LocalizedKey.june.localized, currentAvailability.june),
            (LocalizedKey.july.localized, currentAvailability.july),
            (LocalizedKey.august.localized, currentAvailability.august),
            (LocalizedKey.september.localized, currentAvailability.september),
            (LocalizedKey.october.localized, currentAvailability.october),
            (LocalizedKey.november.localized, currentAvailability.november),
            (LocalizedKey.december.localized, currentAvailability.december)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LocalizedKey.availability.localized)
                    .font(ThibouTheme.Typography.headline)
                    .foregroundColor(color)

                Spacer()

                HStack(spacing: 12) {
                    ForEach(Hemisphere.allCases, id: \.self) { hemisphere in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedHemisphere = hemisphere
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: hemisphere.icon)
                                    .font(.system(size: 12, weight: .medium))

                                Text(hemisphere.localizedName)
                                    .font(ThibouTheme.Typography.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedHemisphere == hemisphere ? color.opacity(0.2) : Color.clear)
                            )
                            .foregroundColor(selectedHemisphere == hemisphere ? color : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, data in
                    MonthAvailabilityCard(
                        month: data.month,
                        timeRange: data.timeRange,
                        color: color
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MonthAvailabilityCard: View {
    let month: String
    let timeRange: FishTimeRange?
    let color: Color

    private var timeText: String {
        guard let timeRange = timeRange else {
            return LocalizedKey.notAvailable.localized
        }

        return "\(timeRange.begin):00 - \(timeRange.end):00"
    }

    private var isAvailable: Bool {
        timeRange != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(month)
                .font(ThibouTheme.Typography.boldCallout)
                .foregroundColor(.primary)

            Text(timeText)
                .font(ThibouTheme.Typography.caption)
                .foregroundColor(isAvailable ? color : .secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAvailable ? color.opacity(0.1) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAvailable ? color.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
    }
}

struct TranslationsFishCard: View {
    let fishName: FishName
    let color: Color

    private var availableTranslations: [(flag: String, country: String, name: String)] {
        var translations: [(String, String, String)] = []

        translations.append(("🇺🇸", LocalizedKey.fishLanguageName("english"), fishName.en))

        if let frenchName = fishName.fr, !frenchName.isEmpty {
            translations.append(("🇫🇷", LocalizedKey.fishLanguageName("french"), frenchName))
        }

        if let spanishName = fishName.es, !spanishName.isEmpty {
            translations.append(("🇪🇸", LocalizedKey.fishLanguageName("spanish"), spanishName))
        }

        if let germanName = fishName.de, !germanName.isEmpty {
            translations.append(("🇩🇪", LocalizedKey.fishLanguageName("german"), germanName))
        }

        if let italianName = fishName.it, !italianName.isEmpty {
            translations.append(("🇮🇹", LocalizedKey.fishLanguageName("italian"), italianName))
        }

        if let japaneseName = fishName.jp, !japaneseName.isEmpty {
            translations.append(("🇯🇵", LocalizedKey.fishLanguageName("japanese"), japaneseName))
        }

        if let koreanName = fishName.ko, !koreanName.isEmpty {
            translations.append(("🇰🇷", LocalizedKey.fishLanguageName("korean"), koreanName))
        }

        if let chineseName = fishName.zh, !chineseName.isEmpty {
            translations.append(("🇨🇳", LocalizedKey.fishLanguageName("chinese"), chineseName))
        }

        if let dutchName = fishName.nl, !dutchName.isEmpty {
            translations.append(("🇳🇱", LocalizedKey.fishLanguageName("dutch"), dutchName))
        }

        if let russianName = fishName.ru, !russianName.isEmpty {
            translations.append(("🇷🇺", LocalizedKey.fishLanguageName("russian"), russianName))
        }

        return translations
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedKey.fishTranslations)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(availableTranslations.enumerated()), id: \.offset) { index, translation in
                    HStack(spacing: 12) {
                        Text(translation.flag)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(translation.country)
                                .font(ThibouTheme.Typography.caption)
                                .foregroundColor(.secondary)

                            Text(translation.name)
                                .font(ThibouTheme.Typography.boldCallout)
                                .foregroundColor(.primary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FishPriceInfoCard: View {
    let title: String
    let items: [(String, String, Bool, String?)]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text(item.1)
                                .font(ThibouTheme.Typography.boldCallout)
                                .foregroundColor(.primary)

                            if item.2, let imageName = item.3 {
                                let imageSize = imageName == "bells_single" ? 28.0 : 40.0

                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: imageSize, height: imageSize)

                                if imageName == "bells_single" {
                                    Spacer()
                                        .frame(width: 2)
                                }
                            }
                        }
                    }

                    if index < items.count - 1 {
                        Divider()
                            .opacity(0.3)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
