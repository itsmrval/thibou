import Foundation

struct IslandResident: Codable, Identifiable {
    let id: String
    let name: String
    let favorite: Bool
}

struct ResidentsResponse: Codable {
    let message: String
    let residents: [IslandResident]
}

struct UpdateResidentsResponse: Codable {
    let message: String
    let island: IslandData

    struct IslandData: Codable {
        let residents: [IslandResident]
        let likes: [String]
    }
}

struct LikesResponse: Codable {
    let message: String
    let villagers: [VillagerSummary]
}
