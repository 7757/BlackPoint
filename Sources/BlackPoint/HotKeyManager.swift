import AppKit
import Carbon

@MainActor
final class HotKeyManager {
    struct RegistrationIssue: Equatable {
        let action: ShortcutAction
        let shortcut: GlobalShortcut
        let status: OSStatus
    }

    private struct Registration {
        let reference: EventHotKeyRef
        let action: ShortcutAction
    }

    private var registrations: [UInt32: Registration] = [:]
    private var handlerReference: EventHandlerRef?
    private let callback: (ShortcutAction) -> Void

    init(callback: @escaping (ShortcutAction) -> Void) {
        self.callback = callback
        installHandler()
    }

    @discardableResult
    func apply(settings: AppSettings) -> [RegistrationIssue] {
        unregisterAllHotKeys()

        var issues: [RegistrationIssue] = []
        for action in ShortcutAction.allCases {
            if action.isCommandTabFilterAction && !settings.commandTabFilteringEnabled {
                continue
            }

            let shortcut = settings.shortcut(for: action)
            if let issue = register(shortcut: shortcut, id: UInt32(action.registrationID), action: action) {
                issues.append(issue)
            }
        }

        return issues
    }

    deinit {
        for registration in registrations.values {
            UnregisterEventHotKey(registration.reference)
        }
        registrations.removeAll()

        if let handlerReference {
            RemoveEventHandler(handlerReference)
        }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard
                    let event,
                    let userData
                else {
                    return OSStatus(eventNotHandledErr)
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.invoke(id: hotKeyID.id)
                }

                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &handlerReference
        )
    }

    private func register(shortcut: GlobalShortcut, id: UInt32, action: ShortcutAction) -> RegistrationIssue? {
        var hotKeyReference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard status == noErr, let hotKeyReference else {
            return RegistrationIssue(action: action, shortcut: shortcut, status: status)
        }

        registrations[id] = Registration(reference: hotKeyReference, action: action)
        return nil
    }

    private func invoke(id: UInt32) {
        guard let action = registrations[id]?.action else {
            return
        }

        callback(action)
    }

    private func unregisterAllHotKeys() {
        for registration in registrations.values {
            UnregisterEventHotKey(registration.reference)
        }
        registrations.removeAll()
    }

    private static let signature: OSType = {
        let scalars = Array("BLKP".unicodeScalars)
        return scalars.reduce(0) { result, scalar in
            (result << 8) + OSType(scalar.value)
        }
    }()
}

private extension ShortcutAction {
    var registrationID: Int {
        switch self {
        case .hideFrontmost:
            1
        case .togglePanel:
            2
        case .hideOtherRunning:
            3
        case .switchNextAllowed:
            4
        case .switchPreviousAllowed:
            5
        }
    }
}
