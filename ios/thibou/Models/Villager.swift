import SwiftUI

struct VillagerSummary: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = VillagerName
    let id: String
    let name: VillagerName
    let titleColor: String
    let textColor: String
    let species: String
    let personality: String?
    let gender: String
    let birthdayDate: String
    let popularityRank: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, species, personality, gender
        case titleColor = "title_color"
        case textColor = "text_color"
        case birthdayDate = "birthday_date"
        case popularityRank = "popularity_rank"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(VillagerName.self, forKey: .name)
        titleColor = try container.decode(String.self, forKey: .titleColor)
        textColor = try container.decode(String.self, forKey: .textColor)
        species = try container.decode(String.self, forKey: .species)
        gender = try container.decode(String.self, forKey: .gender)
        birthdayDate = try container.decode(String.self, forKey: .birthdayDate)
        popularityRank = try container.decodeIfPresent(String.self, forKey: .popularityRank)
        personality = try container.decodeIfPresent(String.self, forKey: .personality)
    }

    init(from villager: Villager) {
        self.id = villager.id
        self.name = villager.name
        self.titleColor = villager.titleColor
        self.textColor = villager.textColor
        self.species = villager.species
        self.personality = villager.personality
        self.gender = villager.gender
        self.birthdayDate = villager.birthdayDate
        self.popularityRank = villager.popularityRank
    }
    var displayPersonality: String {
        guard let personality = personality else { return LocalizedKey.notSpecified.localized }
        return LocalizedKey.personalityName(personality)
    }

    var titleColorValue: Color {
        Color(hex: titleColor) ?? ThibouTheme.Colors.skyBlue
    }

    var displayPopularityRank: String {
        guard let rank = popularityRank else { return LocalizedKey.notSpecified.localized }
        return rank == "unranked" ? LocalizedKey.notSpecified.localized : rank
    }

    var popularityRankColor: Color {
        guard let rank = popularityRank, rank != "unranked" else { return .gray }

        switch rank {
        case "S+":
            return Color.red
        case "S":
            return Color.orange
        case "A":
            return Color.yellow
        case "B":
            return Color.green
        case "C":
            return Color.blue
        case "D":
            return Color.indigo
        case "E":
            return Color.purple
        case "F":
            return Color.brown
        case "G":
            return Color.gray
        default:
            return Color.gray
        }
    }

    func toVillager() -> Villager {
        return Villager(
            id: self.id,
            name: self.name,
            titleColor: self.titleColor,
            textColor: self.textColor,
            species: self.species,
            personality: self.personality,
            gender: self.gender,
            birthdayDate: self.birthdayDate,
            popularityRank: self.popularityRank,
            sign: nil,
            quote: nil,
            house: nil,
            islander: nil,
            debut: nil
        )
    }
}

struct Villager: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = VillagerName
    let id: String
    let name: VillagerName
    let titleColor: String
    let textColor: String
    let species: String
    let personality: String?
    let gender: String
    let birthdayDate: String
    let popularityRank: String?
    let sign: String?
    let quote: VillagerQuote?
    let house: VillagerHouse?
    let islander: Bool?
    let debut: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, species, personality, gender, sign, quote, house, islander, debut
        case titleColor = "title_color"
        case textColor = "text_color"
        case birthdayDate = "birthday_date"
        case popularityRank = "popularity_rank"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(VillagerName.self, forKey: .name)
        titleColor = try container.decode(String.self, forKey: .titleColor)
        textColor = try container.decode(String.self, forKey: .textColor)
        species = try container.decode(String.self, forKey: .species)
        gender = try container.decode(String.self, forKey: .gender)
        birthdayDate = try container.decode(String.self, forKey: .birthdayDate)
        popularityRank = try container.decodeIfPresent(String.self, forKey: .popularityRank)

        islander = try container.decodeIfPresent(Bool.self, forKey: .islander)

        personality = try container.decodeIfPresent(String.self, forKey: .personality)
        sign = try container.decodeIfPresent(String.self, forKey: .sign)
        quote = try container.decodeIfPresent(VillagerQuote.self, forKey: .quote)
        house = try container.decodeIfPresent(VillagerHouse.self, forKey: .house)
        debut = try container.decodeIfPresent(String.self, forKey: .debut)
    }

    init(id: String, name: VillagerName, titleColor: String, textColor: String, species: String, personality: String?, gender: String, birthdayDate: String, popularityRank: String?, sign: String?, quote: VillagerQuote?, house: VillagerHouse?, islander: Bool?, debut: String?) {
        self.id = id
        self.name = name
        self.titleColor = titleColor
        self.textColor = textColor
        self.species = species
        self.personality = personality
        self.gender = gender
        self.birthdayDate = birthdayDate
        self.popularityRank = popularityRank
        self.sign = sign
        self.quote = quote
        self.house = house
        self.islander = islander
        self.debut = debut
    }
    var displayQuote: String {
        return quote?.en ?? ""
    }

    var displayPersonality: String {
        guard let personality = personality else { return LocalizedKey.notSpecified.localized }
        return LocalizedKey.personalityName(personality)
    }

    var displaySign: String {
        guard let sign = sign else { return LocalizedKey.notSpecified.localized }
        return LocalizedKey.astrologicalSignName(sign)
    }

    var displayDebut: String {
        guard let debut = debut else { return LocalizedKey.notSpecified.localized }
        return LocalizedKey.gameAppearanceName(debut)
    }

    var displayIslander: String {
        guard let islander = islander else { return LocalizedKey.notSpecified.localized }
        return islander ? LocalizedKey.yes.localized : LocalizedKey.no.localized
    }

    var titleColorValue: Color {
        Color(hex: titleColor) ?? ThibouTheme.Colors.skyBlue
    }

    var displayPopularityRank: String {
        guard let rank = popularityRank else { return LocalizedKey.notSpecified.localized }
        return rank == "unranked" ? LocalizedKey.notSpecified.localized : rank
    }

    var popularityRankColor: Color {
        guard let rank = popularityRank, rank != "unranked" else { return .gray }

        switch rank {
        case "S+":
            return Color.red
        case "S":
            return Color.orange
        case "A":
            return Color.yellow
        case "B":
            return Color.green
        case "C":
            return Color.blue
        case "D":
            return Color.indigo
        case "E":
            return Color.purple
        case "F":
            return Color.brown
        case "G":
            return Color.gray
        default:
            return Color.gray
        }
    }
}

struct VillagerHouse: Codable, Hashable {
    let roof: String?
    let siding: String?
    let door: String?
}

struct VillagerName: Codable, Hashable, LocalizableName {
    let en: String
    let jp: String?
    let fr: String?
    let es: String?
    let de: String?
    let it: String?
    let ko: String?
    let zh: String?
    let nl: String?
    let ru: String?
}

struct VillagerQuote: Codable, Hashable {
    let en: String?
    let jp: String?
    let fr: String?
}

struct VillagersResponse: Codable {
    let message: String
    let count: Int
    let villagers: [Villager]
}
struct VillagerDetailResponse: Codable {
    let message: String
    let villager: Villager
}

struct VillagerImage: Codable, Identifiable {
    let id: String
    let villagerId: String
    let imageType: String
    let imageData: String
    let size: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case villagerId = "villager_id"
        case imageType = "image_type"
        case imageData = "image_data"
        case size, createdAt, updatedAt
    }
}

struct VillagerImageResponse: Codable {
    let message: String
    let image: VillagerImage
}
