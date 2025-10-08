import SwiftUI

struct IslandView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var islandService = IslandService.shared
    @State private var showLoginSheet = false
    @State private var showManagementSheet = false
    @State private var showLikeSelection = false
    @State private var selectedVillagerForDetail: VillagerSummary?

    var body: some View {
        NavigationView {
            if authManager.isLoggedIn {
                islandContent
            } else {
                loginPrompt
            }
        }
    }

    private var islandContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        showManagementSheet = true
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                                .font(.system(size: 16))

                            Text(LocalizedKey.islandResidents)
                                .font(ThibouTheme.Typography.headline)
                                .foregroundColor(.primary)

                            Text("(\(islandService.residentVillagers.count)/10)")
                                .font(ThibouTheme.Typography.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                if index < islandService.favoriteVillagers.count {
                                    let villager = islandService.favoriteVillagers[index]
                                    ResidentCard(
                                        state: .villager(villager),
                                        onTap: {
                                            selectedVillagerForDetail = villager
                                        },
                                    )
                                } else if index == islandService.favoriteVillagers.count {
                                    ResidentCard(
                                        state: cardState(for: index),
                                        onTap: { showManagementSheet = true },
                                    )
                                } else {
                                    ResidentCard(
                                        state: .empty,
                                        onTap: { showManagementSheet = true },
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    HStack(spacing: 8) {
                        ForEach(nonFavoriteResidents.prefix(7), id: \.id) { villager in
                            SmallResidentCard(
                                villager: villager,
                                onTap: {
                                    selectedVillagerForDetail = villager
                                },
                            )
                        }

                        ForEach(0..<max(0, 7 - nonFavoriteResidents.count), id: \.self) { _ in
                            SmallResidentCard(
                                villager: nil,
                                onTap: { showManagementSheet = true },
                            )
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                }

                Button(action: {
                    showLikeSelection = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))

                        Text(LocalizedKey.likes)
                            .font(ThibouTheme.Typography.headline)
                            .foregroundColor(.primary)

                        Text("(\(islandService.likeVillagers.count))")
                            .font(ThibouTheme.Typography.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    ThibouTheme.Colors.skyBlue.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .refreshable {
            await islandService.fetchIslandData()
            await islandService.fetchLikes()
        }
        .task {
            if islandService.residentVillagers.isEmpty && islandService.likeVillagers.isEmpty {
                await islandService.fetchIslandData()
                await islandService.fetchLikes()
            }
        }
        .sheet(isPresented: $showManagementSheet) {
            IslandManagementSheet()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLikeSelection) {
            VillagerSelectionSheet(mode: .likes) { _ in }
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedVillagerForDetail) { summary in
            IslandCharacterInfoCard(
                character: summary.toVillager(),
                onViewDetails: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToVillagerDetail"),
                            object: summary.toVillager()
                        )
                    }
                },
                onManageVillagers: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showManagementSheet = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var loginPrompt: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Image("NavBar/IslandIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                Text(LocalizedKey.loginRequired)
                    .font(ThibouTheme.Typography.mediumTitle)
                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                Text(LocalizedKey.loginDescription)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button(action: {
                    showLoginSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text(LocalizedKey.signIn)
                            .font(ThibouTheme.Typography.body)
                    }
                    .foregroundColor(ThibouTheme.Colors.leafGreen)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .stroke(
                                ThibouTheme.Colors.leafGreen.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
        .padding()
        .background(ThibouTheme.Colors.backgroundGradient)
        .sheet(isPresented: $showLoginSheet) {
            SettingsView(authManager: authManager) {
                showLoginSheet = false
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func cardState(for index: Int) -> ResidentCardState {
        if index == islandService.favoriteVillagers.count {
            if islandService.residentVillagers.isEmpty {
                return .emptyWithText
            } else if islandService.favoriteVillagers.isEmpty {
                return .defineFavorite
            }
        }
        return .empty
    }

    private var nonFavoriteResidents: [VillagerSummary] {
        islandService.residentVillagers.filter { !islandService.isFavorite($0.name.en) }
    }
}

