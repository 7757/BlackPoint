import AppKit
import BlackPointCore
import Carbon
import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: BlackHoleController
    @State private var selectedTab: Tab = .blackHole

    fileprivate enum Tab: String, CaseIterable, Identifiable, CompactTabItem {
        case blackHole
        case running
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .blackHole:
                L10n.text("tab_blackhole")
            case .running:
                L10n.text("tab_running")
            case .settings:
                L10n.text("tab_settings")
            }
        }
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.018, blue: 0.022),
                    Color(red: 0.045, green: 0.046, blue: 0.055)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.94)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                CompactTabBar(selection: $selectedTab, tabs: Tab.allCases)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                Group {
                    switch selectedTab {
                    case .blackHole:
                        blackHoleList
                    case .running:
                        runningList
                    case .settings:
                        settingsView
                    }
                }
                .animation(.snappy(duration: 0.24), value: selectedTab)
            }
        }
        .foregroundStyle(.white)
        .onAppear {
            controller.refreshRunningApplications()
            controller.enforceBlackHole()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            MiniBlackHoleMark()
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: L10n.text("app_name"))
                    .font(.system(size: 15.5, weight: .semibold))
                Text(verbatim: L10n.text("subtitle"))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
            }

            Spacer()

            HeaderActionButton(
                title: L10n.text("hide_others_tip_title"),
                message: L10n.text("hide_others_tip_message"),
                subtle: true
            ) {
                controller.hideOtherRunningApplications()
            } label: {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 12.5, weight: .medium))
            }

            HeaderActionButton(
                title: L10n.text("hide_frontmost_tip_title"),
                message: L10n.text("hide_frontmost_tip_message")
            ) {
                controller.hideFrontmostApplication()
            } label: {
                Image(systemName: "circle.dotted.and.circle")
                    .font(.system(size: 12.5, weight: .medium))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }

    private var blackHoleList: some View {
        ScrollView {
            LazyVStack(spacing: 7) {
                if controller.blockedApplications.isEmpty {
                    BlackHoleHeroEmptyState {
                        withAnimation(.snappy(duration: 0.22)) {
                            selectedTab = .running
                        }
                    }
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 8) {
                        Text(verbatim: L10n.text("blackhole_count"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))

                        Text(verbatim: "\(controller.blockedApplications.count)")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.055))
                            .clipShape(Capsule())

                        Spacer()

                        Button {
                            controller.restoreAll()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(IconButtonStyle(subtle: true))
                        .help(L10n.text("restore_all"))
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)

                    ForEach(controller.blockedApplications) { app in
                        BlockedApplicationRow(
                            app: app,
                            isRunning: controller.isRunning(app),
                            restore: { controller.restore(app) },
                            remove: { controller.removeWithoutActivating(app) }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .animation(.snappy(duration: 0.22), value: controller.blockedApplications)
    }

    private var runningList: some View {
        ScrollView {
            LazyVStack(spacing: 7) {
                if controller.runningApplications.isEmpty {
                    EmptyStateView(
                        icon: "app.badge.checkmark",
                        showsBlackHoleAnimation: false,
                        title: L10n.text("empty_running_title"),
                        message: L10n.text("empty_running_message"),
                        actionIcon: nil,
                        actionHelp: nil,
                        action: nil
                    )
                    .padding(.top, 44)
                } else {
                    HStack(spacing: 9) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(verbatim: L10n.text("running_quick_action_title"))
                                .font(.system(size: 11.5, weight: .semibold))
                            Text(verbatim: L10n.text("running_quick_action_message"))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.38))
                                .lineLimit(2)
                        }

                        Spacer()

                        Button {
                            controller.hideOtherRunningApplications()
                        } label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(IconButtonStyle())
                        .help(L10n.text("hide_others_help"))
                    }
                    .modifier(RowSurface())

                    ForEach(controller.runningApplications) { app in
                        RunningApplicationRow(
                            app: app,
                            add: { controller.add(snapshot: app) }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .animation(.snappy(duration: 0.22), value: controller.runningApplications)
    }

    private var settingsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 7) {
                SettingsSectionTitle(title: L10n.text("settings_section_general"))

                SettingsLanguageRow(
                    selectedLanguage: controller.settings.appLanguage,
                    select: { controller.setAppLanguage($0) }
                )

                SettingsSectionTitle(title: L10n.text("settings_section_startup"))

                SettingsToggleRow(
                    title: L10n.text("settings_launch_at_login"),
                    message: loginStatusText,
                    isOn: Binding(
                        get: { controller.settings.launchAtLoginEnabled },
                        set: { controller.setLaunchAtLoginEnabled($0) }
                    )
                )

                SettingsSectionTitle(title: L10n.text("settings_section_behavior"))

                SettingsToggleRow(
                    title: L10n.text("settings_auto_rehide"),
                    message: L10n.text("settings_auto_rehide_message"),
                    isOn: Binding(
                        get: { controller.settings.autoRehideEnabled },
                        set: { controller.setAutoRehideEnabled($0) }
                    )
                )

                SettingsToggleRow(
                    title: L10n.text("settings_filter_command_tab"),
                    message: L10n.text("settings_filter_command_tab_message"),
                    isOn: Binding(
                        get: { controller.settings.commandTabFilteringEnabled },
                        set: { controller.setCommandTabFilteringEnabled($0) }
                    )
                )

                SettingsSectionTitle(title: L10n.text("settings_section_shortcuts"))

                ForEach(ShortcutAction.allCases) { action in
                    if !action.isCommandTabFilterAction || controller.settings.commandTabFilteringEnabled {
                        ShortcutSettingsRow(controller: controller, action: action)
                    }
                }

                Button {
                    controller.resetShortcuts()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10.5, weight: .bold))
                        Text(verbatim: L10n.text("settings_reset_shortcuts"))
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(SecondaryTextButtonStyle())
                .padding(.top, 1)

                SettingsSectionTitle(title: L10n.text("settings_section_notes"))

                SettingsInfoRow(
                    icon: "keyboard",
                    title: L10n.text("settings_shortcut_summary"),
                    message: "\(controller.settings.shortcut(for: .hideFrontmost).displayText) · \(L10n.text("settings_action_hide_frontmost"))\n\(controller.settings.shortcut(for: .hideOtherRunning).displayText) · \(L10n.text("settings_action_hide_others"))"
                )

                SettingsInfoRow(
                    icon: "command",
                    title: L10n.text("settings_command_tab_note_title"),
                    message: L10n.text("system_limit_note")
                )
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .onAppear {
            controller.refreshLoginItemStatus()
        }
    }

    private var loginStatusText: String {
        switch controller.loginItemSnapshot.status {
        case .enabled:
            L10n.text("settings_login_enabled")
        case .disabled:
            L10n.text("settings_login_disabled")
        case .requiresApproval:
            L10n.text("settings_login_requires_approval")
        case .notFound:
            L10n.text("settings_login_not_found")
        case .unavailable:
            L10n.text("settings_login_unavailable")
        }
    }
}

private struct HeaderActionButton<Label: View>: View {
    let title: String
    let message: String
    var subtle = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action, label: label)
            .buttonStyle(IconButtonStyle(subtle: subtle))
            .overlay(alignment: .bottomTrailing) {
                if isHovered {
                    InstantTooltip(title: title, message: message)
                        .offset(y: 35)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topTrailing)))
                        .allowsHitTesting(false)
                }
            }
            .zIndex(isHovered ? 10 : 0)
            .onHover { hovering in
                withAnimation(.snappy(duration: 0.10)) {
                    isHovered = hovering
                }
            }
    }
}

