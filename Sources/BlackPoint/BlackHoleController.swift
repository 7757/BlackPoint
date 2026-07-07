import AppKit
import BlackPointCore
import Combine

@MainActor
final class BlackHoleController: ObservableObject {
    @Published private(set) var blockedApplications: [BlockedApplication] = []
    @Published private(set) var runningApplications: [RunningApplicationSnapshot] = []
    @Published private(set) var settings: AppSettings
    @Published private(set) var loginItemSnapshot: LoginItemSnapshot
    @Published var lastMessage: String?

    private let store: BlackHoleStore
    private let settingsStore: SettingsStore
    private let loginItemManager: LoginItemManager
    private var observers: [NSObjectProtocol] = []
    private var lastActiveApplicationBundleIdentifier: String?
    private var activationHistoryBundleIdentifiers: [String] = []
    private weak var popoverController: StatusPopoverController?
    var hotKeyConfigurationHandler: ((AppSettings) -> Void)?

    init(
        store: BlackHoleStore = BlackHoleStore(),
        settingsStore: SettingsStore = SettingsStore(),
        loginItemManager: LoginItemManager = LoginItemManager()
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.loginItemManager = loginItemManager
        let loadedSettings = (try? settingsStore.load()) ?? AppSettings()
        self.settings = loadedSettings
        L10n.configure(language: loadedSettings.appLanguage)
        self.loginItemSnapshot = loginItemManager.snapshot()
        reloadStoredApplications()
        refreshRunningApplications()
        remember(application: NSWorkspace.shared.frontmostApplication)
        installWorkspaceObservers()
        enforceBlackHole()
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
    }

    func attach(popoverController: StatusPopoverController) {
        self.popoverController = popoverController
    }

    func refreshRunningApplications() {
        runningApplications = NSWorkspace.shared.runningApplications
            .compactMap(RunningApplicationSnapshot.init(application:))
            .filter { snapshot in
                !blockedApplications.contains { $0.bundleIdentifier == snapshot.bundleIdentifier }
            }
            .sorted { lhs, rhs in
                lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
            }
    }

    func togglePanel() {
        popoverController?.toggle()
    }

    func showPanel() {
        popoverController?.show()
    }

    func hideFrontmostApplication() {
        guard let application = currentHideCandidate() else {
            lastMessage = L10n.text("message_no_frontmost")
            return
        }

        add(application: application)
    }

    func hideOtherRunningApplications() {
        let preservedBundleIdentifier = currentHideCandidate()?.bundleIdentifier
        let candidates = NSWorkspace.shared.runningApplications
            .compactMap(RunningApplicationSnapshot.init(application:))
            .filter { snapshot in
                snapshot.bundleIdentifier != preservedBundleIdentifier
                    && !blockedApplications.contains { $0.bundleIdentifier == snapshot.bundleIdentifier }
            }

        guard !candidates.isEmpty else {
            enforceBlackHole()
            lastMessage = L10n.text("message_no_running_to_hide")
            return
        }

        let additions = candidates.map { $0.blockedApplication() }
        blockedApplications = BlackHoleStore.uniqued(blockedApplications + additions)
        persist()

        for snapshot in candidates {
            hide(bundleIdentifier: snapshot.bundleIdentifier)
        }

        refreshRunningApplications()
        lastMessage = String(format: L10n.text("message_added_many_to_blackhole"), candidates.count)
    }

    func switchToNextAllowedApplication(reverse: Bool = false) {
        guard settings.commandTabFilteringEnabled else {
            return
        }

        refreshRunningApplications()

        let allowedBundleIdentifiers = Set(runningApplications.map(\.bundleIdentifier))
        guard !allowedBundleIdentifiers.isEmpty else {
            lastMessage = L10n.text("message_no_switch_target")
            return
        }

        let currentBundleIdentifier = currentHideCandidate()?.bundleIdentifier
        let orderedBundleIdentifiers = orderedSwitchCandidates(
            allowedBundleIdentifiers: allowedBundleIdentifiers,
            currentBundleIdentifier: currentBundleIdentifier,
            reverse: reverse
        )

        guard
            let bundleIdentifier = orderedBundleIdentifiers.first,
            let application = runningApplication(bundleIdentifier: bundleIdentifier)
        else {
            lastMessage = L10n.text("message_no_switch_target")
            return
        }

        application.unhide()
        application.activate(options: [])
        remember(application: application)
        lastMessage = String(format: L10n.text("message_switched_to"), application.localizedName ?? bundleIdentifier)
    }

