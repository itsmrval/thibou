import SwiftUI

struct HomeView: View {
    @StateObject private var villagerService = VillagerService.shared
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("NavigateToIslandTab"), object: nil)
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                                .font(.system(size: 16))

                            Text(LocalizedKey.myInhabitants)
                                .font(ThibouTheme.Typography.headline)
                                .foregroundColor(.primary)
                        }

                        Text(LocalizedKey.myInhabitantsSubtext)
                            .font(ThibouTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .semibold))
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
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(ThibouTheme.Colors.skyBlue)
                            .font(.system(size: 16))

                        Text(LocalizedKey.shortcuts)
                            .font(ThibouTheme.Typography.headline)
                            .foregroundColor(.primary)
                    }

                    Text(LocalizedKey.shortcutsSubtext)
                        .font(ThibouTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
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
