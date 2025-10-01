import SwiftUI
import AuthenticationServices
import Combine

struct SettingsView: View {
    @ObservedObject var authManager: AuthManager
    let onDismiss: () -> Void

    @State private var showEmailLogin = false
    @State private var showLanguageSelector = false
    @State private var showAccountSection = false
    @State private var showChangePassword = false
    @State private var showChangeEmail = false
    @State private var showChangeUsername = false
    @State private var showRecentAuthSheet = false
    @State private var pendingAction: PendingAction?
    @State private var isAppleSignInLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    enum PendingAction {
        case linkApple
        case unlinkApple
        case setPassword(String)
        case definePassword
    }
    @StateObject private var languageManager = LanguageManager.shared
    @Namespace private var settingsGlassNamespace

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                ZStack {
                    ThibouTheme.Colors.backgroundGradient
                        .ignoresSafeArea()

                    if !showEmailLogin && !showLanguageSelector && !showAccountSection && !showChangePassword && !showChangeEmail && !showChangeUsername {
                        VStack(spacing: 0) {
                            VStack(spacing: 12) {
                                Image("TopBar/MarieLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                                Text(LocalizedKey.parameters)
                                    .font(ThibouTheme.Typography.mediumTitle)
                                    .foregroundColor(ThibouTheme.Colors.leafGreen)

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
                                    .padding(.horizontal, 24)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.8).combined(with: .opacity)
                                    ))
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 32)

                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 24) {
                                    VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text(LocalizedKey.general)
                                            .font(ThibouTheme.Typography.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }

                                    SettingsButton(
                                        title: LocalizedKey.language.localized,
                                        icon: "globe",
                                        color: ThibouTheme.Colors.skyBlue,
                                        subtitle: languageManager.selectedLanguage.flag + " " + languageManager.selectedLanguage.displayName
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showLanguageSelector = true
                                        }
                                    }
                                }

                                    VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text(LocalizedKey.account)
                                            .font(ThibouTheme.Typography.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }

                                    if authManager.isLoggedIn {
                                        if let user = authManager.currentUser {
                                            VStack(spacing: 12) {
                                                SettingsButton(
                                                    title: LocalizedKey.username.localized,
                                                    icon: "person",
                                                    color: ThibouTheme.Colors.leafGreen,
                                                    subtitle: user.name
                                                ) {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showChangeUsername = true
                                                    }
                                                }

                                                if user.email != nil {
                                                    SettingsButton(
                                                        title: LocalizedKey.emailAddress.localized,
                                                        icon: "envelope",
                                                        color: ThibouTheme.Colors.skyBlue,
                                                        subtitle: user.email
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
                                                    pendingAction = .definePassword
                                                    showRecentAuthSheet = true
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

                                                SettingsButton(
                                                    title: LocalizedKey.signOut.localized,
                                                    icon: "arrow.right.square",
                                                    color: .red
                                                ) {
                                                    authManager.signOut()
                                                    onDismiss()
                                                }
                                            }
                                        }
                                    } else {
                                        VStack(spacing: 12) {
                                            ZStack {
                                                SignInWithAppleButton(
                                                    onRequest: { request in
                                                        request.requestedScopes = [.fullName, .email]
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            isAppleSignInLoading = true
                                                            errorMessage = nil
                                                        }
                                                    },
                                                    onCompletion: { result in
                                                        handleAppleSignIn(result)
                                                    }
                                                )
                                                .signInWithAppleButtonStyle(.black)
                                                .frame(height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .disabled(isAppleSignInLoading)
                                                .opacity(isAppleSignInLoading ? 0.6 : 1.0)

                                                if isAppleSignInLoading {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        .scaleEffect(0.8)
                                                }
                                            }
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    showEmailLogin = true
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "envelope.fill")
                                                    Text(LocalizedKey.signInWithEmail)
                                                        .font(ThibouTheme.Typography.body)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 50)
                                                .foregroundColor(ThibouTheme.Colors.leafGreen)
                                                            .glassEffect()
                                                .glassEffectID("email_login", in: settingsGlassNamespace)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 60)
                            }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Thibou")
                                .font(ThibouTheme.Typography.subheadline)
                                .foregroundColor(.primary)

                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                Text("\(LocalizedKey.version.localized) \(version) (\(build))")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(LocalizedKey.version.localized) 1.0")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 20)
                        }
                    } else if showLanguageSelector {
                        LanguageSelectorView(
                            languageManager: languageManager,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showLanguageSelector = false
                                }
                            },
                            glassNamespace: settingsGlassNamespace
                        )
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
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showChangePassword = false
                                }
                            },
                            onRecentAuthRequired: { newPassword in
                                pendingAction = .setPassword(newPassword)
                                showRecentAuthSheet = true
                            },
                            glassNamespace: settingsGlassNamespace
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
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showChangeEmail = false
                                }
                            },
                            glassNamespace: settingsGlassNamespace
                        )
                    } else if showChangeUsername {
                        ChangeUsernameContentView(
                            authManager: authManager,
                            onSuccess: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showChangeUsername = false
                                }
                                successMessage = "Username changed successfully"
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showChangeUsername = false
                                }
                            },
                            glassNamespace: settingsGlassNamespace
                        )
                    } else if showAccountSection {
                        AccountSectionView(
                            authManager: authManager,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAccountSection = false
                                }
                            }
                        )
                    } else if showEmailLogin {
                        EmailLoginContentView(
                            authManager: authManager,
                            onSuccess: onDismiss,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailLogin = false
                                }
                            },
                            glassNamespace: settingsGlassNamespace
                        )
                    }

                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if showEmailLogin {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmailLogin = false
                            }
                        } else if showLanguageSelector {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLanguageSelector = false
                            }
                        } else if showChangePassword {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangePassword = false
                            }
                        } else if showChangeEmail {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangeEmail = false
                            }
                        } else if showChangeUsername {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showChangeUsername = false
                            }
                        } else if showAccountSection {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAccountSection = false
                            }
                        } else {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: (showEmailLogin || showLanguageSelector || showAccountSection || showChangePassword || showChangeEmail || showChangeUsername) ? "chevron.left" : "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.leafGreen)
                            .contentTransition(.symbolEffect(.replace))
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

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                switch result {
                case .success(let authorization):
                    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        throw AuthError.invalidCredentials
                    }

                    guard let identityTokenData = appleIDCredential.identityToken,
                          let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                        throw AuthError.invalidCredentials
                    }

                    let appleResult = AppleSignInResult(
                        identityToken: identityToken,
                        authorizationCode: appleIDCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) },
                        fullName: appleIDCredential.fullName,
                        email: appleIDCredential.email
                    )

                    try await authManager.processAppleSignInResult(appleResult)

                case .failure(let error):
                    if let authError = error as? ASAuthorizationError {
                        switch authError.code {
                        case .canceled:
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAppleSignInLoading = false
                                    errorMessage = nil
                                }
                            }
                            return
                        case .failed:
                            throw AuthError.appleSignInFailed("Apple Sign-In failed: \(authError.localizedDescription)")
                        case .invalidResponse:
                            throw AuthError.appleSignInFailed("Invalid Apple response: \(authError.localizedDescription)")
                        case .notHandled:
                            throw AuthError.appleSignInFailed("Apple Sign-In not handled: \(authError.localizedDescription)")
                        case .unknown:
                            throw AuthError.appleSignInFailed("Unknown Apple error (code: \(authError.code.rawValue)): \(authError.localizedDescription)")
                        @unknown default:
                            throw AuthError.appleSignInFailed("Unknown Apple Sign-In error (code: \(authError.code.rawValue)): \(authError.localizedDescription)")
                        }
                    } else {
                        throw AuthError.appleSignInFailed("Authentication error: \(error.localizedDescription)")
                    }
                }

                await MainActor.run {
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let authError = error as? AuthError {
                            errorMessage = authError.userFriendlyMessage
                        } else {
                            errorMessage = LocalizedKey.unexpectedError.localized
                        }
                        isAppleSignInLoading = false
                    }
                }
            }
        }
    }

    private var actionsHelper: AccountActionsHelper {
        AccountActionsHelper(
            authManager: authManager,
            successMessage: $successMessage,
            errorMessage: $errorMessage
        )
    }

    private func performLinkApple() {
        pendingAction = .linkApple
        showRecentAuthSheet = true
    }

    private func performUnlinkApple() {
        pendingAction = .unlinkApple
        showRecentAuthSheet = true
    }

    private func executeLinkApple() {
        Task {
            await actionsHelper.linkAppleSSO()
        }
    }

    private func executeUnlinkApple() {
        Task {
            await actionsHelper.unlinkAppleSSO()
        }
    }

    private func executePendingAction(_ action: PendingAction) {
        switch action {
        case .linkApple:
            executeLinkApple()
        case .unlinkApple:
            executeUnlinkApple()
        case .setPassword(let newPassword):
            performSetPassword(newPassword)
        case .definePassword:
            withAnimation(.easeInOut(duration: 0.3)) {
                showChangePassword = true
            }
        }
    }

    private func performSetPassword(_ newPassword: String) {
        Task {
            await actionsHelper.setPassword(newPassword) { password in
                pendingAction = .setPassword(password)
                showRecentAuthSheet = true
            }
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String?
    let action: () -> Void

    init(title: String, icon: String, color: Color, subtitle: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ThibouTheme.Typography.body)
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThibouTheme.Colors.creamWhite.opacity(0.8))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.borderless)
    }
}

