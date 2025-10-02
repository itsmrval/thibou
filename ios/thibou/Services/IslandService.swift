import Foundation
import Combine

@MainActor
class IslandService: ObservableObject {
    static let shared = IslandService()

    @Published var residents: [IslandResident] = []
    @Published var likes: [String] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiManager = APIManager.shared
    private let authManager = AuthManager.shared
    private let villagerService = VillagerService.shared

    private init() {}

    var residentVillagers: [VillagerSummary] {
        residents.compactMap { r in
            villagerService.villagerSummaries.first(where: { $0.id == r.id })
        }
    }

    var favoriteVillagers: [VillagerSummary] {
        residents.filter { $0.favorite }.compactMap { r in
            villagerService.villagerSummaries.first(where: { $0.id == r.id })
        }
    }

    var likeVillagers: [VillagerSummary] {
        likes.compactMap { name in
            villagerService.villagerSummaries.first(where: { $0.name.en == name })
        }
    }

    var canAddResident: Bool {
        residents.count < 10
    }

    func isResident(_ villagerIdOrName: String) -> Bool {
        residents.contains(where: { $0.id == villagerIdOrName || $0.name == villagerIdOrName })
    }

    func isFavorite(_ villagerIdOrName: String) -> Bool {
        residents.contains(where: { ($0.id == villagerIdOrName || $0.name == villagerIdOrName) && $0.favorite })
    }

    func isLiked(_ villagerIdOrName: String) -> Bool {
        likes.contains(villagerIdOrName)
    }

    func fetchIslandData() async {
        guard let userId = authManager.currentUser?.id else {
            error = "User not authenticated"
            return
        }

        isLoading = true
        error = nil

        do {
            let residentsResponse: ResidentsResponse = try await apiManager.makeRequest(
                endpoint: "/user/\(userId)/island/residents",
                requiresAuth: true,
                responseType: ResidentsResponse.self
            )

            residents = residentsResponse.residents
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func updateResidents(_ newResidents: [IslandResident]) async -> Bool {
        guard let userId = authManager.currentUser?.id else {
            error = "User not authenticated"
            return false
        }

        do {
            let residentsData = newResidents.map { ["name": $0.name, "favorite": $0.favorite] }
            let requestBody = ["residents": residentsData]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: UpdateResidentsResponse = try await apiManager.makeRequest(
                endpoint: "/user/\(userId)/island/residents",
                method: .PUT,
                body: bodyData,
                requiresAuth: true,
                responseType: UpdateResidentsResponse.self
            )

            residents = response.island.residents
            likes = response.island.likes
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func toggleFavorite(_ villager: VillagerSummary) async -> Bool {
        var updatedResidents = residents
        if let index = updatedResidents.firstIndex(where: { $0.id == villager.id }) {
            updatedResidents[index] = IslandResident(
                id: updatedResidents[index].id,
                name: updatedResidents[index].name,
                favorite: !updatedResidents[index].favorite
            )
        }
        return await updateResidents(updatedResidents)
    }

    func removeResident(_ villager: VillagerSummary) async -> Bool {
        let updatedResidents = residents.filter { $0.id != villager.id }
        return await updateResidents(updatedResidents)
    }

    func fetchLikes() async {
        guard let userId = authManager.currentUser?.id else {
            error = "User not authenticated"
            return
        }

        do {
            let response: LikesResponse = try await apiManager.makeRequest(
                endpoint: "/user/\(userId)/like",
                requiresAuth: true,
                responseType: LikesResponse.self
            )

            likes = response.villagers.map { $0.name.en }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addLike(_ villagerName: String) async -> Bool {
        guard let userId = authManager.currentUser?.id else {
            error = "User not authenticated"
            return false
        }

        do {
            let requestBody = ["villagerName": villagerName]
            let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

            let response: LikesResponse = try await apiManager.makeRequest(
                endpoint: "/user/\(userId)/like",
                method: .POST,
                body: bodyData,
                requiresAuth: true,
                responseType: LikesResponse.self
            )

            likes = response.villagers.map { $0.name.en }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func removeLike(_ villagerName: String) async -> Bool {
        guard let userId = authManager.currentUser?.id else {
            error = "User not authenticated"
            return false
        }

        do {
            let response: LikesResponse = try await apiManager.makeRequest(
                endpoint: "/user/\(userId)/like/\(villagerName)",
                method: .DELETE,
                requiresAuth: true,
                responseType: LikesResponse.self
            )

            likes = response.villagers.map { $0.name.en }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func clearData() {
        residents = []
        likes = []
        error = nil
    }
}
