import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.thibou.app"
    private let authTokenKey = "authToken"
    private let userDataKey = "userData"

    private init() {}

    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }

    func saveAuthToken(_ token: String) throws {
        let data = Data(token.utf8)
        try saveItem(data, forKey: authTokenKey)
    }

    func getAuthToken() throws -> String? {
        guard let data = try getItem(forKey: authTokenKey) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func saveUserData<T: Codable>(_ userData: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(userData)
        try saveItem(data, forKey: userDataKey)
    }

    func getUserData<T: Codable>(type: T.Type) throws -> T? {
        guard let data = try getItem(forKey: userDataKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    func deleteAuthToken() throws {
        try deleteItem(forKey: authTokenKey)
    }

    func deleteUserData() throws {
        try deleteItem(forKey: userDataKey)
    }

    func deleteAllItems() throws {
        try deleteAuthToken()
        try deleteUserData()
    }

    private func saveItem(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try updateItem(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }

    private func updateItem(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }

    private func getItem(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unknown(status)
        }
    }

    private func deleteItem(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unknown(status)
        }
    }
}