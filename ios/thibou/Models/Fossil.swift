import SwiftUI

struct FossilSummary: IdentifiableModel {
    let id: String
    let name: FossilName
    let room: Int
    let parts: [FossilPart]
    let total_price: Int
    let parts_count: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, room, parts, total_price, parts_count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(FossilName.self, forKey: .name)
        room = try container.decode(Int.self, forKey: .room)
        parts = try container.decode([FossilPart].self, forKey: .parts)
        total_price = try container.decode(Int.self, forKey: .total_price)
        parts_count = try container.decode(Int.self, forKey: .parts_count)
    }

    init(from fossil: Fossil) {
        self.id = fossil.id
        self.name = fossil.name
        self.room = fossil.room
        self.parts = fossil.parts
        self.total_price = fossil.total_price
        self.parts_count = fossil.parts_count
    }

    var displayName: String {
        return name.en
    }

    var displayRoom: String {
        return "\(LocalizedKey.room.localized) \(room)"
    }

    var titleColorValue: Color {
        switch total_price {
        case 0...3000:
            return ThibouTheme.Colors.warmYellow
        case 3001...5000:
            return ThibouTheme.Colors.leafGreen
        case 5001...8000:
            return ThibouTheme.Colors.skyBlue
        default:
            return ThibouTheme.Colors.coral
        }
    }

    func toFossil() -> Fossil {
        return Fossil(
            id: self.id,
            name: self.name,
            room: self.room,
            parts: self.parts,
            total_price: self.total_price,
            parts_count: self.parts_count
        )
    }
}

struct Fossil: IdentifiableModel {
    let id: String
    let name: FossilName
    let room: Int
    let parts: [FossilPart]
    let total_price: Int
    let parts_count: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, room, parts, total_price, parts_count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(FossilName.self, forKey: .name)
        room = try container.decode(Int.self, forKey: .room)
        parts = try container.decode([FossilPart].self, forKey: .parts)
        total_price = try container.decode(Int.self, forKey: .total_price)
        parts_count = try container.decode(Int.self, forKey: .parts_count)
    }

    init(id: String, name: FossilName, room: Int, parts: [FossilPart], total_price: Int, parts_count: Int) {
        self.id = id
        self.name = name
        self.room = room
        self.parts = parts
        self.total_price = total_price
        self.parts_count = parts_count
    }

    var displayName: String {
        return name.en
    }

    var displayRoom: String {
        return "\(LocalizedKey.room.localized) \(room)"
    }

    var titleColorValue: Color {
        switch total_price {
        case 0...3000:
            return ThibouTheme.Colors.warmYellow
        case 3001...5000:
            return ThibouTheme.Colors.leafGreen
        case 5001...8000:
            return ThibouTheme.Colors.skyBlue
        default:
            return ThibouTheme.Colors.coral
        }
    }
}

struct FossilPart: Codable, Hashable {
    let name: String
    let full_name: String
    let sell: Int
    let width: Double
    let length: Double
}

struct FossilName: Codable, Hashable {
    let en: String
}

struct FossilImage: Codable, Identifiable, Hashable {
    let id: String
    let fossil_id: String
    let part_name: String
    let image_data: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fossil_id = "fossil_id"
        case part_name = "part_name"
        case image_data = "image_data"
        case size
    }
}

struct FossilsResponse: Codable {
    let message: String
    let count: Int
    let fossils: [Fossil]
}

struct FossilDetailResponse: Codable {
    let message: String
    let fossil: Fossil
}

struct FossilImageResponse: Codable {
    let message: String
    let image: FossilImage
}