    func add(snapshot: RunningApplicationSnapshot) {
        guard let application = runningApplication(bundleIdentifier: snapshot.bundleIdentifier) else {
            add(blockedApplication: snapshot.blockedApplication())
            return
        }

        add(application: application)
    }

    func add(application: NSRunningApplication) {
        guard let snapshot = RunningApplicationSnapshot(application: application) else {
            lastMessage = L10n.text("message_cannot_hide_app")
            return
        }

        add(blockedApplication: snapshot.blockedApplication())
        hide(bundleIdentifier: snapshot.bundleIdentifier)
        lastMessage = String(format: L10n.text("message_added_to_blackhole"), snapshot.localizedName)
    }

    func restore(_ app: BlockedApplication) {
        blockedApplications.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        persist()

        let applications = runningApplications(bundleIdentifier: app.bundleIdentifier)
        for application in applications {
            application.unhide()
            application.activate(options: [])
        }

        lastMessage = String(format: L10n.text("message_restored"), app.name)
        refreshRunningApplications()
    }

    func removeWithoutActivating(_ app: BlockedApplication) {
        blockedApplications.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        persist()
        lastMessage = String(format: L10n.text("message_removed"), app.name)
        refreshRunningApplications()
    }

    func restoreAll() {
        let apps = blockedApplications
        blockedApplications.removeAll()
        persist()

        for app in apps {
            for application in runningApplications(bundleIdentifier: app.bundleIdentifier) {
                application.unhide()
            }
        }

        lastMessage = L10n.text("message_restored_all")
        refreshRunningApplications()
    }

    func enforceBlackHole() {
        guard settings.autoRehideEnabled else {
            refreshRunningApplications()
            return
        }

        for app in blockedApplications {
            hide(bundleIdentifier: app.bundleIdentifier)
        }
        refreshRunningApplications()
    }

    func isRunning(_ app: BlockedApplication) -> Bool {
        !runningApplications(bundleIdentifier: app.bundleIdentifier).isEmpty
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        settings.launchAtLoginEnabled = enabled
        persistSettings()
        loginItemSnapshot = loginItemManager.setEnabled(enabled)

        switch loginItemSnapshot.status {
        case .enabled:
            lastMessage = L10n.text("message_login_enabled")
        case .disabled:
            lastMessage = L10n.text("message_login_disabled")
        case .requiresApproval:
            lastMessage = L10n.text("message_login_requires_approval")
        case .notFound, .unavailable:
            lastMessage = loginItemSnapshot.detail ?? L10n.text("message_login_unavailable")
        }
    }

    func setAutoRehideEnabled(_ enabled: Bool) {
        settings.autoRehideEnabled = enabled
        persistSettings()
        if enabled {
            enforceBlackHole()
        } else {
            refreshRunningApplications()
        }
        lastMessage = enabled ? L10n.text("message_auto_rehide_enabled") : L10n.text("message_auto_rehide_disabled")
    }

    func setCommandTabFilteringEnabled(_ enabled: Bool) {
        settings.commandTabFilteringEnabled = enabled
        persistSettings()
        hotKeyConfigurationHandler?(settings)
        lastMessage = enabled ? L10n.text("message_switch_filter_enabled") : L10n.text("message_switch_filter_disabled")
    }

    func setAppLanguage(_ language: AppLanguage) {
        L10n.configure(language: language)
        settings.appLanguage = language
        persistSettings()
        popoverController?.refreshLocalizedContent()
        loginItemSnapshot = loginItemManager.snapshot()
        lastMessage = L10n.text("message_language_updated")
    }

    func setShortcut(_ shortcut: GlobalShortcut, for action: ShortcutAction) {
        guard shortcut.isUsable else {
            lastMessage = L10n.text("message_shortcut_invalid")
            return
        }

        if let duplicate = ShortcutAction.allCases.first(where: { otherAction in
            otherAction != action && settings.shortcut(for: otherAction) == shortcut
        }) {
            lastMessage = String(format: L10n.text("message_shortcut_conflict"), duplicate.title)
            return
        }

        settings.setShortcut(shortcut, for: action)
        persistSettings()
        hotKeyConfigurationHandler?(settings)
        lastMessage = String(format: L10n.text("message_shortcut_updated"), action.title)
    }

