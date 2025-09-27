import Foundation

protocol LocalizableName {
    var en: String { get }
    var jp: String? { get }
    var fr: String? { get }
    var es: String? { get }
    var de: String? { get }
    var it: String? { get }
    var ko: String? { get }
    var zh: String? { get }
    var nl: String? { get }
    var ru: String? { get }
}

extension LocalizableName {
    func nameForLanguage(_ languageCode: String) -> String {
        switch languageCode {
        case "en": return en
        case "fr": return fr ?? en
        case "es": return es ?? en
        case "de": return de ?? en
        case "it": return it ?? en
        case "jp": return jp ?? en
        case "ko": return ko ?? en
        case "zh": return zh ?? en
        case "nl": return nl ?? en
        case "ru": return ru ?? en
        default: return en
        }
    }
}