import Foundation
import ServiceManagement

struct LoginItemSnapshot: Equatable {
    enum Status: Equatable {
        case enabled
        case disabled
        case requiresApproval
        case notFound
        case unavailable
    }

    var status: Status
    var detail: String?

    static let unavailable = LoginItemSnapshot(status: .unavailable, detail: nil)
}

struct LoginItemManager {
    func snapshot() -> LoginItemSnapshot {
        guard #available(macOS 13.0, *) else {
            return .unavailable
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            return LoginItemSnapshot(status: .enabled, detail: nil)
        case .requiresApproval:
            return LoginItemSnapshot(status: .requiresApproval, detail: nil)
        case .notFound:
            return LoginItemSnapshot(status: .notFound, detail: nil)
        case .notRegistered:
            return LoginItemSnapshot(status: .disabled, detail: nil)
        @unknown default:
            return .unavailable
        }
    }

    func setEnabled(_ enabled: Bool) -> LoginItemSnapshot {
        guard #available(macOS 13.0, *) else {
            return LoginItemSnapshot(status: .unavailable, detail: L10n.text("settings_login_unavailable"))
        }

        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status != .notRegistered {
                    try SMAppService.mainApp.unregister()
                }
            }
            return snapshot()
        } catch {
            return LoginItemSnapshot(status: snapshot().status, detail: error.localizedDescription)
        }
    }
}
