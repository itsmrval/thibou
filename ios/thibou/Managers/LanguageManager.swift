import SwiftUI
import Combine

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case japanese = "jp"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case korean = "ko"
    case chinese = "zh"
    case dutch = "nl"
    case russian = "ru"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        case .french: return "Français"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .dutch: return "Nederlands"
        case .russian: return "Русский"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .dutch: return "🇳🇱"
        case .russian: return "🇷🇺"
        }
    }
}

class LanguageManager: ObservableObject {
    @Published var selectedLanguage: AppLanguage = .english

    private let userDefaults = UserDefaults.standard
    private let languageKey = "selectedLanguage"

    static let shared = LanguageManager()

    init() {
        loadSelectedLanguage()
    }

    private func loadSelectedLanguage() {
        if let savedLanguage = userDefaults.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            selectedLanguage = language
        } else {
            selectedLanguage = getSystemLanguage()
        }
    }

    private func getSystemLanguage() -> AppLanguage {
        let locale = Locale.current
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        let regionCode = locale.region?.identifier

        if languageCode == "fr" && regionCode == "CA" {
            return .french
        }
        switch languageCode {
        case "en": return .english
        case "ja": return .japanese
        case "fr": return .french
        case "es": return .spanish
        case "de": return .german
        case "it": return .italian
        case "ko": return .korean
        case "zh": return .chinese
        case "nl": return .dutch
        case "ru": return .russian
        default: return .english
        }
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        userDefaults.set(language.rawValue, forKey: languageKey)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}