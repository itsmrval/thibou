import SwiftUI

struct FishSummary: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = FishName
    let id: String
    let name: FishName
    let location: String
    let price: FishPrice
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, location, price, rarity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(FishName.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        price = try container.decode(FishPrice.self, forKey: .price)
        rarity = try container.decode(String.self, forKey: .rarity)
    }

    init(from fish: Fish) {
        self.id = fish.id
        self.name = fish.name
        self.location = fish.location
        self.price = fish.price
        self.rarity = fish.rarity
    }
    var displayLocation: String {
        return location
    }

    var displayRarity: String {
        return rarity
    }

    var shopPrice: Int {
        return price.shop
    }

    var cjPrice: Int {
        return price.cj
    }

    var titleColorValue: Color {
        switch rarity.lowercased() {
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

    func toFish() -> Fish {
        return Fish(
            id: self.id,
            name: self.name,
            location: self.location,
            price: self.price,
            availability: nil,
            rarity: self.rarity
        )
    }
}

struct Fish: IdentifiableModel, NamedModel, ColoredModel {
    typealias NameType = FishName
    let id: String
    let name: FishName
    let location: String
    let price: FishPrice
    let availability: FishAvailability?
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, location, price, availability, rarity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(FishName.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        price = try container.decode(FishPrice.self, forKey: .price)
        availability = try container.decodeIfPresent(FishAvailability.self, forKey: .availability)
        rarity = try container.decode(String.self, forKey: .rarity)
    }

    init(id: String, name: FishName, location: String, price: FishPrice, availability: FishAvailability?, rarity: String) {
        self.id = id
        self.name = name
        self.location = location
        self.price = price
        self.availability = availability
        self.rarity = rarity
    }
    var displayLocation: String {
        return location
    }

    var displayRarity: String {
        return rarity
    }

    var shopPrice: Int {
        return price.shop
    }

    var cjPrice: Int {
        return price.cj
    }

    var titleColorValue: Color {
        switch rarity.lowercased() {
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

struct FishPrice: Codable, Hashable {
    let cj: Int
    let shop: Int
}

struct FishAvailability: Codable, Hashable {
    let north: FishMonthlyAvailability
    let south: FishMonthlyAvailability
}

struct FishMonthlyAvailability: Codable, Hashable {
    let january: FishTimeRange?
    let february: FishTimeRange?
    let march: FishTimeRange?
    let april: FishTimeRange?
    let may: FishTimeRange?
    let june: FishTimeRange?
    let july: FishTimeRange?
    let august: FishTimeRange?
    let september: FishTimeRange?
    let october: FishTimeRange?
    let november: FishTimeRange?
    let december: FishTimeRange?

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

struct FishTimeRange: Codable, Hashable {
    let begin: Int
    let end: Int
}

struct FishName: Codable, Hashable, LocalizableName {
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

struct FishImage: Codable, Identifiable, Hashable {
    let id: String
    let fishId: String
    let imageType: String
    let imageData: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fishId = "fish_id"
        case imageType = "image_type"
        case imageData = "image_data"
        case size
    }
}

struct FishesResponse: Codable {
    let message: String
    let count: Int
    let fishes: [Fish]
}

struct FishDetailResponse: Codable {
    let message: String
    let fish: Fish
}

struct FishImageResponse: Codable {
    let message: String
    let image: FishImage
}