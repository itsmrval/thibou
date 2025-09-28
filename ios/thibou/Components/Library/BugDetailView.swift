import SwiftUI
import UIKit

struct BugDetailView: View {
    let bug: Bug
    let allBugs: [Bug]
    let onToggleFavorite: (Bug) -> Void
    let onShare: (Bug) -> Void

    @State private var currentBugIndex: Int
    @State private var isFavorite = false
    @State private var refreshTrigger = 0

    init(bug: Bug, allBugs: [Bug], onToggleFavorite: @escaping (Bug) -> Void, onShare: @escaping (Bug) -> Void) {
        self.bug = bug

        let groupedBugs = Dictionary(grouping: allBugs) { $0.location }
        let sortedLocations = groupedBugs.keys.sorted { location1, location2 in
            location1.lowercased() < location2.lowercased()
        }

        var sortedBugs: [Bug] = []
        for location in sortedLocations {
            let bugsInLocation = groupedBugs[location] ?? []
            let sortedBugsInLocation = bugsInLocation.sorted { b1, b2 in
                let rarityOrder = ["very_common": 0, "common": 1, "uncommon": 2, "rare": 3]
                let rarity1 = rarityOrder[b1.rarity.lowercased()] ?? 4
                let rarity2 = rarityOrder[b2.rarity.lowercased()] ?? 4
                if rarity1 != rarity2 {
                    return rarity1 < rarity2
                }
                return b1.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased() < b2.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased()
            }
            sortedBugs.append(contentsOf: sortedBugsInLocation)
        }

        self.allBugs = sortedBugs
        self.onToggleFavorite = onToggleFavorite
        self.onShare = onShare

        self._currentBugIndex = State(initialValue: sortedBugs.firstIndex(where: { $0.id == bug.id }) ?? 0)
        self._isFavorite = State(initialValue: false)
    }

    private var currentBug: Bug {
        allBugs.indices.contains(currentBugIndex) ? allBugs[currentBugIndex] : bug
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                BugDetailContent(bug: currentBug, refreshTrigger: refreshTrigger)
                    .id(currentBug.id)
            }
            .refreshable {
                await refreshBugDetails()
            }

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFavorite.toggle()
                    }
                    onToggleFavorite(currentBug)
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
                    onShare(currentBug)
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
                    BugImageView(
                        bugId: currentBug.id,
                        imageType: "full",
                        width: 24,
                        height: 24,
                        cornerRadius: 6,
                        placeholderColor: currentBug.titleColorValue
                    )

                    Text(currentBug.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: previousBug) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoPrevious)

                Button(action: nextBug) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoNext)
            }
        }
        .onAppear {
            NotificationCenter.default.post(
                name: Notification.Name("BugDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentBug)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentBug)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )

            preloadAdjacentImages()
        }
        .onDisappear {
            NotificationCenter.default.post(name: Notification.Name("BugDetailDidDisappear"), object: nil)
        }
        .onChange(of: currentBugIndex) { _, _ in
            NotificationCenter.default.post(
                name: Notification.Name("BugDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentBug)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentBug)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )
        }
    }

    private var canGoPrevious: Bool {
        currentBugIndex > 0
    }

    private var canGoNext: Bool {
        currentBugIndex < allBugs.count - 1
    }

    private func previousBug() {
        guard canGoPrevious else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentBugIndex -= 1
        }
        preloadAdjacentImages()
    }

    private func nextBug() {
        guard canGoNext else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentBugIndex += 1
        }
        preloadAdjacentImages()
    }

    private func preloadAdjacentImages() {
        Task {
            await BugService.shared.fetchBugImage(bugId: currentBug.id, imageType: "full")
            await BugService.shared.fetchBugImage(bugId: currentBug.id, imageType: "small")

            if currentBugIndex + 1 < allBugs.count {
                let nextBug = allBugs[currentBugIndex + 1]
                await BugService.shared.fetchBugImage(bugId: nextBug.id, imageType: "full")
                await BugService.shared.fetchBugImage(bugId: nextBug.id, imageType: "small")
            }

            if currentBugIndex - 1 >= 0 {
                let prevBug = allBugs[currentBugIndex - 1]
                await BugService.shared.fetchBugImage(bugId: prevBug.id, imageType: "full")
                await BugService.shared.fetchBugImage(bugId: prevBug.id, imageType: "small")
            }
        }
    }

    private func refreshBugDetails() async {
        BugService.shared.clearAllCaches()
        refreshTrigger += 1
        preloadAdjacentImages()
    }
}

struct BugDetailContent: View {
    let bug: Bug
    let refreshTrigger: Int
    @State private var fullBug: Bug?
    @State private var isLoadingDetails = false
    @StateObject private var languageManager = LanguageManager.shared

