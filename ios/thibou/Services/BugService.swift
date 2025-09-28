import Foundation
import Combine

@MainActor
class BugService: ObservableObject, CacheManaging {
    typealias ImageType = BugImage
    typealias DetailType = Bug
    static let shared = BugService()

    @Published var bugSummaries: [BugSummary] = []
    @Published var bugs: [Bug] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiManager = APIManager.shared
    private var currentFetchTask: Task<Void, Never>?
    private var currentSummariesTask: Task<Void, Never>?

    private var imageCache: [String: BugImage] = [:]
    private var bugDetailsCache: [String: Bug] = [:]

    private init() {}

    func fetchBugById(id: String) async -> Bug? {
        if let cached = bugDetailsCache[id] {
            return cached
        }

        do {
            let response: BugDetailResponse = try await apiManager.makeRequest(
                endpoint: "/bug/\(id)",
                requiresAuth: AuthManager.shared.isLoggedIn,
                responseType: BugDetailResponse.self
            )
            bugDetailsCache[id] = response.bug
            return response.bug
        } catch {
            return nil
        }
    }

    func fetchBugSummaries() async {
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

                let response: BugsResponse = try await apiManager.makeRequest(
                    endpoint: "/bug",
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: BugsResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                bugSummaries = response.bugs.map { BugSummary(from: $0) }
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

    func fetchBugs(filters: BugFilters = BugFilters()) async {
        currentFetchTask?.cancel()

        currentFetchTask = Task {
            if Task.isCancelled { return }

            isLoading = true
            error = nil

            do {
                var endpoint = "/bug"
                var queryParams: [String] = []

                if let location = filters.location {
                    queryParams.append("location=\(location)")
                }
                if let weather = filters.weather {
                    queryParams.append("weather=\(weather)")
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

                let response: BugsResponse = try await apiManager.makeRequest(
                    endpoint: endpoint,
                    requiresAuth: AuthManager.shared.isLoggedIn,
                    responseType: BugsResponse.self
                )

                if Task.isCancelled {
                    isLoading = false
                    return
                }

                bugs = response.bugs
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

    func fetchBugImage(bugId: String, imageType: String) async -> BugImage? {
        let cacheKey = "\(bugId)_\(imageType)"

        if let cachedImage = imageCache[cacheKey] {
            return cachedImage
        }

        do {
            let endpoint = "/bug/\(bugId)/img/\(imageType)"

            let response: BugImageResponse = try await apiManager.makeRequest(
                endpoint: endpoint,
                requiresAuth: false,
                responseType: BugImageResponse.self
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
        bugDetailsCache.removeAll()
    }

    func clearAllCaches() {
        clearImageCache()
        clearDetailsCache()
    }
}

struct BugFilters {
    var location: String?
    var weather: String?
    var rarity: String?
    var search: String?
}