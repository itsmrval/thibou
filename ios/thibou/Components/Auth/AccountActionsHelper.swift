import SwiftUI

struct AccountActionsHelper {
    let authManager: AuthManager
    let successMessage: Binding<String?>
    let errorMessage: Binding<String?>

    func linkAppleSSO() async {
        do {
            try await authManager.linkAppleSSO()
            await MainActor.run {
                successMessage.wrappedValue = LocalizedKey.appleAccountLinkedSuccessfully.localized
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthError {
                    if case .userCancelled = authError {
                        return
                    }
                    if case .appleSignInFailed(let message) = authError,
                       message.contains("annulée") || message.contains("cancelled") || message.contains("canceled") {
                        return
                    }
                    errorMessage.wrappedValue = authError.userFriendlyMessage
                } else {
                    errorMessage.wrappedValue = error.localizedDescription
                }
            }
        }
    }

    func unlinkAppleSSO() async {
        do {
            try await authManager.unlinkAppleSSO()
            await MainActor.run {
                successMessage.wrappedValue = LocalizedKey.appleAccountUnlinkedSuccessfully.localized
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthError {
                    errorMessage.wrappedValue = authError.userFriendlyMessage
                } else {
                    errorMessage.wrappedValue = error.localizedDescription
                }
            }
        }
    }

    func setPassword(_ newPassword: String) async {
        do {
            try await authManager.setPassword(newPassword)
            await MainActor.run {
                let isNew = authManager.currentUser?.hasPassword != true
                successMessage.wrappedValue = isNew ? LocalizedKey.passwordDefinedSuccessfully.localized : LocalizedKey.passwordUpdatedSuccessfully.localized
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthError {
                    errorMessage.wrappedValue = authError.userFriendlyMessage
                } else {
                    errorMessage.wrappedValue = error.localizedDescription
                }
            }
        }
    }

    func changeUsername(_ newUsername: String) async {
        do {
            try await authManager.changeUsername(newUsername: newUsername)
            await MainActor.run {
                successMessage.wrappedValue = "Username changed successfully"
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthError {
                    errorMessage.wrappedValue = authError.userFriendlyMessage
                } else {
                    errorMessage.wrappedValue = error.localizedDescription
                }
            }
        }
    }

    func changeEmail(_ newEmail: String) async {
        do {
            try await authManager.changeEmail(newEmail: newEmail)
            await MainActor.run {
                successMessage.wrappedValue = "Email changed successfully"
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthError {
                    errorMessage.wrappedValue = authError.userFriendlyMessage
                } else {
                    errorMessage.wrappedValue = error.localizedDescription
                }
            }
        }
    }
}
