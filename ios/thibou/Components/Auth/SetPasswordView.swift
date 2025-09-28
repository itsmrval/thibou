import SwiftUI

struct SetPasswordContentView: View {
    @ObservedObject var authManager: AuthManager
    let isSettingNew: Bool
    let onSuccess: (String) -> Void
    let onBack: () -> Void
    let onRecentAuthRequired: (String) -> Void
    let glassNamespace: Namespace.ID

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(isSettingNew ? LocalizedKey.definePassword.localized : LocalizedKey.updateMyPassword.localized)
                .font(ThibouTheme.Typography.mediumTitle)
                .padding(.top, 10)

            VStack(spacing: 12) {
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

            Button(action: setPassword) {
                ZStack {
                    Text(isSettingNew ? LocalizedKey.definePassword.localized : LocalizedKey.updateMyPassword.localized)
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
                .glassEffectID("set_password_button", in: glassNamespace)
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
        return !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword.count >= 6 &&
               newPassword == confirmPassword
    }

    private func setPassword() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }

        Task {
            do {
                try await authManager.setPassword(newPassword)
                await MainActor.run {
                    let message = isSettingNew ? LocalizedKey.passwordDefinedSuccessfully.localized : LocalizedKey.passwordUpdatedSuccessfully.localized
                    onSuccess(message)
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoading = false
                        if extractRecentAuthError(from: error) != nil {
                            onRecentAuthRequired(newPassword)
                        } else {
                            if let authError = error as? AuthError {
                                errorMessage = authError.userFriendlyMessage
                            } else {
                                errorMessage = error.localizedDescription
                            }
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