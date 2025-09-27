import Foundation
import Combine

@MainActor
class VillagerService: ObservableObject, CacheManaging {
    typealias ImageType = VillagerImage
    typealias DetailType = Villager
    static let shared = VillagerService()

    @Published var villagerSummaries: [VillagerSummary] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiManager = APIManager.shared
    private var currentSummariesTask: Task<Void, Never>?
    private var imageCache: [String: VillagerImage] = [:]
    private var villagerDetailsCache: [String: Villager] = [:]

    private init() {}

    func fetchVillagerById(id: String) async -> Villager? {
        if let cached = villagerDetailsCache[id] {
            return cached
        }

        do {
            let response: VillagerDetailResponse = try await apiManager.makeRequest(
                endpoint: "/villager/\(id)",
                requiresAuth: AuthManager.shared.isLoggedIn,
                responseType: VillagerDetailResponse.self
            )
            villagerDetailsCache[id] = response.villager
            return response.villager
        } catch {
            return nil
        }
    }

    func fetchVillagerSummaries() async {
        currentSummariesTask?.cancel()

        currentSummariesTask = Task {
            if Task.isCancelled { return }

            isLoading = true
            error = nil

            do {
                if Task.isCancelled {
                    isLoading = false
                    return
                }

                let response: VillagersResponse = try await apiManager.makeRequest(
                    endpoint: "/villager",
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: VillagersResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                villagerSummaries = response.villagers.map { VillagerSummary(from: $0) }
                isLoading = false
            } catch {
                if !Task.isCancelled && !(error is CancellationError) {
                    self.error = error.localizedDescription
                }
                isLoading = false
            }
        }

        await currentSummariesTask?.value
    }

    func fetchVillagerImage(villagerId: String, imageType: String) async -> VillagerImage? {
        let cacheKey = "\(villagerId)_\(imageType)"

        if let cached = imageCache[cacheKey] {
            return cached
        }

        do {
            let response: VillagerImageResponse = try await apiManager.makeRequest(
                endpoint: "/villager/\(villagerId)/img/\(imageType)",
                requiresAuth: false,
                responseType: VillagerImageResponse.self
            )
            imageCache[cacheKey] = response.image
            return response.image
        } catch {
            return nil
        }
    }

    func clearImageCache() {
        imageCache.removeAll()
    }

    func clearDetailsCache() {
        villagerDetailsCache.removeAll()
    }

    func clearAllCaches() {
        clearImageCache()
        clearDetailsCache()
    }
}

struct VillagerFilters {
    var species: String?
    var personality: String?
    var gender: String?
    var islander: Bool?
    var search: String?
}
