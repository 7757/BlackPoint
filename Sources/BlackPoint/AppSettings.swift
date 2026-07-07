import AppKit
import Carbon
import Foundation

struct AppSettings: Codable, Equatable {
    static let storageKey = "blackpoint.settings.v1"

    var launchAtLoginEnabled: Bool
    var autoRehideEnabled: Bool
    var commandTabFilteringEnabled: Bool
    var appLanguage: AppLanguage
    var shortcuts: [String: GlobalShortcut]

    init(
        launchAtLoginEnabled: Bool = false,
        autoRehideEnabled: Bool = true,
        commandTabFilteringEnabled: Bool = true,
        appLanguage: AppLanguage = .system,
        shortcuts: [String: GlobalShortcut] = ShortcutAction.defaultShortcuts
    ) {
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.autoRehideEnabled = autoRehideEnabled
        self.commandTabFilteringEnabled = commandTabFilteringEnabled
        self.appLanguage = appLanguage
        self.shortcuts = shortcuts
    }

    private enum CodingKeys: String, CodingKey {
        case launchAtLoginEnabled
        case autoRehideEnabled
        case commandTabFilteringEnabled
        case appLanguage
        case shortcuts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false
        autoRehideEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoRehideEnabled) ?? true
        commandTabFilteringEnabled = try container.decodeIfPresent(Bool.self, forKey: .commandTabFilteringEnabled) ?? true
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .system
        shortcuts = try container.decodeIfPresent([String: GlobalShortcut].self, forKey: .shortcuts) ?? ShortcutAction.defaultShortcuts
    }

    func shortcut(for action: ShortcutAction) -> GlobalShortcut {
        shortcuts[action.rawValue] ?? ShortcutAction.defaultShortcuts[action.rawValue]!
    }

    mutating func setShortcut(_ shortcut: GlobalShortcut, for action: ShortcutAction) {
        shortcuts[action.rawValue] = shortcut
    }

    mutating func resetShortcuts() {
        shortcuts = ShortcutAction.defaultShortcuts
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var localizationIdentifier: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        }
    }

    var displayName: String {
        switch self {
        case .system:
            L10n.text("language_system")
        case .english:
            L10n.text("language_english")
        case .simplifiedChinese:
            L10n.text("language_simplified_chinese")
        }
    }
}

enum ShortcutAction: String, Codable, CaseIterable, Identifiable {
    case hideFrontmost
    case hideOtherRunning
    case togglePanel
    case switchNextAllowed
    case switchPreviousAllowed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hideFrontmost:
            L10n.text("settings_shortcut_hide_frontmost")
        case .hideOtherRunning:
            L10n.text("settings_shortcut_hide_others")
        case .togglePanel:
            L10n.text("settings_shortcut_toggle_panel")
        case .switchNextAllowed:
            L10n.text("settings_shortcut_switch_next")
        case .switchPreviousAllowed:
            L10n.text("settings_shortcut_switch_previous")
        }
    }

    var isCommandTabFilterAction: Bool {
        self == .switchNextAllowed || self == .switchPreviousAllowed
    }

    static let defaultShortcuts: [String: GlobalShortcut] = [
        ShortcutAction.hideFrontmost.rawValue: GlobalShortcut(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: UInt32(cmdKey | optionKey | controlKey)
        ),
        ShortcutAction.hideOtherRunning.rawValue: GlobalShortcut(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(cmdKey | optionKey | controlKey)
        ),
        ShortcutAction.togglePanel.rawValue: GlobalShortcut(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(cmdKey | optionKey | controlKey)
        ),
        ShortcutAction.switchNextAllowed.rawValue: GlobalShortcut(
            keyCode: UInt32(kVK_Tab),
            modifiers: UInt32(cmdKey)
        ),
        ShortcutAction.switchPreviousAllowed.rawValue: GlobalShortcut(
            keyCode: UInt32(kVK_Tab),
            modifiers: UInt32(cmdKey | shiftKey)
        )
    ]
}

struct GlobalShortcut: Codable, Equatable, Hashable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayText: String {
        modifierDisplay + keyDisplay
    }

    var isUsable: Bool {
        modifiers != 0 && !keyDisplay.isEmpty
    }

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        guard event.type == .keyDown, event.keyCode != UInt16(kVK_Escape) else {
            return nil
        }

        self.keyCode = UInt32(event.keyCode)
        self.modifiers = event.modifierFlags.carbonHotKeyModifiers

        guard isUsable else {
            return nil
        }
    }

    private var modifierDisplay: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 {
            result += "^"
        }
        if modifiers & UInt32(optionKey) != 0 {
            result += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            result += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            result += "⌘"
        }
        return result
    }

    private var keyDisplay: String {
        Self.keyNames[keyCode] ?? "Key \(keyCode)"
    }

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Escape): "Esc",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓"
    ]
}

private extension NSEvent.ModifierFlags {
    var carbonHotKeyModifiers: UInt32 {
        var result: UInt32 = 0
        if contains(.command) {
            result |= UInt32(cmdKey)
        }
        if contains(.option) {
            result |= UInt32(optionKey)
        }
        if contains(.control) {
            result |= UInt32(controlKey)
        }
        if contains(.shift) {
            result |= UInt32(shiftKey)
        }
        return result
    }
}