private struct InstantTooltip: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)

            Text(verbatim: message)
                .font(.system(size: 9.4, weight: .medium))
                .foregroundStyle(.white.opacity(0.50))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 188, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.black.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
    }
}

private struct RunningApplicationRow: View {
    let app: RunningApplicationSnapshot
    let add: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(image: app.icon, size: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: app.localizedName)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                Text(verbatim: app.bundleIdentifier)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 11.5, weight: .medium))
            }
            .buttonStyle(IconButtonStyle())
            .help(L10n.text("add_to_blackhole"))
        }
        .modifier(RowSurface())
    }
}

private struct MiniBlackHoleMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.012, green: 0.014, blue: 0.026),
                            Color(red: 0.040, green: 0.046, blue: 0.075)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 0.7)
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.56, green: 0.70, blue: 1.0).opacity(0.26),
                            Color(red: 0.26, green: 0.24, blue: 0.52).opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 18
                    )
                )
                .blur(radius: 1.2)

            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.52, green: 0.76, blue: 1.0).opacity(0.18),
                            Color(red: 1.0, green: 0.74, blue: 0.45).opacity(0.74),
                            Color(red: 0.78, green: 0.48, blue: 1.0).opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.15
                )
                .frame(width: 23, height: 8.5)
                .rotationEffect(.degrees(-18))

            Ellipse()
                .stroke(
                    Color(red: 0.72, green: 0.84, blue: 1.0).opacity(0.26),
                    lineWidth: 0.7
                )
                .frame(width: 18, height: 6.5)
                .rotationEffect(.degrees(-12))

            Circle()
                .fill(.black.opacity(0.98))
                .frame(width: 8.5, height: 8.5)
                .shadow(color: Color(red: 0.52, green: 0.70, blue: 1.0).opacity(0.34), radius: 3)

            Circle()
                .fill(Color(red: 0.86, green: 0.92, blue: 1.0).opacity(0.82))
                .frame(width: 1.6, height: 1.6)
                .offset(x: 8.2, y: -2.8)
        }
    }
}

