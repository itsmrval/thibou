import Foundation
import Combine

@MainActor
class FishService: ObservableObject, CacheManaging {
    typealias ImageType = FishImage
    typealias DetailType = Fish
    static let shared = FishService()

    @Published var fishSummaries: [FishSummary] = []
    @Published var fishes: [Fish] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiManager = APIManager.shared
    private var currentFetchTask: Task<Void, Never>?
    private var currentSummariesTask: Task<Void, Never>?

    private var imageCache: [String: FishImage] = [:]
    private var fishDetailsCache: [String: Fish] = [:]

    private init() {}

    func fetchFishById(id: String) async -> Fish? {
        if let cached = fishDetailsCache[id] {
            return cached
        }

        do {
            let response: FishDetailResponse = try await apiManager.makeRequest(
                endpoint: "/fish/\(id)",
                requiresAuth: AuthManager.shared.isLoggedIn,
                responseType: FishDetailResponse.self
            )
            fishDetailsCache[id] = response.fish
            return response.fish
        } catch {
            return nil
        }
    }

    func fetchFishSummaries() async {
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

                let response: FishesResponse = try await apiManager.makeRequest(
                    endpoint: "/fish",
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: FishesResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                fishSummaries = response.fishes.map { FishSummary(from: $0) }
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

    func fetchFishes(filters: FishFilters = FishFilters()) async {
        currentFetchTask?.cancel()

        currentFetchTask = Task {
            if Task.isCancelled { return }

            isLoading = true
            error = nil

            do {
                var endpoint = "/fish"
                var queryParams: [String] = []

                if let location = filters.location {
                    queryParams.append("location=\(location)")
                }
                if let rarity = filters.rarity {
                    queryParams.append("rarity=\(rarity)")
                }
                if let search = filters.search, !search.isEmpty {
                    queryParams.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
                }

                if !queryParams.isEmpty {
                    endpoint += "?" + queryParams.joined(separator: "&")
                }

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                let response: FishesResponse = try await apiManager.makeRequest(
                    endpoint: endpoint,
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: FishesResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                fishes = response.fishes
                isLoading = false
            } catch {
                if !Task.isCancelled && !(error is CancellationError) {
                    self.error = error.localizedDescription
                }
                isLoading = false
            }
        }

        await currentFetchTask?.value
    }

    func fetchFishImage(fishId: String, imageType: String) async -> FishImage? {
        let cacheKey = "\(fishId)_\(imageType)"

        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }

        do {
            let endpoint = "/fish/\(fishId)/img/\(imageType)"

            let response: FishImageResponse = try await apiManager.makeRequest(
                endpoint: endpoint,
                requiresAuth: false,
                responseType: FishImageResponse.self
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
        fishDetailsCache.removeAll()
    }

    func clearAllCaches() {
        clearImageCache()
        clearDetailsCache()
    }
}

struct FishFilters {
    var location: String?
    var rarity: String?
    var search: String?
}