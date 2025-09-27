import SwiftUI

protocol IdentifiableModel: Codable, Identifiable, Hashable {
    var id: String { get }
    var displayName: String { get }
}

protocol ColoredModel {
    var titleColorValue: Color { get }
}

protocol NamedModel {
    associatedtype NameType: LocalizableName
    var name: NameType { get }
}

extension NamedModel {
    var displayName: String {
        return name.en
    }

    func nameForLanguage(_ languageCode: String) -> String {
        return name.nameForLanguage(languageCode)
    }
}

protocol SummaryConvertible {
    associatedtype FullType
    func toFullModel() -> FullType
}

protocol FullModelConvertible {
    associatedtype SummaryType
    init(from summary: SummaryType)
}