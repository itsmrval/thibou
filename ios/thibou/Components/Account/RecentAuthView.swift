import SwiftUI
import AuthenticationServices

struct RecentAuthSheet: View {
    @ObservedObject var authManager: AuthManager
    let onDismiss: () -> Void
    let onAuthSuccess: () -> Void

    @State private var showEmailLogin = false
    @State private var isAppleSignInLoading = false
    @State private var errorMessage: String?
    @Namespace private var recentAuthGlassNamespace

    var hasPassword: Bool {
        authManager.currentUser?.hasPassword == true
    }

    var hasAppleSSO: Bool {
        authManager.currentUser?.hasAppleSSO == true
    }

    var body: some View {
        NavigationView {
            GlassEffectContainer {
                ZStack {
                    ThibouTheme.Colors.backgroundGradient
                        .ignoresSafeArea()

                    if !showEmailLogin {
                        VStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Text(LocalizedKey.confirmYourIdentity)
                                    .font(ThibouTheme.Typography.mediumTitle)
                                    .foregroundColor(ThibouTheme.Colors.leafGreen)

                                Text(LocalizedKey.confirmYourIdentityDescription)
                                    .font(ThibouTheme.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 20)

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
                                .padding(.horizontal)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }

                            VStack(spacing: 12) {
                                if hasAppleSSO {
                                    ZStack {
                                        SignInWithAppleButton(
                                            onRequest: { request in
                                                request.requestedScopes = []
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
                                }

                                if hasPassword {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showEmailLogin = true
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "key.fill")
                                            Text(LocalizedKey.signInWithPassword)
                                                .font(ThibouTheme.Typography.body)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .foregroundColor(ThibouTheme.Colors.leafGreen)
                                        .glassEffect()
                                        .glassEffectID("password_login", in: recentAuthGlassNamespace)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                        .padding()
                    } else {
                        EmailLoginForReAuthView(
                            authManager: authManager,
                            onSuccess: onAuthSuccess,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailLogin = false
                                }
                            },
                            glassNamespace: recentAuthGlassNamespace
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
                        } else {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: showEmailLogin ? "chevron.left" : "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThibouTheme.Colors.leafGreen)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
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
                    await MainActor.run {
                        onAuthSuccess()
                    }

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
                        default:
                            throw AuthError.appleSignInFailed("Apple Sign-In failed: \(authError.localizedDescription)")
                        }
                    } else {
                        throw AuthError.appleSignInFailed("Authentication error: \(error.localizedDescription)")
                    }
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
}

struct EmailLoginForReAuthView: View {
    @ObservedObject var authManager: AuthManager
    let onSuccess: () -> Void
    let onBack: () -> Void
    let glassNamespace: Namespace.ID

    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedKey.confirmYourIdentity)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
                SecureField(LocalizedKey.password.localized, text: $password)
                    .padding()
                    .glassEffect()
                    .glassEffectID("reauth_password_field", in: glassNamespace)
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
                    Text(LocalizedKey.signInAuth)
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
                .glassEffectID("reauth_submit_button", in: glassNamespace)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || password.isEmpty)
            .opacity((isLoading || password.isEmpty) ? 0.6 : 1.0)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func handleSubmit() {
        guard let currentUser = authManager.currentUser, let email = currentUser.email else {
            errorMessage = "User information not available"
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                try await authManager.reAuthenticateWithPassword(password)
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