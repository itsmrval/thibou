import SwiftUI
import UIKit

struct VillagerDetailView: View {
    let villager: Villager
    let allVillagers: [Villager]
    let onToggleFavorite: (Villager) -> Void
    let onShare: (Villager) -> Void

    @State private var currentVillagerIndex: Int
    @State private var isFavorite = false
    @State private var refreshTrigger = 0

    init(villager: Villager, allVillagers: [Villager], onToggleFavorite: @escaping (Villager) -> Void, onShare: @escaping (Villager) -> Void) {
        self.villager = villager

        let groupedVillagers = Dictionary(grouping: allVillagers) { $0.species }
        let sortedSpecies = groupedVillagers.keys.sorted { species1, species2 in
            species1.lowercased() < species2.lowercased()
        }

        var sortedVillagers: [Villager] = []
        for species in sortedSpecies {
            let villagersInSpecies = groupedVillagers[species] ?? []
            let sortedVillagersInSpecies = villagersInSpecies.sorted { v1, v2 in
                v1.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased() < v2.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue).lowercased()
            }
            sortedVillagers.append(contentsOf: sortedVillagersInSpecies)
        }

        self.allVillagers = sortedVillagers
        self.onToggleFavorite = onToggleFavorite
        self.onShare = onShare

        self._currentVillagerIndex = State(initialValue: sortedVillagers.firstIndex(where: { $0.id == villager.id }) ?? 0)
        self._isFavorite = State(initialValue: false)
    }

    private var currentVillager: Villager {
        allVillagers.indices.contains(currentVillagerIndex) ? allVillagers[currentVillagerIndex] : villager
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VillagerDetailContent(villager: currentVillager, refreshTrigger: refreshTrigger)
                    .id(currentVillager.id)
            }
            .refreshable {
                await refreshVillagerDetails()
            }

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFavorite.toggle()
                    }
                    onToggleFavorite(currentVillager)
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
                    onShare(currentVillager)
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
                    VillagerImageView(
                        villagerId: currentVillager.id,
                        imageType: "small",
                        width: 24,
                        height: 24,
                        cornerRadius: 6,
                        placeholderColor: currentVillager.titleColorValue
                    )

                    Text(currentVillager.nameForLanguage(LanguageManager.shared.selectedLanguage.rawValue))
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: previousVillager) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoPrevious)

                Button(action: nextVillager) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoNext)
            }
        }
        .onAppear {
            NotificationCenter.default.post(
                name: Notification.Name("VillagerDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentVillager)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentVillager)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )

            preloadAdjacentImages()
        }
        .onDisappear {
            NotificationCenter.default.post(name: Notification.Name("VillagerDetailDidDisappear"), object: nil)
        }
        .onChange(of: currentVillagerIndex) { _, _ in
            NotificationCenter.default.post(
                name: Notification.Name("VillagerDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentVillager)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentVillager)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )
        }
    }

    private var canGoPrevious: Bool {
        currentVillagerIndex > 0
    }

    private var canGoNext: Bool {
        currentVillagerIndex < allVillagers.count - 1
    }

    private func previousVillager() {
        guard canGoPrevious else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentVillagerIndex -= 1
        }
        preloadAdjacentImages()
    }

    private func nextVillager() {
        guard canGoNext else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentVillagerIndex += 1
        }
        preloadAdjacentImages()
    }

    private func preloadAdjacentImages() {
        Task {
            await VillagerService.shared.fetchVillagerImage(villagerId: currentVillager.id, imageType: "full")
            await VillagerService.shared.fetchVillagerImage(villagerId: currentVillager.id, imageType: "small")

            if currentVillagerIndex + 1 < allVillagers.count {
                let nextVillager = allVillagers[currentVillagerIndex + 1]
                await VillagerService.shared.fetchVillagerImage(villagerId: nextVillager.id, imageType: "full")
                await VillagerService.shared.fetchVillagerImage(villagerId: nextVillager.id, imageType: "small")
            }

            if currentVillagerIndex - 1 >= 0 {
                let prevVillager = allVillagers[currentVillagerIndex - 1]
                await VillagerService.shared.fetchVillagerImage(villagerId: prevVillager.id, imageType: "full")
                await VillagerService.shared.fetchVillagerImage(villagerId: prevVillager.id, imageType: "small")
            }
        }
    }

    private func refreshVillagerDetails() async {
        VillagerService.shared.clearAllCaches()
        refreshTrigger += 1
        preloadAdjacentImages()
    }
}
struct VillagerDetailContent: View {
    let villager: Villager
    let refreshTrigger: Int
    @State private var fullVillager: Villager?
    @State private var isLoadingDetails = false
    @StateObject private var languageManager = LanguageManager.shared