private struct BlockedApplicationRow: View {
    let app: BlockedApplication
    let isRunning: Bool
    let restore: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.04))
                Image(systemName: isRunning ? "eye.slash.fill" : "powerplug.portrait")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(isRunning ? .white.opacity(0.72) : .white.opacity(0.38))
            }
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(verbatim: app.name)
                        .font(.system(size: 12.5, weight: .medium))
                        .lineLimit(1)

                    Text(verbatim: isRunning ? L10n.text("status_hidden") : L10n.text("status_not_running"))
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(isRunning ? Color(red: 1.0, green: 0.77, blue: 0.38).opacity(0.9) : .white.opacity(0.42))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isRunning ? Color(red: 1.0, green: 0.62, blue: 0.18).opacity(0.12) : .white.opacity(0.045))
                        .clipShape(Capsule())
                }

                Text(verbatim: app.bundleIdentifier)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.32))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: restore) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 11.5, weight: .medium))
            }
            .buttonStyle(IconButtonStyle())
            .help(L10n.text("restore"))

            Button(action: remove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .buttonStyle(IconButtonStyle(subtle: true))
            .help(L10n.text("remove"))
        }
        .modifier(RowSurface())
    }
}

private struct EmptyStateView: View {
    let icon: String?
    let showsBlackHoleAnimation: Bool
    let title: String?
    let message: String?
    let actionIcon: String?
    let actionHelp: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 11) {
            if showsBlackHoleAnimation {
                BlackHoleAnimationView()
                    .frame(width: 126, height: 96)
                    .padding(.bottom, 2)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            if let title {
                Text(verbatim: title)
                    .font(.system(size: 14, weight: .semibold))
            }

            if let message {
                Text(verbatim: message)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: 230)
            }

            if let actionIcon, let action {
                Button(action: action) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(IconButtonStyle(subtle: true))
                .help(actionHelp ?? "")
                .padding(.top, 2)
            }
        }
    }
}

private struct BlackHoleHeroEmptyState: View {
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            BlackHoleAnimationView()
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .scaleEffect(1.16)
                .offset(y: -5)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.12),
                            .init(color: .black, location: 0.78),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 10) {
                Button(action: action) {
                    HStack(spacing: 7) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 10.5, weight: .medium))
                        Text(verbatim: L10n.text("empty_blackhole_choose_running"))
                            .font(.system(size: 10.5, weight: .medium))
                    }
                }
                .buttonStyle(CapsuleActionButtonStyle(minWidth: 132, minHeight: 34))
            }
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 254)
    }
}

private protocol CompactTabItem: Identifiable, Hashable {
    var title: String { get }
}

private struct CompactTabBar<Tab: CompactTabItem>: View {
    @Binding var selection: Tab
    let tabs: [Tab]
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                CompactTabButton(
                    tab: tab,
                    selection: $selection,
                    namespace: namespace
                )
            }
        }
        .padding(2)
        .background(.white.opacity(0.018))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.025), lineWidth: 1)
        )
    }
}

private struct CompactTabButton<Tab: CompactTabItem>: View {
    let tab: Tab
    @Binding var selection: Tab
    let namespace: Namespace.ID
    @State private var isHovered = false

    private var isSelected: Bool {
        selection == tab
    }

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                selection = tab
            }
        } label: {
            Text(verbatim: tab.title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white.opacity(0.90) : .white.opacity(isHovered ? 0.62 : 0.40))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 30)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.060))
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                            .shadow(color: Color(red: 0.55, green: 0.72, blue: 1.0).opacity(0.10), radius: 8, y: 1)
                    } else if isHovered {
                        Capsule()
                            .fill(.white.opacity(0.034))
                    }
                }
        }
        .buttonStyle(PressScaleButtonStyle(hovered: isHovered, hoverScale: 1.015, pressedScale: 0.975))
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.snappy(duration: 0.16)) {
                isHovered = hovering
            }
        }
        .animation(.snappy(duration: 0.16), value: isHovered)
        .animation(.snappy(duration: 0.18), value: isSelected)
    }
}

