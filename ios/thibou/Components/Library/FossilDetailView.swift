import SwiftUI
import UIKit

struct FossilDetailView: View {
    let fossil: Fossil
    let allFossils: [Fossil]
    let onToggleFavorite: (Fossil) -> Void
    let onShare: (Fossil) -> Void

    @State private var currentFossilIndex: Int
    @State private var isFavorite = false
    @State private var refreshTrigger = 0

    init(fossil: Fossil, allFossils: [Fossil], onToggleFavorite: @escaping (Fossil) -> Void, onShare: @escaping (Fossil) -> Void) {
        self.fossil = fossil

        let groupedFossils = Dictionary(grouping: allFossils) { $0.room }
        let sortedRooms = groupedFossils.keys.sorted()

        var sortedFossils: [Fossil] = []
        for room in sortedRooms {
            let fossilsInRoom = groupedFossils[room] ?? []
            let sortedFossilsInRoom = fossilsInRoom.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            sortedFossils.append(contentsOf: sortedFossilsInRoom)
        }

        self.allFossils = sortedFossils
        self.onToggleFavorite = onToggleFavorite
        self.onShare = onShare

        self._currentFossilIndex = State(initialValue: sortedFossils.firstIndex(where: { $0.id == fossil.id }) ?? 0)
        self._isFavorite = State(initialValue: false)
    }

    private var currentFossil: Fossil {
        allFossils.indices.contains(currentFossilIndex) ? allFossils[currentFossilIndex] : fossil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                FossilDetailContent(fossil: currentFossil, refreshTrigger: refreshTrigger)
                    .id(currentFossil.id)
            }
            .refreshable {
                await refreshFossilDetails()
            }

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFavorite.toggle()
                    }
                    onToggleFavorite(currentFossil)
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
                    onShare(currentFossil)
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
                    Text(currentFossil.displayName)
                        .font(ThibouTheme.Typography.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: previousFossil) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoPrevious)

                Button(action: nextFossil) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoNext)
            }
        }
        .onAppear {
            NotificationCenter.default.post(
                name: Notification.Name("FossilDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentFossil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentFossil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )

            preloadAdjacentImages()
        }
        .onDisappear {
            NotificationCenter.default.post(name: Notification.Name("FossilDetailDidDisappear"), object: nil)
        }
        .onChange(of: currentFossilIndex) { _, _ in
            NotificationCenter.default.post(
                name: Notification.Name("FossilDetailDidAppear"),
                object: DetailTabActions(
                    isFavorite: isFavorite,
                    onToggleFavorite: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isFavorite.toggle()
                        }
                        onToggleFavorite(currentFossil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    },
                    onShare: {
                        onShare(currentFossil)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            )
        }
    }

    private var canGoPrevious: Bool {
        currentFossilIndex > 0
    }

    private var canGoNext: Bool {
        currentFossilIndex < allFossils.count - 1
    }

    private func previousFossil() {
        guard canGoPrevious else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFossilIndex -= 1
        }
        preloadAdjacentImages()
    }

    private func nextFossil() {
        guard canGoNext else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFossilIndex += 1
        }
        preloadAdjacentImages()
    }

    private func preloadAdjacentImages() {
        Task {
            for part in currentFossil.parts {
                await FossilService.shared.fetchFossilImage(fossilId: currentFossil.id, partName: part.name)
            }

            if currentFossilIndex + 1 < allFossils.count {
                let nextFossil = allFossils[currentFossilIndex + 1]
                for part in nextFossil.parts {
                    await FossilService.shared.fetchFossilImage(fossilId: nextFossil.id, partName: part.name)
                }
            }

            if currentFossilIndex - 1 >= 0 {
                let prevFossil = allFossils[currentFossilIndex - 1]
                for part in prevFossil.parts {
                    await FossilService.shared.fetchFossilImage(fossilId: prevFossil.id, partName: part.name)
                }
            }
        }
    }

    private func refreshFossilDetails() async {
        FossilService.shared.clearAllCaches()
        refreshTrigger += 1
        preloadAdjacentImages()
    }
}

struct FossilDetailContent: View {
    let fossil: Fossil
    let refreshTrigger: Int

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                FossilSetInfoCard(
                    title: LocalizedKey.complete_set_value.localized,
                    items: [
                        (LocalizedKey.museum_room.localized, fossil.displayRoom, false, nil),
                        (LocalizedKey.parts_count.localized, "\(fossil.parts_count)", false, nil),
                        (LocalizedKey.total_value.localized, "\(fossil.total_price)", true, "bells")
                    ],
                    color: fossil.titleColorValue
                )

                FossilPartsCard(
                    fossil: fossil,
                    color: fossil.titleColorValue
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 100)
        }
    }
}

struct FossilSetInfoCard: View {
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
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
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

struct FossilPartsCard: View {
    let fossil: Fossil
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedKey.parts.localized)
                .font(ThibouTheme.Typography.headline)
                .foregroundColor(color)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(fossil.parts.enumerated()), id: \.offset) { index, part in
                    FossilPartCard(
                        fossilId: fossil.id,
                        part: part,
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

struct FossilPartCard: View {
    let fossilId: String
    let part: FossilPart
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            FossilImageView(
                fossilId: fossilId,
                partName: part.name,
                width: 100,
                height: 100,
                cornerRadius: 12,
                placeholderColor: color
            )

            Text(part.full_name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(LocalizedKey.width.localized + ":")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f", part.width))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Text(LocalizedKey.length.localized + ":")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f", part.length))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Text("\(part.sell)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Image("bells_single")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
    }
}