    func resetShortcuts() {
        settings.resetShortcuts()
        persistSettings()
        hotKeyConfigurationHandler?(settings)
        lastMessage = L10n.text("message_shortcuts_reset")
    }

    func handleHotKeyRegistrationIssues(_ issues: [HotKeyManager.RegistrationIssue]) {
        guard let issue = issues.first else {
            return
        }

        lastMessage = String(
            format: L10n.text("message_shortcut_registration_failed"),
            issue.action.title,
            issue.shortcut.displayText
        )
    }

    func refreshLoginItemStatus() {
        loginItemSnapshot = loginItemManager.snapshot()
    }

    private func add(blockedApplication: BlockedApplication) {
        guard !blockedApplications.contains(where: { $0.bundleIdentifier == blockedApplication.bundleIdentifier }) else {
            hide(bundleIdentifier: blockedApplication.bundleIdentifier)
            return
        }

        blockedApplications.append(blockedApplication)
        blockedApplications = BlackHoleStore.uniqued(blockedApplications)
        persist()
        refreshRunningApplications()
    }

    private func reloadStoredApplications() {
        do {
            blockedApplications = try store.load()
        } catch {
            blockedApplications = []
            lastMessage = L10n.text("message_store_reset")
        }
    }

    private func persist() {
        do {
            try store.save(blockedApplications)
        } catch {
            lastMessage = L10n.text("message_store_failed")
        }
    }

    private func persistSettings() {
        do {
            try settingsStore.save(settings)
        } catch {
            lastMessage = L10n.text("message_settings_store_failed")
        }
    }

    private func hide(bundleIdentifier: String) {
        for application in runningApplications(bundleIdentifier: bundleIdentifier) {
            _ = application.hide()
        }
    }

    private func currentHideCandidate() -> NSRunningApplication? {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           RunningApplicationSnapshot(application: frontmost) != nil {
            remember(application: frontmost)
            return frontmost
        }

        if let lastActiveApplicationBundleIdentifier {
            return runningApplication(bundleIdentifier: lastActiveApplicationBundleIdentifier)
        }

        return nil
    }

    private func remember(application: NSRunningApplication?) {
        guard let snapshot = application.flatMap(RunningApplicationSnapshot.init(application:)) else {
            return
        }

        lastActiveApplicationBundleIdentifier = snapshot.bundleIdentifier
        activationHistoryBundleIdentifiers.removeAll { $0 == snapshot.bundleIdentifier }
        activationHistoryBundleIdentifiers.insert(snapshot.bundleIdentifier, at: 0)
    }

    private func orderedSwitchCandidates(
        allowedBundleIdentifiers: Set<String>,
        currentBundleIdentifier: String?,
        reverse: Bool
    ) -> [String] {
        let historyCandidates = activationHistoryBundleIdentifiers.filter { bundleIdentifier in
            allowedBundleIdentifiers.contains(bundleIdentifier)
                && bundleIdentifier != currentBundleIdentifier
        }

        let missingCandidates = runningApplications
            .map(\.bundleIdentifier)
            .filter { bundleIdentifier in
                allowedBundleIdentifiers.contains(bundleIdentifier)
                    && bundleIdentifier != currentBundleIdentifier
                    && !historyCandidates.contains(bundleIdentifier)
            }

        let candidates = historyCandidates + missingCandidates
        return reverse ? Array(candidates.reversed()) : candidates
    }

    private func runningApplication(bundleIdentifier: String) -> NSRunningApplication? {
        runningApplications(bundleIdentifier: bundleIdentifier).first
    }

    private func runningApplications(bundleIdentifier: String) -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleIdentifier }
    }

    private func installWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let notifications: [NSNotification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ]

        observers = notifications.map { name in
            center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    if name == NSWorkspace.didActivateApplicationNotification {
                        self?.remember(
                            application: notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                        )
                    }
                    self?.enforceBlackHole()
                }
            }
        }
    }
}