struct LanguageSelectorView: View {
    @ObservedObject var languageManager: LanguageManager
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedKey.chooseLangauge)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            languageManager.setLanguage(language)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onBack()
                            }
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.system(size: 20))

                                Text(language.displayName)
                                    .font(ThibouTheme.Typography.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                if languageManager.selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ThibouTheme.Colors.leafGreen)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(languageManager.selectedLanguage == language ?
                                          ThibouTheme.Colors.leafGreen.opacity(0.1) :
                                          ThibouTheme.Colors.creamWhite.opacity(0.8))
                                    .stroke(languageManager.selectedLanguage == language ?
                                           ThibouTheme.Colors.leafGreen.opacity(0.3) :
                                           Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.bottom, 40)
    }
}

struct AccountSectionView: View {
    @ObservedObject var authManager: AuthManager
    let onBack: () -> Void

    var body: some View {
        AccountSettingsContentView(
            authManager: authManager,
            onDismiss: onBack
        )
    }
}

struct EmailLoginContentView: View {
    @ObservedObject var authManager: AuthManager
    let onSuccess: () -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(isRegistering ? LocalizedKey.createAccount.localized : LocalizedKey.signInAuth.localized)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
                if isRegistering {
                    TextField(LocalizedKey.username.localized, text: $name)
                        .padding()
                        .glassEffect()
                        .glassEffectID("name_field", in: glassNamespace)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                TextField(LocalizedKey.emailAddress.localized, text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .glassEffect()
                    .glassEffectID("email_field", in: glassNamespace)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField(LocalizedKey.password.localized, text: $password)
                    .padding()
                    .glassEffect()
                    .glassEffectID("password_field", in: glassNamespace)
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

            Button(action: handleSubmit) {
                ZStack {
                    Text(isRegistering ? LocalizedKey.createAccount.localized : LocalizedKey.signInAuth.localized)
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
                .glassEffectID("submit_button", in: glassNamespace)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || !isFormValid)
            .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
            .padding(.horizontal)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRegistering.toggle()
                }
                errorMessage = nil
            }) {
                Text(isRegistering ? LocalizedKey.alreadyHaveAccount.localized : LocalizedKey.dontHaveAccount.localized)
                    .font(.system(size: 13))
                    .foregroundColor(ThibouTheme.Colors.skyBlue)
            }
            .padding(.bottom, 40)
        }
    }

    private var isFormValid: Bool {
        if isRegistering {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func handleSubmit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                if isRegistering {
                    try await authManager.registerWithEmail(email, password: password, name: name)
                } else {
                    try await authManager.signInWithEmail(email, password: password)
                }

                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let authError = error as? AuthError {
                            errorMessage = authError.userFriendlyMessage
                        } else {
                            errorMessage = LocalizedKey.unexpectedError.localized
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
}


struct ChangeUsernameContentView: View {
    @ObservedObject var authManager: AuthManager
    let onSuccess: () -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var newUsername = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Change Username")
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
                TextField(LocalizedKey.username.localized, text: $newUsername)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .glassEffect()
                    .glassEffectID("new_username_field", in: glassNamespace)
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

            Button(action: changeUsername) {
                ZStack {
                    Text("Change Username")
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
                .glassEffectID("change_username_button", in: glassNamespace)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || !isFormValid)
            .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.bottom, 40)
        .onAppear {
            if newUsername.isEmpty, let currentName = authManager.currentUser?.name {
                newUsername = currentName
            }
        }
    }

    private var isFormValid: Bool {
        return !newUsername.isEmpty && newUsername.count >= 2
    }

    private func changeUsername() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                try await authManager.changeUsername(newUsername: newUsername)
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let authError = error as? AuthError {
                            errorMessage = authError.userFriendlyMessage
                        } else {
                            errorMessage = error.localizedDescription
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
}