private struct BlackHoleAnimationView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width * 0.50, y: size.height * 0.48)
                let radius = min(size.width * 0.46, size.height * 0.64)
                let breath = breathingPulse(time)
                let breathingRadius = radius * CGFloat(0.988 + breath * 0.032)
                let tilt = -0.18
                    + sin(time * 0.075) * 0.026
                    + sin(time * 0.031 + 1.7) * 0.012

                drawStarField(context: &context, size: size, center: center, radius: breathingRadius, time: time)
                drawNebula(context: &context, center: center, radius: breathingRadius, breath: breath, time: time)
                drawFarWaves(context: &context, center: center, radius: breathingRadius, breath: breath, tilt: tilt, time: time)
                drawAccretionDisk(context: &context, center: center, radius: breathingRadius, breath: breath, tilt: tilt, time: time)
                drawSpiralDust(context: &context, center: center, radius: breathingRadius, breath: breath, tilt: tilt, time: time)
                drawEventHorizon(context: &context, center: center, radius: breathingRadius, breath: breath, tilt: tilt, time: time)
            }
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }

    private func drawStarField(
        context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint,
        radius: CGFloat,
        time: TimeInterval
    ) {
        for index in 0..<120 {
            let xSeed = seed(index, channel: 0.17)
            let ySeed = seed(index, channel: 0.41)
            let pulseSeed = seed(index, channel: 0.73)
            let point = CGPoint(
                x: CGFloat(xSeed) * size.width,
                y: CGFloat(ySeed) * size.height
            )
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < radius * 0.34 {
                continue
            }

            let twinkle = 0.48 + 0.52 * sin(time * (0.22 + pulseSeed * 0.24) + pulseSeed * 18)
            let alpha = (0.025 + pulseSeed * 0.10) * max(0.25, twinkle)
            let dotSize = CGFloat(0.45 + pulseSeed * 0.95)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - dotSize / 2,
                    y: point.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )),
                with: .color(Color(red: 0.82, green: 0.88, blue: 1.0).opacity(alpha))
            )
        }
    }

    private func drawNebula(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        breath: Double,
        time: TimeInterval
    ) {
        let breathing = 0.80 + 0.30 * breath
        let nebulaScale = CGFloat(0.96 + breath * 0.10)

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: radius * 0.10))

            layer.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius * 1.45 * nebulaScale,
                    y: center.y - radius * 0.82 * nebulaScale,
                    width: radius * 2.9 * nebulaScale,
                    height: radius * 1.64 * nebulaScale
                )),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.13 * breathing), location: 0.0),
                        .init(color: Color(red: 0.33, green: 0.58, blue: 1.0).opacity(0.060 * breathing), location: 0.24),
                        .init(color: Color(red: 0.78, green: 0.28, blue: 1.0).opacity(0.030 * breathing), location: 0.58),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: center,
                    startRadius: radius * 0.04,
                    endRadius: radius * 1.42
                )
            )

            let drift = CGFloat(sin(time * 0.09) + sin(time * 0.043 + 2.4) * 0.45) * radius * 0.08
            layer.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius * 1.1 + drift,
                    y: center.y - radius * 0.58,
                    width: radius * 2.2,
                    height: radius * 1.16
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 1.0, green: 0.70, blue: 0.44).opacity(0.036 * breathing),
                        Color(red: 0.42, green: 0.72, blue: 1.0).opacity(0.022 * breathing),
                        .clear
                    ]),
                    center: CGPoint(x: center.x + drift, y: center.y),
                    startRadius: radius * 0.16,
                    endRadius: radius * 1.08
                )
            )
        }
    }

    private func drawFarWaves(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        breath: Double,
        tilt: Double,
        time: TimeInterval
    ) {
        let waveBreath = 0.76 + breath * 0.32

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 3.8))

            for index in 0..<18 {
                let s = seed(index, channel: 1.2)
                let orbit = radius * CGFloat(0.66 + s * 0.72)
                let angle = time * (0.026 + s * 0.028)
                    + s * .pi * 2
                    + sin(time * (0.035 + s * 0.012) + s * 11) * 0.34
                let length = .pi * (0.34 + s * 0.74 + 0.06 * sin(time * 0.05 + s * 7))
                let path = ellipseArcPath(
                    center: center,
                    radiusX: orbit,
                    radiusY: orbit * CGFloat(0.23 + s * 0.10),
                    rotation: tilt + sin(time * (0.035 + s * 0.015) + s * 4) * 0.038,
                    start: angle,
                    length: length,
                    steps: 42
                )

                layer.stroke(
                    path,
                    with: .color(dustColor(index, alpha: (0.018 + s * 0.034) * waveBreath)),
                    lineWidth: CGFloat(0.65 + s * 1.2)
                )
            }
        }
    }

    private func drawAccretionDisk(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        breath: Double,
        tilt: Double,
        time: TimeInterval
    ) {
        let diskBreath = 0.78 + breath * 0.34

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6.2))

            for index in 0..<30 {
                let s = seed(index, channel: 2.4)
                let orbit = radius * CGFloat(0.42 + s * 0.48)
                let phase = time * (0.075 + s * 0.050)
                    + s * .pi * 2
                    + sin(time * (0.045 + s * 0.018) + s * 9) * 0.30
                let arcLength = .pi * (0.48 + s * 0.78 + 0.07 * sin(time * 0.042 + s * 13))
                let alpha = (0.045 + s * 0.062) * diskBreath
                let path = ellipseArcPath(
                    center: center,
                    radiusX: orbit,
                    radiusY: orbit * CGFloat(0.23 + s * 0.08),
                    rotation: tilt + sin(time * (0.030 + s * 0.010) + s * 6) * 0.018,
                    start: phase,
                    length: arcLength,
                    steps: 54
                )

                layer.stroke(
                    path,
                    with: .color(dustColor(index, alpha: alpha)),
                    lineWidth: CGFloat(1.4 + s * 3.4)
                )
            }
        }

        for index in 0..<46 {
            let s = seed(index, channel: 3.7)
            let orbit = radius * CGFloat(0.38 + s * 0.62)
            let speed = 0.12 + s * 0.095
            let phase = time * speed
                + s * .pi * 4
                + sin(time * (0.052 + s * 0.016) + s * 8) * 0.38
            let arcLength = .pi * (0.13 + s * 0.42 + 0.04 * sin(time * 0.06 + s * 17))
            let path = ellipseArcPath(
                center: center,
                radiusX: orbit,
                radiusY: orbit * CGFloat(0.23 + s * 0.12),
                rotation: tilt + sin(time * (0.052 + s * 0.020) + s * 3) * 0.024,
                start: phase,
                length: arcLength,
                steps: 28
            )

            context.stroke(
                path,
                with: .color(dustColor(index + 17, alpha: (0.08 + s * 0.16) * diskBreath)),
                lineWidth: CGFloat(0.36 + s * 0.85)
            )
        }

        let frontArc = ellipseArcPath(
            center: CGPoint(x: center.x, y: center.y + radius * 0.014),
            radiusX: radius * 0.72,
            radiusY: radius * 0.22,
            rotation: tilt,
            start: 0.05,
            length: .pi * 0.94,
            steps: 70
        )
        context.stroke(
            frontArc,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.50, green: 0.74, blue: 1.0).opacity(0.02),
                    Color(red: 1.0, green: 0.76, blue: 0.48).opacity(0.20 + breath * 0.14),
                    Color(red: 0.86, green: 0.60, blue: 1.0).opacity(0.055)
                ]),
                startPoint: CGPoint(x: center.x - radius * 0.75, y: center.y),
                endPoint: CGPoint(x: center.x + radius * 0.75, y: center.y)
            ),
            lineWidth: 1.2
        )
    }

    private func drawSpiralDust(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        breath: Double,
        tilt: Double,
        time: TimeInterval
    ) {
        let dustBreath = 0.82 + breath * 0.24

        for index in 0..<150 {
            let s = seed(index, channel: 4.9)
            let travel = (s + time * (0.018 + s * 0.017)).truncatingRemainder(dividingBy: 1)
            let eased = pow(1 - travel, 1.85)
            let wobble = sin(time * (0.10 + s * 0.045) + s * 31)
            let orbit = radius * CGFloat(0.16 + eased * (0.92 + s * 0.42) + wobble * 0.018)
            let angle = s * .pi * 8.0
                + time * (0.18 + s * 0.11)
                + travel * .pi * 2.1
                + sin(time * (0.070 + s * 0.025) + s * 19) * 0.24
            let yScale = CGFloat(0.26 + s * 0.10 + sin(time * 0.048 + s * 23) * 0.018)
            let alphaFade = sin(.pi * travel)
            let alpha = (0.035 + s * 0.17) * max(0, alphaFade) * dustBreath

            let head = pointOnEllipse(
                center: center,
                radiusX: orbit,
                radiusY: orbit * yScale,
                rotation: tilt,
                angle: angle
            )
            let tail = pointOnEllipse(
                center: center,
                radiusX: orbit + radius * CGFloat(0.018 + s * 0.032),
                radiusY: (orbit + radius * CGFloat(0.018 + s * 0.032)) * yScale,
                rotation: tilt,
                angle: angle - 0.07 - s * 0.07
            )

            var path = Path()
            path.move(to: tail)
            path.addLine(to: head)
            context.stroke(
                path,
                with: .color(dustColor(index + 29, alpha: alpha)),
                lineWidth: CGFloat(0.38 + s * 0.52)
            )

            if index % 3 == 0 {
                let dotSize = CGFloat(0.5 + (1 - travel) * 1.4)
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: head.x - dotSize / 2,
                        y: head.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )),
                    with: .color(Color(red: 0.84, green: 0.90, blue: 1.0).opacity(alpha * 0.86))
                )
            }
        }
    }

    private func drawEventHorizon(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        breath: Double,
        tilt: Double,
        time: TimeInterval
    ) {
        let coreRadius = radius * CGFloat(0.122 + 0.018 * breath + 0.004 * sin(time * 0.071 + 0.8))
        let coreRect = CGRect(
            x: center.x - coreRadius,
            y: center.y - coreRadius,
            width: coreRadius * 2,
            height: coreRadius * 2
        )

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: coreRadius * 0.44))
            layer.fill(
                Path(ellipseIn: coreRect.insetBy(dx: -coreRadius * 2.9, dy: -coreRadius * 2.2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.92, green: 0.86, blue: 1.0).opacity(0.15 + breath * 0.13), location: 0.0),
                        .init(color: Color(red: 0.36, green: 0.64, blue: 1.0).opacity(0.08 + breath * 0.06), location: 0.33),
                        .init(color: Color(red: 0.64, green: 0.30, blue: 1.0).opacity(0.032 + breath * 0.024), location: 0.68),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: center,
                    startRadius: coreRadius * 0.18,
                    endRadius: coreRadius * CGFloat(3.7 + breath * 0.7)
                )
            )
        }

        let shadowRect = coreRect.insetBy(dx: -coreRadius * 1.1, dy: -coreRadius * 0.92)
        context.fill(
            Path(ellipseIn: shadowRect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .black.opacity(0.96), location: 0.0),
                    .init(color: Color(red: 0.005, green: 0.006, blue: 0.02).opacity(0.88), location: 0.42),
                    .init(color: Color(red: 0.05, green: 0.06, blue: 0.16).opacity(0.24), location: 0.72),
                    .init(color: .clear, location: 1.0)
                ]),
                center: center,
                startRadius: 0,
                endRadius: coreRadius * 2.18
            )
        )

        context.fill(
            Path(ellipseIn: coreRect.insetBy(dx: coreRadius * 0.10, dy: coreRadius * 0.10)),
            with: .radialGradient(
                Gradient(colors: [
                    .black.opacity(0.98),
                    .black.opacity(0.70),
                    .clear
                ]),
                center: CGPoint(
                    x: center.x - coreRadius * 0.10,
                    y: center.y + coreRadius * 0.04
                ),
                startRadius: 0,
                endRadius: coreRadius * 0.94
            )
        )

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 1.2))
            let crescent = ellipseArcPath(
                center: CGPoint(x: center.x, y: center.y + coreRadius * 0.10),
                radiusX: coreRadius * 1.95,
                radiusY: coreRadius * 0.54,
                rotation: tilt,
                start: .pi * 1.02,
                length: .pi * 0.86,
                steps: 44
            )
            layer.stroke(
                crescent,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.62, green: 0.74, blue: 1.0).opacity(0.02),
                        Color(red: 1.0, green: 0.82, blue: 0.58).opacity(0.12 + breath * 0.11),
                        Color(red: 0.60, green: 0.72, blue: 1.0).opacity(0.03)
                    ]),
                    startPoint: CGPoint(x: center.x - coreRadius * 2.0, y: center.y),
                    endPoint: CGPoint(x: center.x + coreRadius * 2.0, y: center.y)
                ),
                lineWidth: 1.0
            )
        }
    }

    private func breathingPulse(_ time: TimeInterval) -> Double {
        let primary = 0.5 + 0.5 * sin(time * 0.26)
        let secondary = 0.5 + 0.5 * sin(time * 0.091 + 1.8)
        return primary * 0.72 + secondary * 0.28
    }

    private func ellipseArcPath(
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat,
        rotation: Double,
        start: Double,
        length: Double,
        steps: Int
    ) -> Path {
        var path = Path()

        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let point = pointOnEllipse(
                center: center,
                radiusX: radiusX,
                radiusY: radiusY,
                rotation: rotation,
                angle: start + length * progress
            )

            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }

    private func pointOnEllipse(
        center: CGPoint,
        radiusX: CGFloat,
        radiusY: CGFloat,
        rotation: Double,
        angle: Double
    ) -> CGPoint {
        let x = CGFloat(cos(angle)) * radiusX
        let y = CGFloat(sin(angle)) * radiusY
        let rotationCos = CGFloat(cos(rotation))
        let rotationSin = CGFloat(sin(rotation))

        return CGPoint(
            x: center.x + x * rotationCos - y * rotationSin,
            y: center.y + x * rotationSin + y * rotationCos
        )
    }

    private func dustColor(_ index: Int, alpha: Double) -> Color {
        switch index % 5 {
        case 0:
            return Color(red: 0.58, green: 0.78, blue: 1.0).opacity(alpha)
        case 1:
            return Color(red: 0.86, green: 0.90, blue: 1.0).opacity(alpha)
        case 2:
            return Color(red: 1.0, green: 0.70, blue: 0.42).opacity(alpha * 0.82)
        case 3:
            return Color(red: 0.70, green: 0.45, blue: 1.0).opacity(alpha * 0.72)
        default:
            return Color(red: 0.44, green: 0.96, blue: 1.0).opacity(alpha * 0.58)
        }
    }

    private func seed(_ index: Int, channel: Double = 0) -> Double {
        let value = sin((Double(index) + channel * 19.19) * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.46))
                .frame(width: 16, height: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title)
                    .font(.system(size: 11.3, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                Text(verbatim: message)
                    .font(.system(size: 9.4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .modifier(SettingsRowSurface())
    }
}

private struct SettingsSectionTitle: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
            .font(.system(size: 9.2, weight: .semibold))
            .foregroundStyle(.white.opacity(0.31))
            .padding(.horizontal, 3)
            .padding(.top, 3)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let message: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title)
                    .font(.system(size: 11.4, weight: .medium))
                    .lineLimit(1)
                Text(verbatim: message)
                    .font(.system(size: 9.4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(CompactSwitchToggleStyle())
                .labelsHidden()
        }
        .modifier(SettingsRowSurface())
    }
}

