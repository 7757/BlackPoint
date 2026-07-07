import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: BlackHoleController?
    private var popoverController: StatusPopoverController?
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = BlackHoleController()
        let popoverController = StatusPopoverController(controller: controller)
        controller.attach(popoverController: popoverController)

        let hotKeyManager = HotKeyManager { [weak controller] action in
            switch action {
            case .hideFrontmost:
                controller?.hideFrontmostApplication()
            case .hideOtherRunning:
                controller?.hideOtherRunningApplications()
            case .switchNextAllowed:
                controller?.switchToNextAllowedApplication()
            case .switchPreviousAllowed:
                controller?.switchToNextAllowedApplication(reverse: true)
            case .togglePanel:
                controller?.togglePanel()
            }
        }
        controller.hotKeyConfigurationHandler = { [weak controller, weak hotKeyManager] settings in
            let issues = hotKeyManager?.apply(settings: settings) ?? []
            controller?.handleHotKeyRegistrationIssues(issues)
        }
        controller.handleHotKeyRegistrationIssues(hotKeyManager.apply(settings: controller.settings))

        self.controller = controller
        self.popoverController = popoverController
        self.hotKeyManager = hotKeyManager
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
