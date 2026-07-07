import AppKit
import SwiftUI

@MainActor
final class StatusPopoverController: NSObject {
    private static let popoverContentSize = NSSize(width: 332, height: 442)

    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let controller: BlackHoleController

    init(controller: BlackHoleController) {
        self.controller = controller
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        super.init()

        configureStatusItem()
        configurePopover()
    }

    func toggle() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show()
        }
    }

    func show() {
        guard let button = statusItem.button else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        popover.contentSize = Self.popoverContentSize
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        anchorPopover(to: button)

        DispatchQueue.main.async { [weak self, weak button] in
            guard let button else {
                return
            }
            self?.anchorPopover(to: button)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak button] in
            guard let button else {
                return
            }
            self?.anchorPopover(to: button)
        }
    }

    func refreshLocalizedContent() {
        statusItem.button?.toolTip = L10n.text("status_item_tooltip")
        popover.contentViewController = NSHostingController(
            rootView: ContentView(controller: controller)
                .frame(width: Self.popoverContentSize.width, height: Self.popoverContentSize.height)
        )
        if popover.isShown, let button = statusItem.button {
            anchorPopover(to: button)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = StatusIcon.make()
        button.image?.isTemplate = true
        button.action = #selector(statusItemClicked)
        button.target = self
        button.toolTip = L10n.text("status_item_tooltip")
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = Self.popoverContentSize
        popover.contentViewController = NSHostingController(
            rootView: ContentView(controller: controller)
                .frame(width: Self.popoverContentSize.width, height: Self.popoverContentSize.height)
        )
    }

    @objc private func statusItemClicked() {
        toggle()
    }

    private func anchorPopover(to button: NSStatusBarButton) {
        guard
            popover.isShown,
            let buttonWindow = button.window,
            let popoverWindow = popover.contentViewController?.view.window
        else {
            return
        }

        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let buttonRect = buttonWindow.convertToScreen(buttonRectInWindow)
        let screen = buttonWindow.screen
            ?? NSScreen.screens.first(where: { $0.frame.intersects(buttonRect) })
            ?? NSScreen.main

        guard let screen else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let margin: CGFloat = 6
        let popoverSize = popoverWindow.frame.size == .zero
            ? Self.popoverContentSize
            : popoverWindow.frame.size

        var origin = NSPoint(
            x: buttonRect.midX - popoverSize.width / 2,
            y: buttonRect.minY - popoverSize.height - margin
        )

        origin.x = min(
            max(origin.x, visibleFrame.minX + margin),
            visibleFrame.maxX - popoverSize.width - margin
        )
        origin.y = min(
            max(origin.y, visibleFrame.minY + margin),
            visibleFrame.maxY - popoverSize.height - margin
        )

        popoverWindow.setFrameOrigin(origin)
    }
}

private enum StatusIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        let center = NSPoint(x: 9, y: 9)

        func withRotation(_ degrees: CGFloat, draw: () -> Void) {
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.translateX(by: center.x, yBy: center.y)
            transform.rotate(byDegrees: degrees)
            transform.translateX(by: -center.x, yBy: -center.y)
            transform.concat()
            draw()
            NSGraphicsContext.restoreGraphicsState()
        }

        NSColor.white.withAlphaComponent(0.95).setStroke()
        withRotation(-18) {
            let disk = NSBezierPath(ovalIn: NSRect(x: 2.1, y: 6.0, width: 13.8, height: 6.0))
            disk.lineWidth = 1.30
            disk.lineCapStyle = .round
            disk.stroke()
        }

        NSColor.white.withAlphaComponent(0.46).setStroke()
        withRotation(-22) {
            let outerDisk = NSBezierPath(ovalIn: NSRect(x: 1.3, y: 5.1, width: 15.4, height: 7.8))
            outerDisk.lineWidth = 0.75
            outerDisk.lineCapStyle = .round
            outerDisk.stroke()
        }

        NSColor.white.withAlphaComponent(0.72).setStroke()
        withRotation(-10) {
            let innerDisk = NSBezierPath(ovalIn: NSRect(x: 4.6, y: 6.7, width: 8.8, height: 4.7))
            innerDisk.lineWidth = 0.85
            innerDisk.lineCapStyle = .round
            innerDisk.stroke()
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(ovalIn: NSRect(x: 5.65, y: 5.65, width: 6.7, height: 6.7)).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.88).setStroke()
        let horizon = NSBezierPath(ovalIn: NSRect(x: 6.2, y: 6.2, width: 5.6, height: 5.6))
        horizon.lineWidth = 1.05
        horizon.stroke()

        NSColor.white.withAlphaComponent(0.72).setFill()
        NSBezierPath(ovalIn: NSRect(x: 13.6, y: 10.7, width: 1.3, height: 1.3)).fill()
        NSColor.white.withAlphaComponent(0.46).setFill()
        NSBezierPath(ovalIn: NSRect(x: 3.5, y: 5.1, width: 1.0, height: 1.0)).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
