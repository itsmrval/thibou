import SwiftUI
import AuthenticationServices

struct AccountSettingsView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            AccountSettingsContentView(
                authManager: authManager,
                onDismiss: { dismiss() },
                showAsSheet: true
            )
            .navigationTitle(LocalizedKey.account.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct AccountSettingsContentView: View {
    @ObservedObject var authManager: AuthManager
    let onDismiss: () -> Void
    let showAsSheet: Bool

    @State private var showChangePassword = false
    @State private var showChangeEmail = false
    @State private var showRecentAuthSheet = false
    @State private var pendingAction: PendingAction?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    enum PendingAction {
        case linkApple
        case unlinkApple
        case setPassword(String)
    }
    @Namespace private var accountGlassNamespace

    var body: some View {
        return GlassEffectContainer {
            ZStack {
                ThibouTheme.Colors.backgroundGradient
                    .ignoresSafeArea()

                if !showChangePassword && !showChangeEmail {
                    VStack(spacing: 24) {
                        if !showAsSheet {
                            Text(LocalizedKey.account.localized)
                                .font(ThibouTheme.Typography.mediumTitle)
                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                                .padding(.top, 20)
                        }

                        if let user = authManager.currentUser {
                            VStack(spacing: 12) {
                                Image(showAsSheet ? "TopBar/ThibouLogo" : "TopBar/MarieLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                                VStack(spacing: 4) {
                                    Text(user.name)
                                        .font(ThibouTheme.Typography.title)

                                    if let email = user.email {
                                        Text(email)
                                            .font(ThibouTheme.Typography.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.bottom)

                            VStack(spacing: 12) {
                                if user.email != nil {
                                    SettingsButton(
                                        title: LocalizedKey.changeEmail.localized,
                                        icon: "envelope",
                                        color: ThibouTheme.Colors.skyBlue
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showChangeEmail = true
                                        }
                                    }
                                }

                                SettingsButton(
                                    title: LocalizedKey.password.localized,
                                    icon: "key",
                                    color: ThibouTheme.Colors.warmYellow,
                                    subtitle: user.hasPassword == true ?
                                              LocalizedKey.updateMyPassword.localized :
                                              LocalizedKey.definePassword.localized
                                ) {
                                    performDefinePassword()
                                }

                                if user.hasAppleSSO == true {
                                    SettingsButton(
                                        title: LocalizedKey.unlinkAppleAccount.localized,
                                        icon: "apple.logo",
                                        color: ThibouTheme.Colors.coral
                                    ) {
                                        performUnlinkApple()
                                    }
                                } else {
                                    SettingsButton(
                                        title: LocalizedKey.linkAppleAccount.localized,
                                        icon: "apple.logo",
                                        color: .black
                                    ) {
                                        performLinkApple()
                                    }
                                }

                                Divider()
                                    .padding(.vertical)

                                SettingsButton(
                                    title: LocalizedKey.signOut.localized,
                                    icon: "arrow.right.square",
                                    color: .red
                                ) {
                                    authManager.signOut()
                                    onDismiss()
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .padding()
                } else if showChangePassword {
                    SetPasswordContentView(
                        authManager: authManager,
                        isSettingNew: authManager.currentUser?.hasPassword != true,
                        onSuccess: { message in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangePassword = false
                            }
                            successMessage = message
                        },
                        onBack: {
                            handleBackAction()
                        },
                        onRecentAuthRequired: { newPassword in
                            pendingAction = .setPassword(newPassword)
                            showRecentAuthSheet = true
                        },
                        glassNamespace: accountGlassNamespace
                    )
                } else if showChangeEmail {
                    ChangeEmailContentView(
                        authManager: authManager,
                        onSuccess: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangeEmail = false
                            }
                            successMessage = "Email changed successfully"
                        },
                        onBack: {
                            handleBackAction()
                        },
                        glassNamespace: accountGlassNamespace
                    )
                }

                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThibouTheme.Colors.leafGreen))
                        .scaleEffect(1.5)
                }
            }
        }
        .toolbar {
            if showAsSheet {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        handleBackAction()
                    }) {
                        Image(systemName: showChangePassword || showChangeEmail ? "chevron.left" : "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.leafGreen)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        }
        .alert("Success", isPresented: .constant(successMessage != nil)) {
            Button("OK") {
                successMessage = nil
            }
        } message: {
            Text(successMessage ?? "")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showRecentAuthSheet) {
            RecentAuthSheet(
                authManager: authManager,
                onDismiss: {
                    showRecentAuthSheet = false
                    pendingAction = nil
                },
                onAuthSuccess: {
                    showRecentAuthSheet = false
                    if let action = pendingAction {
                        executePendingAction(action)
                    }
                    pendingAction = nil
                }
            )
        }
    }

    private func handleBackAction() {
        if showChangePassword {
            withAnimation(.easeInOut(duration: 0.3)) {
                showChangePassword = false
            }
        } else if showChangeEmail {
            withAnimation(.easeInOut(duration: 0.3)) {
                showChangeEmail = false
            }
        } else {
            onDismiss()
        }
    }

    private func performLinkApple() {
        Task {
            do {
                try await authManager.linkAppleSSO()
                await MainActor.run {
                    successMessage = LocalizedKey.appleAccountLinkedSuccessfully.localized
                }
            } catch {
                await MainActor.run {
                    if extractRecentAuthError(from: error) != nil {
                        pendingAction = .linkApple
                        showRecentAuthSheet = true
                    } else {
                        if let authError = error as? AuthError {
                            self.errorMessage = authError.userFriendlyMessage
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func performUnlinkApple() {
        Task {
            do {
                try await authManager.unlinkAppleSSO()
                await MainActor.run {
                    successMessage = LocalizedKey.appleAccountUnlinkedSuccessfully.localized
                }
            } catch {
                await MainActor.run {
                    if extractRecentAuthError(from: error) != nil {
                        pendingAction = .unlinkApple
                        showRecentAuthSheet = true
                    } else {
                        if let authError = error as? AuthError {
                            self.errorMessage = authError.userFriendlyMessage
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func performDefinePassword() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showChangePassword = true
        }
    }

    private func executePendingAction(_ action: PendingAction) {
        switch action {
        case .linkApple:
            performLinkApple()
        case .unlinkApple:
            performUnlinkApple()
        case .setPassword(let newPassword):
            performSetPassword(newPassword)
        }
    }

    private func performSetPassword(_ newPassword: String) {
        Task {
            do {
                try await authManager.setPassword(newPassword)
                await MainActor.run {
                    let isNew = authManager.currentUser?.hasPassword != true
                    successMessage = isNew ? LocalizedKey.passwordDefinedSuccessfully.localized : LocalizedKey.passwordUpdatedSuccessfully.localized
                }
            } catch {
                await MainActor.run {
                    if extractRecentAuthError(from: error) != nil {
                        pendingAction = .setPassword(newPassword)
                        showRecentAuthSheet = true
                    } else {
                        if let authError = error as? AuthError {
                            self.errorMessage = authError.userFriendlyMessage
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func extractRecentAuthError(from error: Error) -> String? {
        if error is RecentAuthRequiredError {
            return "Recent authentication required"
        }
        if let apiError = error as? APIError,
           case .serverError(let message) = apiError,
           message.contains("requiresRecentAuth") || message.contains("Token is too old") {
            return message
        }
        return nil
    }
}