import Foundation

struct SettingsStore {
    enum StoreError: Error {
        case unreadableData
    }

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, storageKey: String = AppSettings.storageKey) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func load() throws -> AppSettings {
        guard let data = defaults.data(forKey: storageKey) else {
            return AppSettings()
        }

        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            throw StoreError.unreadableData
        }
    }

    func save(_ settings: AppSettings) throws {
        let data = try encoder.encode(settings)
        defaults.set(data, forKey: storageKey)
    }
}
