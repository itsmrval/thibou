import SwiftUI

struct IslandView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLoginSheet = false

    var body: some View {
        NavigationView {
            if authManager.isLoggedIn {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        VStack(spacing: 20) {
                            Image("NavBar/IslandIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)

                            Text(LocalizedKey.myIslandTitle)
                                .font(ThibouTheme.Typography.title)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ThibouTheme.Colors.skyBlue, ThibouTheme.Colors.lavender],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text(LocalizedKey.comingSoon)
                                .font(ThibouTheme.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
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
            } else {
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
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: showLoginSheet)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(LocalizedKey.myIslandTitle.localized)
        .background(ThibouTheme.Colors.backgroundGradient)
        .sheet(isPresented: $showLoginSheet) {
            SettingsView(authManager: authManager) {
                showLoginSheet = false
            }
            .presentationDragIndicator(.visible)
        }
    }
}