    private var displayBug: Bug {
        fullBug ?? bug
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                BugImageView(
                    bugId: displayBug.id,
                    imageType: "small",
                    width: 160,
                    height: 160,
                    cornerRadius: 20,
                    placeholderColor: displayBug.titleColorValue
                )
                .shadow(
                    color: displayBug.titleColorValue.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 20) {
                BugPriceInfoCard(
                    title: LocalizedKey.bugBasicInformation.localized,
                    items: [
                        (LocalizedKey.location.localized, LocalizedKey.bugLocation(displayBug.location), false, nil),
                        (LocalizedKey.weather.localized, LocalizedKey.bugWeather(displayBug.weather), false, nil),
                        (LocalizedKey.rarity.localized, LocalizedKey.bugRarity(displayBug.rarity), false, nil),
                        (LocalizedKey.shopPrice.localized, "\(displayBug.shopPrice)", true, "bells_single"),
                        (LocalizedKey.flickPrice.localized, "\(displayBug.flickPrice)", true, "bells")
                    ],
                    color: displayBug.titleColorValue
                )

                BugLocationCard(
                    location: displayBug.location,
                    color: ThibouTheme.Colors.leafGreen
                )

                if let fullBugData = fullBug, let availability = fullBugData.availability {
                    BugAvailabilityCard(
                        availability: availability,
                        color: displayBug.titleColorValue
                    )
                }

                if let fullBugData = fullBug {
                    TranslationsBugCard(
                        bugName: fullBugData.name,
                        color: ThibouTheme.Colors.lavender
                    )
                } else if isLoadingDetails {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: displayBug.titleColorValue))
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
            await fetchFullBugDetailsIfNeeded()
        }
        .task(id: refreshTrigger) {
            if refreshTrigger > 0 {
                fullBug = nil
                await fetchFullBugDetailsIfNeeded()
            }
        }
    }

    private func fetchFullBugDetailsIfNeeded() async {
        guard fullBug == nil else { return }

        isLoadingDetails = true
        let fetchedBug = await BugService.shared.fetchBugById(id: bug.id)
        if let fetchedBug = fetchedBug {
            fullBug = fetchedBug
        }
        isLoadingDetails = false
    }
}

struct BugLocationCard: View {
    let location: String
    let color: Color

    private var locationIconName: String {
        switch location.lowercased() {
        case "trees":
            return "BugIcons/trees"
        case "flowers":
            return "BugIcons/flowers"
        case "ground":
            return "BugIcons/ground"
        case "flying":
            return "BugIcons/flying"
        case "rocks":
            return "BugIcons/rocks"
        case "stumps":
            return "BugIcons/stumps"
        case "water":
            return "BugIcons/water"
        case "special":
            return "BugIcons/special"
        case "villager", "villagers":
            return "BugIcons/villager"
        default:
            return "BugIcons/trees"
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
                    Text(LocalizedKey.bugLocation(location))
                        .font(ThibouTheme.Typography.subheadline)
                        .foregroundColor(.primary)

                    Text(LocalizedKey.bugLocationDescription(location))
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

struct BugAvailabilityCard: View {
    let availability: BugAvailability
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

    private var currentAvailability: BugMonthlyAvailability {
        switch selectedHemisphere {
        case .north: return availability.north
        case .south: return availability.south
        }
    }

    private var monthlyData: [(month: String, timeRange: BugTimeRange?)] {
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
                    MonthBugAvailabilityCard(
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

struct MonthBugAvailabilityCard: View {
    let month: String
    let timeRange: BugTimeRange?
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

struct TranslationsBugCard: View {
    let bugName: BugName
    let color: Color

    private var availableTranslations: [(flag: String, country: String, name: String)] {
        var translations: [(String, String, String)] = []

        translations.append(("🇺🇸", LocalizedKey.bugLanguageName("english"), bugName.en))

        if let frenchName = bugName.fr, !frenchName.isEmpty {
            translations.append(("🇫🇷", LocalizedKey.bugLanguageName("french"), frenchName))
        }

        if let spanishName = bugName.es, !spanishName.isEmpty {
            translations.append(("🇪🇸", LocalizedKey.bugLanguageName("spanish"), spanishName))
        }

        if let germanName = bugName.de, !germanName.isEmpty {
            translations.append(("🇩🇪", LocalizedKey.bugLanguageName("german"), germanName))
        }

        if let italianName = bugName.it, !italianName.isEmpty {
            translations.append(("🇮🇹", LocalizedKey.bugLanguageName("italian"), italianName))
        }

        if let japaneseName = bugName.jp, !japaneseName.isEmpty {
            translations.append(("🇯🇵", LocalizedKey.bugLanguageName("japanese"), japaneseName))
        }

        if let koreanName = bugName.ko, !koreanName.isEmpty {
            translations.append(("🇰🇷", LocalizedKey.bugLanguageName("korean"), koreanName))
        }

        if let chineseName = bugName.zh, !chineseName.isEmpty {
            translations.append(("🇨🇳", LocalizedKey.bugLanguageName("chinese"), chineseName))
        }

        if let dutchName = bugName.nl, !dutchName.isEmpty {
            translations.append(("🇳🇱", LocalizedKey.bugLanguageName("dutch"), dutchName))
        }

        if let russianName = bugName.ru, !russianName.isEmpty {
            translations.append(("🇷🇺", LocalizedKey.bugLanguageName("russian"), russianName))
        }

        return translations
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedKey.bugTranslations.localized)
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

struct BugPriceInfoCard: View {
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