private struct SettingsLanguageRow: View {
    let selectedLanguage: AppLanguage
    let select: (AppLanguage) -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: L10n.text("settings_language"))
                    .font(.system(size: 11.4, weight: .medium))
                    .lineLimit(1)
                Text(verbatim: L10n.text("settings_language_message"))
                    .font(.system(size: 9.4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(2)
            }

            Spacer()

            Menu {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        select(language)
                    } label: {
                        Text(verbatim: language.displayName)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(verbatim: selectedLanguage.displayName)
                        .font(.system(size: 9.8, weight: .semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7.5, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(isHovered ? 0.72 : 0.55))
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .frame(minWidth: 70, minHeight: 24)
                .background(.white.opacity(isHovered ? 0.040 : 0.024))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isHovered ? 0.042 : 0.018), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .onHover { hovering in
                withAnimation(.snappy(duration: 0.16)) {
                    isHovered = hovering
                }
            }
        }
        .modifier(SettingsRowSurface())
    }
}

private struct ShortcutSettingsRow: View {
    @ObservedObject var controller: BlackHoleController
    let action: ShortcutAction
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: action.title)
                    .font(.system(size: 11.4, weight: .medium))
                    .lineLimit(1)
                Text(verbatim: action.isCommandTabFilterAction ? L10n.text("settings_shortcut_filter_scope") : L10n.text("settings_shortcut_global_scope"))
                    .font(.system(size: 9.4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.32))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                beginRecording()
            } label: {
                Text(verbatim: isRecording ? L10n.text("settings_shortcut_recording") : controller.settings.shortcut(for: action).displayText)
                    .font(.system(size: 9.8, weight: .semibold, design: .rounded))
                    .frame(minWidth: 58)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .frame(minHeight: 24)
            }
            .buttonStyle(ShortcutCaptureButtonStyle(isRecording: isRecording))
            .help(L10n.text("settings_shortcut_record_help"))
        }
        .modifier(SettingsRowSurface())
        .onDisappear {
            stopRecording()
        }
    }

    private func beginRecording() {
        stopRecording()
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            if let shortcut = GlobalShortcut(event: event) {
                controller.setShortcut(shortcut, for: action)
            } else {
                controller.lastMessage = L10n.text("message_shortcut_invalid")
            }

            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }
}

