import Foundation

protocol CacheManaging {
    associatedtype ImageType
    associatedtype DetailType

    func clearImageCache()
    func clearDetailsCache()
}

extension CacheManaging {
    func clearImageCache() {
    }

    func clearDetailsCache() {
    }
}