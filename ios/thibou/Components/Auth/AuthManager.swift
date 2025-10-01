import Foundation
import SwiftUI
import Combine
import AuthenticationServices

struct SSOProvider: Codable {
    let provider: String
    let id: String?
}

struct User: Codable {
    let id: String
    let name: String
    let email: String?
    let role: String
    let ssoProviders: [SSOProvider]
    let hasPassword: Bool?
    let createdAt: String?
    let version: Int?
    let scopes: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, role, ssoProviders, hasPassword, createdAt, scopes
        case version = "__v"
    }

    var hasAppleSSO: Bool {
        return ssoProviders.contains { $0.provider == "apple" }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        role = try container.decode(String.self, forKey: .role)
        ssoProviders = try container.decodeIfPresent([SSOProvider].self, forKey: .ssoProviders) ?? []
        hasPassword = try container.decodeIfPresent(Bool.self, forKey: .hasPassword)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        scopes = try container.decodeIfPresent([String].self, forKey: .scopes)
    }
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
    let tokenType: String
}

struct AuthMeResponse: Codable {
    let user: User
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case invalidResponse
    case invalidToken
    case noToken
    case serverError(String)
    case networkError
    case validationError(String)
    case userCancelled
    case appleSignInFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Identifiants invalides"
        case .invalidResponse:
            return "Réponse du serveur invalide"
        case .invalidToken:
            return "Token d'authentification invalide"
        case .noToken:
            return "Aucun token d'authentification"
        case .serverError(let message):
            return message
        case .networkError:
            return "Erreur de connexion réseau"
        case .validationError(let message):
            return message
        case .userCancelled:
            return "Connexion avec Apple annulée"
        case .appleSignInFailed(let message):
            return message
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .invalidCredentials:
            return "Vos identifiants sont incorrects. Veuillez réessayer."
        case .invalidResponse, .invalidToken, .noToken:
            return "Un problème technique est survenu. Veuillez réessayer."
        case .serverError(let message):
            return message.isEmpty ? "Erreur du serveur" : message
        case .networkError:
            return "Vérifiez votre connexion internet et réessayez."
        case .validationError(let message):
            return message.isEmpty ? "Données invalides" : message
        case .userCancelled:
            return "Connexion avec Apple annulée"
        case .appleSignInFailed(let message):
            if message.contains("code: 1000") || message.contains("Unknown Apple error") {
                return "Connexion avec Apple annulée"
            } else if message.contains("canceled") || message.contains("cancelled") {
                return "Connexion avec Apple annulée"
            } else {
                return "Connexion avec Apple impossible. Veuillez réessayer."
            }
        }
    }
}

struct RecentAuthRequiredError: Error {}

