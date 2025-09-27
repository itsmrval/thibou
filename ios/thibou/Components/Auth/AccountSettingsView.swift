import SwiftUI

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
    @State private var showAppleSSO = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @Namespace private var accountGlassNamespace

    var body: some View {
        GlassEffectContainer {
            ZStack {
                ThibouTheme.Colors.backgroundGradient
                    .ignoresSafeArea()

                if !showChangePassword && !showChangeEmail && !showAppleSSO {
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

                                if user.hasPassword == true {
                                    SettingsButton(
                                        title: LocalizedKey.changePassword.localized,
                                        icon: "key",
                                        color: ThibouTheme.Colors.warmYellow
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showChangePassword = true
                                        }
                                    }
                                }

                                if user.hasAppleSSO == true {
                                    SettingsButton(
                                        title: LocalizedKey.unlinkAppleAccount.localized,
                                        icon: "apple.logo",
                                        color: ThibouTheme.Colors.coral
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showAppleSSO = true
                                        }
                                    }
                                } else {
                                    SettingsButton(
                                        title: LocalizedKey.linkAppleAccount.localized,
                                        icon: "apple.logo",
                                        color: .black
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showAppleSSO = true
                                        }
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
                    ChangePasswordContentView(
                        authManager: authManager,
                        onSuccess: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangePassword = false
                            }
                            successMessage = "Password changed successfully"
                        },
                        onBack: {
                            handleBackAction()
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
                } else if showAppleSSO {
                    AppleSSOManagedView(
                        authManager: authManager,
                        isLinking: authManager.currentUser?.hasAppleSSO != true,
                        onSuccess: { message in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAppleSSO = false
                            }
                            successMessage = message
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
                        Image(systemName: showChangePassword || showChangeEmail || showAppleSSO ? "chevron.left" : "xmark")
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
        } else if showAppleSSO {
            withAnimation(.easeInOut(duration: 0.3)) {
                showAppleSSO = false
            }
        } else {
            onDismiss()
        }
    }
}
struct ChangePasswordContentView: View {
    @ObservedObject var authManager: AuthManager
    let onSuccess: () -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedKey.changePasswordTitle)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
                SecureField(LocalizedKey.currentPasswordPlaceholder.localized, text: $currentPassword)
                    .padding()
                    .glassEffect()
                    .glassEffectID("current_password_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField(LocalizedKey.newPasswordPlaceholder.localized, text: $newPassword)
                    .padding()
                    .glassEffect()
                    .glassEffectID("new_password_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField(LocalizedKey.confirmPassword.localized, text: $confirmPassword)
                    .padding()
                    .glassEffect()
                    .glassEffectID("confirm_password_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))

                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.errorMessage = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal)

            Button(action: changePassword) {
                ZStack {
                    Text(LocalizedKey.changePasswordTitle)
                        .font(ThibouTheme.Typography.body)
                        .opacity(isLoading ? 0 : 1)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ThibouTheme.Colors.leafGreen))
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .glassEffect()
                .glassEffectID("change_password_button", in: glassNamespace)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || !isFormValid)
            .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword.count >= 6 &&
               newPassword == confirmPassword
    }

    private func changePassword() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                try await authManager.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct ChangeEmailContentView: View {
    @ObservedObject var authManager: AuthManager
    let onSuccess: () -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var newEmail = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedKey.changeEmailTitle)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
                TextField(LocalizedKey.newEmailPlaceholder.localized, text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .glassEffect()
                    .glassEffectID("new_email_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField(LocalizedKey.currentPassword.localized, text: $password)
                    .padding()
                    .glassEffect()
                    .glassEffectID("email_password_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))

                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.errorMessage = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal)

            Button(action: changeEmail) {
                ZStack {
                    Text(LocalizedKey.changeEmailTitle)
                        .font(ThibouTheme.Typography.body)
                        .opacity(isLoading ? 0 : 1)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ThibouTheme.Colors.leafGreen))
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .glassEffect()
                .glassEffectID("change_email_button", in: glassNamespace)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || !isFormValid)
            .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var isFormValid: Bool {
        return !newEmail.isEmpty && !password.isEmpty && newEmail.contains("@")
    }

    private func changeEmail() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                try await authManager.changeEmail(newEmail: newEmail, password: password)
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct AppleSSOManagedView: View {
    @ObservedObject var authManager: AuthManager
    let isLinking: Bool
    let onSuccess: (String) -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text(isLinking ? "Link Apple Account" : "Unlink Apple Account")
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 20)

            Image(systemName: "apple.logo")
                .font(.system(size: 60))
                .foregroundColor(.black)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ThibouTheme.Colors.leafGreen))
                        .scaleEffect(1.2)

                    Text(LocalizedKey.waitingForApple)
                        .font(ThibouTheme.Typography.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 16) {
                    Text(isLinking ?
                         "Link your Apple ID to your account for easier sign-in." :
                         "This will remove Apple Sign-In from your account. Make sure you have another way to sign in.")
                        .font(ThibouTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                        if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))

                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    self.errorMessage = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }

                    Button(action: performAppleSSO) {
                        Text(isLinking ? "Link Apple Account" : "Unlink Apple Account")
                            .font(ThibouTheme.Typography.body)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(isLinking ? .white : .red)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isLinking ? .black : ThibouTheme.Colors.coral)
                            )
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            if isLinking {
                performAppleSSO()
            }
        }
    }

    private func performAppleSSO() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                if isLinking {
                    try await authManager.linkAppleSSO()
                    await MainActor.run {
                        onSuccess("Apple account linked successfully")
                    }
                } else {
                    try await authManager.unlinkAppleSSO()
                    await MainActor.run {
                        onSuccess("Apple account unlinked successfully")
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                        if let authError = error as? AuthError,
                           case .userCancelled = authError {
                            onBack()
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}
