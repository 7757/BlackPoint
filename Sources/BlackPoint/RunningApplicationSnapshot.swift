import AppKit
import BlackPointCore

struct RunningApplicationSnapshot: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String
    let localizedName: String
    let path: String?
    let processIdentifier: pid_t
    let icon: NSImage?

    var id: String { bundleIdentifier }

    init?(application: NSRunningApplication) {
        guard
            application.activationPolicy == .regular,
            let bundleIdentifier = application.bundleIdentifier,
            bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return nil
        }

        self.bundleIdentifier = bundleIdentifier
        self.localizedName = application.localizedName ?? bundleIdentifier
        self.name = application.localizedName ?? bundleIdentifier
        self.path = application.bundleURL?.path
        self.processIdentifier = application.processIdentifier
        self.icon = application.icon
    }

    func blockedApplication(addedAt: Date = Date()) -> BlockedApplication {
        BlockedApplication(
            bundleIdentifier: bundleIdentifier,
            name: name,
            path: path,
            addedAt: addedAt
        )
    }
}
