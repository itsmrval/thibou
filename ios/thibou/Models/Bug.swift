import SwiftUI

struct BugSummary: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = BugName
    let id: String
    let name: BugName
    let location: String
    let weather: String
    let price: BugPrice
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, location, weather, price, rarity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(BugName.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        weather = try container.decode(String.self, forKey: .weather)
        price = try container.decode(BugPrice.self, forKey: .price)
        rarity = try container.decode(String.self, forKey: .rarity)
    }

    init(from bug: Bug) {
        self.id = bug.id
        self.name = bug.name
        self.location = bug.location
        self.weather = bug.weather
        self.price = bug.price
        self.rarity = bug.rarity
    }

    var displayLocation: String {
        return location
    }

    var displayWeather: String {
        return weather
    }

    var displayRarity: String {
        return rarity
    }

    var shopPrice: Int {
        return price.shop
    }

    var flickPrice: Int {
        return price.flick
    }

    var titleColorValue: Color {
        switch rarity.lowercased() {
        case "very_common":
            return ThibouTheme.Colors.warmYellow
        case "common":
            return ThibouTheme.Colors.leafGreen
        case "uncommon":
            return ThibouTheme.Colors.skyBlue
        case "rare":
            return ThibouTheme.Colors.coral
        default:
            return ThibouTheme.Colors.skyBlue
        }
    }

    func toBug() -> Bug {
        return Bug(
            id: self.id,
            name: self.name,
            location: self.location,
            weather: self.weather,
            price: self.price,
            availability: nil,
            rarity: self.rarity
        )
    }
}

struct Bug: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = BugName
    let id: String
    let name: BugName
    let location: String
    let weather: String
    let price: BugPrice
    let availability: BugAvailability?
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, location, weather, price, availability, rarity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(BugName.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        weather = try container.decode(String.self, forKey: .weather)
        price = try container.decode(BugPrice.self, forKey: .price)
        availability = try container.decodeIfPresent(BugAvailability.self, forKey: .availability)
        rarity = try container.decode(String.self, forKey: .rarity)
    }

    init(id: String, name: BugName, location: String, weather: String, price: BugPrice, availability: BugAvailability?, rarity: String) {
        self.id = id
        self.name = name
        self.location = location
        self.weather = weather
        self.price = price
        self.availability = availability
        self.rarity = rarity
    }

    var displayLocation: String {
        return location
    }

    var displayWeather: String {
        return weather
    }

    var displayRarity: String {
        return rarity
    }

    var shopPrice: Int {
        return price.shop
    }

    var flickPrice: Int {
        return price.flick
    }

    var titleColorValue: Color {
        switch rarity.lowercased() {
        case "very_common":
            return ThibouTheme.Colors.warmYellow
        case "common":
            return ThibouTheme.Colors.leafGreen
        case "uncommon":
            return ThibouTheme.Colors.skyBlue
        case "rare":
            return ThibouTheme.Colors.coral
        default:
            return ThibouTheme.Colors.skyBlue
        }
    }
}

struct BugPrice: Codable, Hashable {
    let flick: Int
    let shop: Int
}

struct BugAvailability: Codable, Hashable {
    let north: BugMonthlyAvailability
    let south: BugMonthlyAvailability
}

struct BugMonthlyAvailability: Codable, Hashable {
    let january: BugTimeRange?
    let february: BugTimeRange?
    let march: BugTimeRange?
    let april: BugTimeRange?
    let may: BugTimeRange?
    let june: BugTimeRange?
    let july: BugTimeRange?
    let august: BugTimeRange?
    let september: BugTimeRange?
    let october: BugTimeRange?
    let november: BugTimeRange?
    let december: BugTimeRange?

    enum CodingKeys: String, CodingKey {
        case january = "1"
        case february = "2"
        case march = "3"
        case april = "4"
        case may = "5"
        case june = "6"
        case july = "7"
        case august = "8"
        case september = "9"
        case october = "10"
        case november = "11"
        case december = "12"
    }
}

struct BugTimeRange: Codable, Hashable {
    let begin: Int
    let end: Int
}

struct BugName: Codable, Hashable, LocalizableName {
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

struct BugImage: Codable, Identifiable, Hashable {
    let id: String
    let bugId: String
    let imageType: String
    let imageData: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bugId = "bug_id"
        case imageType = "image_type"
        case imageData = "image_data"
        case size
    }
}

struct BugsResponse: Codable {
    let message: String
    let count: Int
    let bugs: [Bug]
}

struct BugDetailResponse: Codable {
    let message: String
    let bug: Bug
}

struct BugImageResponse: Codable {
    let message: String
    let image: BugImage
}