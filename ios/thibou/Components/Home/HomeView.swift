import SwiftUI

struct HomeView: View {
    @StateObject private var villagerService = VillagerService.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var blinkOpacity = 1.0

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("NavigateToIslandTab"), object: nil)
            }) {
                HStack {
                    Text(LocalizedKey.myInhabitants)
                        .font(ThibouTheme.Typography.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(ThibouTheme.Colors.skyBlue)
                        .opacity(blinkOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                blinkOpacity = 0.3
                            }
                        }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            if !villagerService.villagerSummaries.isEmpty {
                TreeInhabitants(characters: Array(villagerService.villagerSummaries.map { $0.toVillager() }.shuffled().prefix(3)))
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .padding(.horizontal, 16)
            }

            HStack {
                Text(LocalizedKey.shortcuts)
                    .font(ThibouTheme.Typography.body)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Shortcuts()
                .padding(.bottom, 30)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
            }
        }
        .refreshable {
            await refreshData()
        }
        .padding(.top, 15)
        .background(ThibouTheme.Colors.backgroundGradient)
        .task {
            if villagerService.villagerSummaries.isEmpty {
                await villagerService.fetchVillagerSummaries()
            }
        }
    }

    private func refreshData() async {
        villagerService.clearAllCaches()
        await villagerService.fetchVillagerSummaries()
    }
}