    private var displayVillager: Villager {
        fullVillager ?? villager
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VillagerImageView(
                    villagerId: displayVillager.id,
                    imageType: "full",
                    width: 160,
                    height: 160,
                    cornerRadius: 20,
                    placeholderColor: displayVillager.titleColorValue
                )
                .shadow(
                    color: displayVillager.titleColorValue.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 20) {
                DetailInfoCard(
                    title: LocalizedKey.basicInformation.localized,
                    items: [
                        (LocalizedKey.species.localized, LocalizedKey.speciesName(displayVillager.species)),
                        (LocalizedKey.gender.localized, LocalizedKey.genderName(displayVillager.gender)),
                        (LocalizedKey.personality.localized, displayVillager.displayPersonality),
                        (LocalizedKey.birthday.localized, displayVillager.birthdayDate)
                    ],
                    color: ThibouTheme.Colors.leafGreen
                )

                if let fullVillagerData = fullVillager {
                    let gameInfoItems = [
                        displayVillager.sign != nil ? (LocalizedKey.astrologicalSign.localized, displayVillager.displaySign) : nil,
                        displayVillager.debut != nil ? (LocalizedKey.firstAppearance.localized, displayVillager.displayDebut) : nil,
                        displayVillager.islander != nil ? (LocalizedKey.islander.localized, displayVillager.displayIslander) : nil
                    ].compactMap { $0 }

                    if !gameInfoItems.isEmpty {
                        DetailInfoCard(
                            title: LocalizedKey.gameInformation.localized,
                            items: gameInfoItems,
                            color: ThibouTheme.Colors.skyBlue
                        )
                    }
                }

                if let fullVillagerData = fullVillager {
                    if !fullVillagerData.displayQuote.isEmpty {
                        QuoteCard(
                            quote: fullVillagerData.displayQuote,
                            color: fullVillagerData.titleColorValue
                        )
                    }

                    if let house = fullVillagerData.house {
                        HouseCard(
                            house: house,
                            villagerId: fullVillagerData.id,
                            color: ThibouTheme.Colors.coral
                        )
                    }

                    TranslationsCard(
                        villagerName: fullVillagerData.name,
                        color: ThibouTheme.Colors.lavender
                    )
                } else if isLoadingDetails {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: displayVillager.titleColorValue))
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
            await fetchFullVillagerDetailsIfNeeded()
        }
        .task(id: refreshTrigger) {
            if refreshTrigger > 0 {
                fullVillager = nil
                await fetchFullVillagerDetailsIfNeeded()
            }
        }
    }

    private func fetchFullVillagerDetailsIfNeeded() async {
        guard fullVillager == nil else { return }

        isLoadingDetails = true
        let fetchedVillager = await VillagerService.shared.fetchVillagerById(id: villager.id)
        if let fetchedVillager = fetchedVillager {
            fullVillager = fetchedVillager
        }
        isLoadingDetails = false
    }

}

struct DetailInfoCard: View {
    let title: String
    let items: [(String, String)]
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

                        Text(item.1)
                            .font(ThibouTheme.Typography.boldCallout)
                            .foregroundColor(.primary)
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

struct QuoteCard: View {
    let quote: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedKey.favoriteQuote)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            Text("\"\(quote)\"")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .italic()
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular.tint(color.opacity(0.03)), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct HouseCard: View {
    let house: VillagerHouse
    let villagerId: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizedKey.house)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    HouseImageView(
                        villagerId: villagerId,
                        imageType: "exterior",
                        title: LocalizedKey.exterior.localized,
                        width: 120,
                        height: 90,
                        house: house
                    )