private struct RowSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(.white.opacity(0.018))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(.white.opacity(0.024), lineWidth: 1)
            )
    }
}

private struct SettingsRowSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.014))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(.white.opacity(0.018), lineWidth: 1)
            )
    }
}

private struct CompactSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        CompactSwitchBody(configuration: configuration)
    }

    private struct CompactSwitchBody: View {
        let configuration: ToggleStyleConfiguration
        @State private var isHovered = false

        var body: some View {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    configuration.isOn.toggle()
                }
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(trackFill)
                        .frame(width: 29, height: 16)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(configuration.isOn ? 0.070 : (isHovered ? 0.046 : 0.024)), lineWidth: 1)
                        )

                    Circle()
                        .fill(configuration.isOn ? Color(red: 0.84, green: 0.91, blue: 1.0) : .white.opacity(0.52))
                        .frame(width: 10.5, height: 10.5)
                        .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                        .padding(.horizontal, 3)
                }
                .frame(width: 36, height: 26)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.035 : 1)
            .animation(.snappy(duration: 0.18), value: isHovered)
            .animation(.snappy(duration: 0.18), value: configuration.isOn)
            .onHover { hovering in
                isHovered = hovering
            }
        }

        private var trackFill: Color {
            if configuration.isOn {
                return Color(red: 0.42, green: 0.62, blue: 1.0).opacity(isHovered ? 0.42 : 0.34)
            }

            return .white.opacity(isHovered ? 0.055 : 0.030)
        }
    }
}

