import SwiftUI

struct ToolsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                VStack(spacing: 20) {
                    Image("NavBar/ToolsIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    Text(LocalizedKey.toolsTitle)
                        .font(ThibouTheme.Typography.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ThibouTheme.Colors.coral, ThibouTheme.Colors.warmYellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(LocalizedKey.wikiToolsComingSoon)
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
                    ThibouTheme.Colors.coral.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
