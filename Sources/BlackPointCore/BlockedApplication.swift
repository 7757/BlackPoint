import Foundation

public struct BlockedApplication: Codable, Equatable, Identifiable, Hashable, Sendable {
    public let bundleIdentifier: String
    public var name: String
    public var path: String?
    public var addedAt: Date

    public var id: String { bundleIdentifier }

    public init(bundleIdentifier: String, name: String, path: String?, addedAt: Date = Date()) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        self.addedAt = addedAt
    }
}