final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var authToken: String?

    private let apiManager = APIManager.shared
    private let keychainManager = KeychainManager.shared

    private init() {
        Task { @MainActor in
            await self.checkStoredAuth()
        }
    }

    @MainActor
    private func checkStoredAuth() async {
        do {
            if let token = try keychainManager.getAuthToken() {
                self.authToken = token
                await validateStoredToken()
            }
        } catch {
            print("Failed to retrieve token from keychain: \(error)")
        }
    }

    @MainActor
    private func validateStoredToken() async {
        guard let token = authToken else {
            return
        }

        do {
            let user = try await validateToken(token)
            self.currentUser = user
            self.isLoggedIn = true
        } catch {
            self.authToken = nil
            self.currentUser = nil
            self.isLoggedIn = false
            try? keychainManager.deleteAuthToken()
        }
    }

    private func validateToken(_ token: String) async throws -> User {
        let oldToken = self.authToken
        self.authToken = token

        do {
            let response: AuthMeResponse = try await apiManager.makeRequest(
                endpoint: "/auth/me",
                requiresAuth: true,
                responseType: AuthMeResponse.self
            )
            return response.user
        } catch {
            self.authToken = oldToken
            throw AuthError.invalidToken
        }
    }

    func signInWithEmail(_ email: String, password: String) async throws {
        let requestBody = ["email": email, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let authResponse: AuthResponse = try await apiManager.makeRequest(
                endpoint: "/auth/login",
                method: .POST,
                body: bodyData,
                responseType: AuthResponse.self
            )
            await handleSuccessfulAuth(authResponse)
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                throw AuthError.serverError(message)
            default:
                throw AuthError.networkError
            }
        }
    }

    func registerWithEmail(_ email: String, password: String, name: String) async throws {
        let requestBody = ["email": email, "password": password, "name": name]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, httpResponse) = try await apiManager.makeRequestWithoutDecoding(
                endpoint: "/auth/register",
                method: .POST,
                body: bodyData
            )

            if httpResponse.statusCode == 201 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                await handleSuccessfulAuth(authResponse)
            } else {
                let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Registration failed")
                throw AuthError.serverError(errorMessage)
            }
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                throw AuthError.serverError(message)
            default:
                throw AuthError.networkError
            }
        } catch let decodingError as DecodingError {
            throw AuthError.serverError("Registration response parsing failed: \(decodingError.localizedDescription)")
        } catch {
            throw AuthError.serverError("Registration failed: \(error.localizedDescription)")
        }
    }

    func signInWithApple() async throws {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate

        authorizationController.performRequests()

        let result = try await delegate.result
        try await processAppleSignInResult(result)
    }

    func processAppleSignInResult(_ result: AppleSignInResult) async throws {
        var requestBody: [String: Any] = ["token": result.identityToken]

        if let fullName = result.fullName {
            var nameComponents: [String] = []
            if let givenName = fullName.givenName, !givenName.isEmpty {
                nameComponents.append(givenName)
            }
            if let familyName = fullName.familyName, !familyName.isEmpty {
                nameComponents.append(familyName)
            }
            if !nameComponents.isEmpty {
                requestBody["name"] = nameComponents.joined(separator: " ")
            }
        }

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let authResponse: AuthResponse = try await apiManager.makeRequest(
                endpoint: "/sso/apple",
                method: .POST,
                body: bodyData,
                responseType: AuthResponse.self
            )
            await handleSuccessfulAuth(authResponse)
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                throw AuthError.appleSignInFailed(message)
            default:
                throw AuthError.appleSignInFailed("Apple Sign-In failed")
            }
        }
    }

    @MainActor
    private func handleSuccessfulAuth(_ authResponse: AuthResponse) {
        self.authToken = authResponse.token
        self.currentUser = authResponse.user
        self.isLoggedIn = true

        do {
            try keychainManager.saveAuthToken(authResponse.token)
        } catch {
            print("Failed to save token to keychain: \(error)")
        }
    }
    @MainActor
    func signOut() {
        self.authToken = nil
        self.currentUser = nil
        self.isLoggedIn = false

        do {
            try keychainManager.deleteAuthToken()
        } catch {
            print("Failed to delete token from keychain: \(error)")
        }
    }

    func linkAppleSSO() async throws {
        guard let token = authToken else {
            throw AuthError.noToken
        }

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let appleRequest = appleIDProvider.createRequest()
        appleRequest.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [appleRequest])
        let delegate = AppleSignInDelegate()
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate

        authorizationController.performRequests()

        let result = try await delegate.result

        let requestBody = ["token": result.identityToken]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, httpResponse) = try await apiManager.makeRequestWithoutDecoding(
            endpoint: "/sso/apple/link",
            method: .POST,
            body: bodyData,
            requiresAuth: true
        )

        if httpResponse.statusCode == 200 {
            try await refreshUserData()
        } else if httpResponse.statusCode == 403 {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let requiresRecentAuth = errorData?["requiresRecentAuth"] as? Bool, requiresRecentAuth {
                throw RecentAuthRequiredError()
            }
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to link Apple account")
            throw AuthError.serverError(errorMessage)
        } else {
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to link Apple account")
            throw AuthError.serverError(errorMessage)
        }
    }

    func unlinkAppleSSO() async throws {
        guard let token = authToken else {
            throw AuthError.noToken
        }

        let (data, httpResponse) = try await apiManager.makeRequestWithoutDecoding(
            endpoint: "/sso/apple/unlink",
            method: .DELETE,
            requiresAuth: true
        )

        if httpResponse.statusCode == 200 {
            try await refreshUserData()
        } else if httpResponse.statusCode == 403 {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let requiresRecentAuth = errorData?["requiresRecentAuth"] as? Bool, requiresRecentAuth {
                throw RecentAuthRequiredError()
            }
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to unlink Apple account")
            throw AuthError.serverError(errorMessage)
        } else {
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to unlink Apple account")
            throw AuthError.serverError(errorMessage)
        }
    }

    func setPassword(_ newPassword: String) async throws {
        guard let token = authToken, let userId = currentUser?.id else {
            throw AuthError.noToken
        }

        let requestBody = ["newPassword": newPassword]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, httpResponse) = try await apiManager.makeRequestWithoutDecoding(
            endpoint: "/user/\(userId)",
            method: .PUT,
            body: bodyData,
            requiresAuth: true
        )

        if httpResponse.statusCode == 200 {
            try await refreshUserData()
        } else if httpResponse.statusCode == 403 {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let requiresRecentAuth = errorData?["requiresRecentAuth"] as? Bool, requiresRecentAuth {
                throw RecentAuthRequiredError()
            }
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to set password")
            throw AuthError.serverError(errorMessage)
        } else {
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to set password")
            throw AuthError.serverError(errorMessage)
        }
    }

    func changeEmail(newEmail: String, password: String) async throws {
        guard let token = authToken, let userId = currentUser?.id else {
            throw AuthError.noToken
        }

        let requestBody = ["email": newEmail, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, httpResponse) = try await apiManager.makeRequestWithoutDecoding(
            endpoint: "/user/\(userId)",
            method: .PUT,
            body: bodyData,
            requiresAuth: true
        )

        if httpResponse.statusCode == 200 {
            try await refreshUserData()
        } else {
            let errorMessage = apiManager.extractErrorMessage(from: data, defaultMessage: "Failed to change email")
            throw AuthError.serverError(errorMessage)
        }
    }

    @MainActor
    private func refreshUserData() async throws {
        guard let token = authToken else {
            throw AuthError.noToken
        }

        let user = try await validateToken(token)
        self.currentUser = user
    }

    func reAuthenticateWithPassword(_ password: String) async throws {
        guard let currentUser = currentUser, let email = currentUser.email else {
            throw AuthError.invalidCredentials
        }

        let requestBody = ["email": email, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let authResponse: AuthResponse = try await apiManager.makeRequest(
                endpoint: "/auth/login",
                method: .POST,
                body: bodyData,
                responseType: AuthResponse.self
            )
            await handleSuccessfulAuth(authResponse)
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                throw AuthError.serverError(message)
            default:
                throw AuthError.networkError
            }
        }
    }

    func reAuthenticateWithApple() async throws {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = []

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate

        authorizationController.performRequests()

        let result = try await delegate.result
        try await processAppleSignInResult(result)
    }
}

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    var result: AppleSignInResult {
        get async throws {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.invalidCredentials)
            return
        }

        guard let identityTokenData = appleIDCredential.identityToken else {
            continuation?.resume(throwing: AuthError.invalidCredentials)
            return
        }

        guard let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AuthError.invalidCredentials)
            return
        }

        let result = AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: appleIDCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) },
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )

        continuation?.resume(returning: result)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation?.resume(throwing: AuthError.userCancelled)
            case .failed:
                continuation?.resume(throwing: AuthError.appleSignInFailed("Apple Sign-In failed: \(authError.localizedDescription)"))
            case .invalidResponse:
                continuation?.resume(throwing: AuthError.appleSignInFailed("Invalid Apple response: \(authError.localizedDescription)"))
            case .notHandled:
                continuation?.resume(throwing: AuthError.appleSignInFailed("Apple Sign-In not handled: \(authError.localizedDescription)"))
            case .unknown:
                continuation?.resume(throwing: AuthError.appleSignInFailed("Unknown Apple error (code: \(authError.code.rawValue)): \(authError.localizedDescription)"))
            @unknown default:
                continuation?.resume(throwing: AuthError.appleSignInFailed("Unknown Apple Sign-In error (code: \(authError.code.rawValue)): \(authError.localizedDescription)"))
            }
        } else {
            continuation?.resume(throwing: AuthError.appleSignInFailed("Authentication error: \(error.localizedDescription)"))
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

struct AppleSignInResult {
    let identityToken: String
    let authorizationCode: String?
    let fullName: PersonNameComponents?
    let email: String?
}