private struct IconButtonStyle: ButtonStyle {
    var subtle = false

    func makeBody(configuration: Configuration) -> some View {
        IconButtonBody(configuration: configuration, subtle: subtle)
    }

    private struct IconButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let subtle: Bool
        @State private var isHovered = false

        private var fillOpacity: Double {
            if subtle {
                return isHovered ? 0.040 : 0.018
            }
            return configuration.isPressed ? 0.075 : (isHovered ? 0.060 : 0.032)
        }

        private var strokeOpacity: Double {
            if subtle {
                return isHovered ? 0.034 : 0.014
            }
            return isHovered ? 0.062 : 0.028
        }

        var body: some View {
            ZStack {
                Capsule()
                    .fill(.white.opacity(fillOpacity))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(strokeOpacity), lineWidth: 1)
                    )
                    .shadow(
                        color: Color(red: 0.55, green: 0.72, blue: 1.0).opacity(subtle ? 0 : (isHovered ? 0.16 : 0)),
                        radius: isHovered ? 8 : 0,
                        y: 1
                    )

                configuration.label
                    .foregroundStyle(subtle ? .white.opacity(isHovered ? 0.66 : 0.46) : Color(red: 0.72, green: 0.82, blue: 1.0).opacity(isHovered ? 0.94 : 0.82))
            }
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.93 : (isHovered ? 1.055 : 1))
            .brightness(isHovered ? 0.025 : 0)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .animation(.snappy(duration: 0.17), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
}