                    HouseImageView(
                        villagerId: villagerId,
                        imageType: "interior",
                        title: LocalizedKey.interior.localized,
                        width: 120,
                        height: 90,
                        house: house
                    )
                }

                VStack(spacing: 12) {
                    if let roof = house.roof {
                        HouseComponentLineView(
                            villagerId: villagerId,
                            imageType: "roof",
                            title: LocalizedKey.roof.localized,
                            description: roof,
                            house: house
                        )
                    }

                    if let siding = house.siding {
                        HouseComponentLineView(
                            villagerId: villagerId,
                            imageType: "siding",
                            title: LocalizedKey.siding.localized,
                            description: siding,
                            house: house
                        )
                    }

                    if let door = house.door {
                        HouseComponentLineView(
                            villagerId: villagerId,
                            imageType: "door",
                            title: LocalizedKey.door.localized,
                            description: door,
                            house: house
                        )
                    }

                    HouseComponentLineView(
                        villagerId: villagerId,
                        imageType: "shape",
                        title: LocalizedKey.shape.localized,
                        description: LocalizedKey.shapeDescription.localized,
                        house: house
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

struct HouseImageView: View {
    let villagerId: String
    let imageType: String
    let title: String
    let width: CGFloat
    let height: CGFloat
    let house: VillagerHouse?

    @State private var showImageModal = false

    var body: some View {
        Button(action: {
            showImageModal = true
        }) {
            VStack(spacing: 8) {
                VillagerImageView(
                    villagerId: villagerId,
                    imageType: imageType,
                    width: width,
                    height: height,
                    cornerRadius: 12,
                    placeholderColor: ThibouTheme.Colors.coral
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThibouTheme.Colors.coral.opacity(0.3), lineWidth: 1)
                )

                Text(title)
                    .font(ThibouTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showImageModal) {
            HouseGalleryModal(
                villagerId: villagerId,
                initialImageType: imageType,
                house: house
            )
        }
    }
}

struct HouseComponentLineView: View {
    let villagerId: String
    let imageType: String
    let title: String
    let description: String
    let house: VillagerHouse?

    var body: some View {
        HStack(spacing: 16) {
            VillagerImageView(
                villagerId: villagerId,
                imageType: imageType,
                width: 60,
                height: 60,
                cornerRadius: 12,
                placeholderColor: ThibouTheme.Colors.coral
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThibouTheme.Colors.coral.opacity(0.3), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ThibouTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThibouTheme.Colors.coral.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct HouseGalleryModal: View {
    let villagerId: String
    let initialImageType: String
    let house: VillagerHouse?

    @Environment(\.dismiss) private var dismiss
    @Namespace private var glassNamespace
    @State private var selectedImageIndex = 0

    private var mainImageTypes: [(type: String, title: String, description: String)] {
        [
            ("exterior", LocalizedKey.exterior.localized, LocalizedKey.exteriorDescription.localized),
            ("interior", LocalizedKey.interior.localized, LocalizedKey.interiorDescription.localized)
        ]
    }
    var body: some View {
        NavigationView {
            GlassEffectContainer {
                VStack(spacing: 0) {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(mainImageTypes.enumerated()), id: \.offset) { index, imageData in
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Text(imageData.title)
                                        .font(ThibouTheme.Typography.largeTitle)
                                        .foregroundColor(.primary)

                                    Text(imageData.description)
                                        .font(ThibouTheme.Typography.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }

                                VillagerImageView(
                                    villagerId: villagerId,
                                    imageType: imageData.type,
                                    width: 280,
                                    height: 280,
                                    cornerRadius: 20,
                                    placeholderColor: ThibouTheme.Colors.coral
                                )
                                .shadow(color: ThibouTheme.Colors.coral.opacity(0.3), radius: 10, x: 0, y: 4)
                            }
                            .padding(.horizontal, 24)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack(spacing: 8) {
                        ForEach(0..<mainImageTypes.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedImageIndex ? ThibouTheme.Colors.coral : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == selectedImageIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: selectedImageIndex)
                        }
                    }
                    .padding(.bottom, 20)
                    .onAppear {
                        if let initialIndex = mainImageTypes.firstIndex(where: { $0.type == initialImageType }) {
                            selectedImageIndex = initialIndex
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.coral)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
    }
}

struct TranslationsCard: View {
    let villagerName: VillagerName
    let color: Color

    private var availableTranslations: [(flag: String, country: String, name: String)] {
        var translations: [(String, String, String)] = []

        translations.append(("🇺🇸", LocalizedKey.english.localized, villagerName.en))

        if let frenchName = villagerName.fr, !frenchName.isEmpty {
            translations.append(("🇫🇷", LocalizedKey.french.localized, frenchName))
        }

        if let spanishName = villagerName.es, !spanishName.isEmpty {
            translations.append(("🇪🇸", LocalizedKey.spanish.localized, spanishName))
        }

        if let germanName = villagerName.de, !germanName.isEmpty {
            translations.append(("🇩🇪", LocalizedKey.german.localized, germanName))
        }

        if let italianName = villagerName.it, !italianName.isEmpty {
            translations.append(("🇮🇹", LocalizedKey.italian.localized, italianName))
        }

        if let japaneseName = villagerName.jp, !japaneseName.isEmpty {
            translations.append(("🇯🇵", LocalizedKey.japanese.localized, japaneseName))
        }

        if let koreanName = villagerName.ko, !koreanName.isEmpty {
            translations.append(("🇰🇷", LocalizedKey.korean.localized, koreanName))
        }

        if let chineseName = villagerName.zh, !chineseName.isEmpty {
            translations.append(("🇨🇳", LocalizedKey.chinese.localized, chineseName))
        }

        if let dutchName = villagerName.nl, !dutchName.isEmpty {
            translations.append(("🇳🇱", LocalizedKey.dutch.localized, dutchName))
        }

        if let russianName = villagerName.ru, !russianName.isEmpty {
            translations.append(("🇷🇺", LocalizedKey.russian.localized, russianName))
        }

        return translations
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedKey.translations)
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
