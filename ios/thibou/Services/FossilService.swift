import Foundation
import Combine

@MainActor
class FossilService: ObservableObject, CacheManaging {
    typealias ImageType = FossilImage
    typealias DetailType = Fossil
    static let shared = FossilService()

    @Published var fossilSummaries: [FossilSummary] = []
    @Published var fossils: [Fossil] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiManager = APIManager.shared
    private var currentFetchTask: Task<Void, Never>?
    private var currentSummariesTask: Task<Void, Never>?

    private var imageCache: [String: FossilImage] = [:]
    private var fossilDetailsCache: [String: Fossil] = [:]

    private init() {}

    func fetchFossilById(id: String) async -> Fossil? {
        if let cached = fossilDetailsCache[id] {
            return cached
        }

        do {
            let response: FossilDetailResponse = try await apiManager.makeRequest(
                endpoint: "/fossil/\(id)",
                requiresAuth: AuthManager.shared.isLoggedIn,
                responseType: FossilDetailResponse.self
            )
            fossilDetailsCache[id] = response.fossil
            return response.fossil
        } catch {
            return nil
        }
    }

    func fetchFossilSummaries() async {
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

                let response: FossilsResponse = try await apiManager.makeRequest(
                    endpoint: "/fossil",
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: FossilsResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                fossilSummaries = response.fossils.map { FossilSummary(from: $0) }
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

    func fetchFossils(filters: FossilFilters = FossilFilters()) async {
        currentFetchTask?.cancel()

        currentFetchTask = Task {
            if Task.isCancelled { return }

            isLoading = true
            error = nil

            do {
                var endpoint = "/fossil"
                var queryParams: [String] = []

                if let room = filters.room {
                    queryParams.append("room=\(room)")
                }

                if !queryParams.isEmpty {
                    endpoint += "?" + queryParams.joined(separator: "&")
                }

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                let response: FossilsResponse = try await apiManager.makeRequest(
                    endpoint: endpoint,
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: FossilsResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                fossils = response.fossils
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

    func fetchFossilImage(fossilId: String, partName: String) async -> FossilImage? {
        let cacheKey = "\(fossilId)_\(partName)"

        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }

        do {
            let endpoint = "/fossil/\(fossilId)/img/\(partName)"

            let response: FossilImageResponse = try await apiManager.makeRequest(
                endpoint: endpoint,
                requiresAuth: false,
                responseType: FossilImageResponse.self
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
        fossilDetailsCache.removeAll()
    }

    func clearAllCaches() {
        clearImageCache()
        clearDetailsCache()
    }
}

struct FossilFilters {
    var room: Int?
}