private struct CapsuleActionButtonStyle: ButtonStyle {
    let minWidth: CGFloat
    let minHeight: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        CapsuleActionButtonBody(
            configuration: configuration,
            minWidth: minWidth,
            minHeight: minHeight
        )
    }

    private struct CapsuleActionButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let minWidth: CGFloat
        let minHeight: CGFloat
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .foregroundStyle(.white.opacity(isHovered ? 0.76 : 0.58))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .frame(minWidth: minWidth, minHeight: minHeight)
                .background(.white.opacity(configuration.isPressed ? 0.060 : (isHovered ? 0.052 : 0.035)))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isHovered ? 0.070 : 0.035), lineWidth: 1)
                )
                .shadow(
                    color: Color(red: 0.58, green: 0.74, blue: 1.0).opacity(isHovered ? 0.12 : 0),
                    radius: isHovered ? 10 : 0,
                    y: 2
                )
                .scaleEffect(configuration.isPressed ? 0.975 : (isHovered ? 1.018 : 1))
                .contentShape(Rectangle())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
                .animation(.snappy(duration: 0.18), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}

private struct ShortcutCaptureButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        ShortcutCaptureButtonBody(configuration: configuration, isRecording: isRecording)
    }

    private struct ShortcutCaptureButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let isRecording: Bool
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .foregroundStyle(isRecording ? .black.opacity(0.78) : .white.opacity(isHovered ? 0.70 : 0.54))
                .background(isRecording ? .white.opacity(configuration.isPressed ? 0.56 : 0.64) : .white.opacity(configuration.isPressed ? 0.046 : (isHovered ? 0.040 : 0.024)))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isRecording ? 0 : (isHovered ? 0.042 : 0.018)), lineWidth: 1)
                )
                .shadow(
                    color: Color(red: 0.58, green: 0.74, blue: 1.0).opacity(isHovered && !isRecording ? 0.055 : 0),
                    radius: isHovered ? 5 : 0,
                    y: 1
                )
                .scaleEffect(configuration.isPressed ? 0.975 : (isHovered ? 1.010 : 1))
                .contentShape(Rectangle())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
                .animation(.snappy(duration: 0.18), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    var hovered = false
    var hoverScale: CGFloat = 1.02
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : (hovered ? hoverScale : 1))
            .brightness(hovered ? 0.018 : 0)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .animation(.snappy(duration: 0.17), value: hovered)
    }
}

private struct SecondaryTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryTextButtonBody(configuration: configuration)
    }

    private struct SecondaryTextButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .font(.system(size: 10.6, weight: .semibold))
                .foregroundStyle(.white.opacity(configuration.isPressed ? 0.50 : (isHovered ? 0.72 : 0.58)))
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(.white.opacity(configuration.isPressed ? 0.046 : (isHovered ? 0.048 : 0.030)))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(.white.opacity(isHovered ? 0.040 : 0.016), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.976 : (isHovered ? 1.010 : 1))
                .shadow(
                    color: Color(red: 0.58, green: 0.74, blue: 1.0).opacity(isHovered ? 0.055 : 0),
                    radius: isHovered ? 5 : 0,
                    y: 1
                )
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
                .animation(.snappy(duration: 0.18), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}
