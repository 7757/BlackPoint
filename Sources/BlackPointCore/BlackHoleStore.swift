import Foundation

public protocol KeyValueStoring: Sendable {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: KeyValueStoring {}

public struct BlackHoleStore: Sendable {
    public enum StoreError: Error, Equatable {
        case unreadableData
    }

    public static let defaultStorageKey = "blackpoint.blockedApplications.v1"

    private let defaults: KeyValueStoring
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(defaults: KeyValueStoring = UserDefaults.standard, storageKey: String = Self.defaultStorageKey) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> [BlockedApplication] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try decoder.decode([BlockedApplication].self, from: data)
        } catch {
            throw StoreError.unreadableData
        }
    }

    public func save(_ applications: [BlockedApplication]) throws {
        let uniqueApps = Self.uniqued(applications)
        let data = try encoder.encode(uniqueApps)
        defaults.set(data, forKey: storageKey)
    }

    public static func uniqued(_ applications: [BlockedApplication]) -> [BlockedApplication] {
        var seen = Set<String>()
        var result: [BlockedApplication] = []

        for app in applications {
            guard !seen.contains(app.bundleIdentifier) else {
                continue
            }

            seen.insert(app.bundleIdentifier)
            result.append(app)
        }

        return result.sorted { lhs, rhs in
            if lhs.addedAt == rhs.addedAt {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.addedAt < rhs.addedAt
        }
    }
}
