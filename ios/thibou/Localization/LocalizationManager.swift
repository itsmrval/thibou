import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage = .english
    private var translations: [String: [String: Any]] = [:]

    private init() {
        loadTranslations()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil
        )
        currentLanguage = LanguageManager.shared.selectedLanguage
    }

    @objc private func languageChanged() {
        currentLanguage = LanguageManager.shared.selectedLanguage
    }

    private func loadTranslations() {
        let componentFiles = [
            ("Common", "common"),
            ("Components/Library", "library"),
            ("Components/Auth", "auth"),
            ("Components/Home", "home"),
            ("Components/Settings", "settings"),
            ("Components/Tools", "tools"),
            ("Components/Island", "island"),
            ("Villager", "villager"),
            ("Fish", "fish"),
            ("Bug", "bug")
        ]
        let languages = ["en", "fr"]

        for (component, filename) in componentFiles {
            for language in languages {
                loadTranslationFile(component: component, filename: filename, language: language)
            }
        }
    }

    private func loadTranslationFile(component: String, filename: String, language: String) {
        guard let url = Bundle.main.url(forResource: "\(filename)_\(language)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }

        let key = "\(component)_\(language)"
        translations[key] = json
    }

    func localizedString(for key: String, component: String = "Common", fallback: String? = nil) -> String {
        let primaryKey = "\(component)_\(currentLanguage.rawValue)"
        let fallbackKey = "\(component)_en"

        if let translation = getNestedValue(from: translations[primaryKey], keyPath: key) {
            return translation
        }

        if let translation = getNestedValue(from: translations[fallbackKey], keyPath: key) {
            return translation
        }

        return fallback ?? key
    }

    private func getNestedValue(from dictionary: [String: Any]?, keyPath: String) -> String? {
        guard let dict = dictionary else { return nil }

        let keys = keyPath.split(separator: ".").map(String.init)

        if keys.count == 1 {
            return dict[keys[0]] as? String
        }

        var current: Any? = dict
        for key in keys {
            guard let currentDict = current as? [String: Any] else { return nil }
            current = currentDict[key]
        }

        return current as? String
    }

    func localizedString(for keyPath: String, fallback: String? = nil) -> String {
        let components = keyPath.split(separator: ".").map(String.init)
        guard components.count >= 2 else {
            return localizedString(for: keyPath, fallback: fallback)
        }

        let component = components[0]
        let key = components.dropFirst().joined(separator: ".")

        return localizedString(for: key, component: component, fallback: fallback)
    }
}
