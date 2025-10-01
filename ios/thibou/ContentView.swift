import SwiftUI
import UIKit

struct DetailTabActions {
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onShare: () -> Void
}

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var searchText = ""

    var body: some View {
        MainAppView(authManager: authManager, searchText: $searchText)
    }
}

struct MainAppView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var searchText: String
    @State private var showAccountSettings = false
    @State private var showSearchSheet = false
    @State private var selectedTab = "home"
    @State private var libraryCategory: LibraryCategory = .villageois
    @State private var navigationPath = NavigationPath()
    @StateObject private var localizationManager = LocalizationManager.shared

    private var categories: [LibraryCategory] { LibraryCategory.allCases }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                ThibouTheme.Colors.backgroundGradient
                    .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    AuthNavigationBar(authManager: authManager, showAccountSettings: $showAccountSettings)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    TabView(selection: $selectedTab) {
                        Tab(value: "home") {
                            HomeView()
                        } label: {
                            Label(LocalizedKey.home.localized, image: "NavBar/HomeIcon")
                        }

                        Tab(value: "library") {
                            LibraryView(selectedCategory: $libraryCategory)
                        } label: {
                            Label(LocalizedKey.library.localized, image: "NavBar/LibraryIcon")
                        }

                        Tab(value: "tools") {
                            ToolsView()
                        } label: {
                            Label(LocalizedKey.tools.localized, image: "NavBar/ToolsIcon")
                        }

                        Tab(value: "my_island") {
                            IslandView()
                                .environmentObject(authManager)
                        } label: {
                            Label(LocalizedKey.myIsland.localized, image: "NavBar/IslandIcon")
                        }

                        Tab(value: "search", role: .search) {
                            Color.clear
                        }
                    }
                    .onChange(of: selectedTab) { oldTab, newTab in
                        if newTab == "search" {
                            showSearchSheet = true
                            selectedTab = oldTab
                        } else {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                    }
                    .tint(ThibouTheme.Colors.leafGreen)
                    .tabViewBottomAccessory {
                        if selectedTab == "library" {
                            LibraryAccessoryBar(
                                selectedCategory: $libraryCategory,
                                onPrevious: goToPreviousCategory,
                                onNext: goToNextCategory
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAccountSettings) {
                SettingsView(authManager: authManager) {
                    showAccountSettings = false
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchSheet()
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: Villager.self) { villager in
                VillagerDetailView(
                    villager: villager,
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
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToVillagerDetail"))) { notification in
            if let villager = notification.object as? Villager {
                selectedTab = "library"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigationPath.append(villager)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToIslandTab"))) { _ in
            selectedTab = "my_island"
        }
    }

}

struct AuthNavigationBar: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showAccountSettings: Bool
    @Namespace private var accountGlassNamespace

    var body: some View {
        GlassEffectContainer {
        HStack {
            HStack(spacing: 8) {
                Image("TopBar/ThibouLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding(.leading, 4)

                Text("Thibou")
                    .font(ThibouTheme.Typography.title)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAccountSettings = true
            }) {
                HStack(spacing: 8) {
                    Image("TopBar/MarieLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)

                    Text(authManager.isLoggedIn ? (authManager.currentUser?.name ?? LocalizedKey.myAccount.localized) : LocalizedKey.myAccount.localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(authManager.isLoggedIn ? ThibouTheme.Colors.leafGreen : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect()
                .glassEffectID("account_button", in: accountGlassNamespace)
                .clipShape(Circle())
            }
            .buttonStyle(.borderless)
            .hoverEffect(.lift)
            .scaleEffect(1.0)
            .animation(.bouncy(duration: 0.3), value: authManager.isLoggedIn)
        }
        }
    }
}

private struct LibraryAccessoryBar: View {
    @Binding var selectedCategory: LibraryCategory
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        LibraryNavigationBar(
            selectedCategory: $selectedCategory,
            onPrevious: onPrevious,
            onNext: onNext
        )
    }
}
