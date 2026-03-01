import AppKit
import Foundation

// MARK: - Settings Model

struct CountdownSettings {
    private static let defaultMinutesKey = "defaultMinutes"
    private static let quickAddMinutesKey = "quickAddMinutes"
    private static let playSoundOnDoneKey = "playSoundOnDone"
    private static let requestAttentionOnDoneKey = "requestAttentionOnDone"

    static let defaultMinutesRange = 0.1...1_440.0
    static let quickAddMinutesRange = 0.1...240.0

    var defaultMinutes: Double
    var quickAddMinutes: Double
    var playSoundOnDone: Bool
    var requestAttentionOnDone: Bool

    static func load(fallbackDefaultMinutes: Double) -> CountdownSettings {
        let defaults = UserDefaults.standard
        let storedDefaultMinutes = defaults.object(forKey: defaultMinutesKey) as? Double
        let storedQuickAddMinutes = defaults.object(forKey: quickAddMinutesKey) as? Double
        let storedPlaySound = defaults.object(forKey: playSoundOnDoneKey) as? Bool
        let storedRequestAttention = defaults.object(forKey: requestAttentionOnDoneKey) as? Bool

        return CountdownSettings(
            defaultMinutes: sanitize(storedDefaultMinutes ?? fallbackDefaultMinutes, fallback: fallbackDefaultMinutes, range: defaultMinutesRange),
            quickAddMinutes: sanitize(storedQuickAddMinutes ?? 5, fallback: 5, range: quickAddMinutesRange),
            playSoundOnDone: storedPlaySound ?? true,
            requestAttentionOnDone: storedRequestAttention ?? true
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(defaultMinutes, forKey: Self.defaultMinutesKey)
        defaults.set(quickAddMinutes, forKey: Self.quickAddMinutesKey)
        defaults.set(playSoundOnDone, forKey: Self.playSoundOnDoneKey)
        defaults.set(requestAttentionOnDone, forKey: Self.requestAttentionOnDoneKey)
    }

    static func sanitize(_ value: Double, fallback: Double, range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return fallback }

        let rounded = (value * 10).rounded() / 10
        if rounded < range.lowerBound || rounded > range.upperBound {
            return fallback
        }

        return rounded
    }
}

// MARK: - Design System

@MainActor
enum DesignSystem {
    // Accent color — productivity blue
    static let accentColor = NSColor(srgbRed: 0.231, green: 0.510, blue: 0.965, alpha: 1.0) // #3B82F6
    static let accentColorHover = NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1.0) // #2563EB

    // Semantic colors
    static let successColor = NSColor(srgbRed: 0.133, green: 0.773, blue: 0.369, alpha: 1.0) // #22C55E
    static let warningColor = NSColor(srgbRed: 0.976, green: 0.451, blue: 0.086, alpha: 1.0) // #F97316
    static let dangerColor = NSColor(srgbRed: 0.937, green: 0.267, blue: 0.267, alpha: 1.0)  // #EF4444

    // Text colors
    static let textPrimary = NSColor.labelColor
    static let textSecondary = NSColor.secondaryLabelColor
    static let textTertiary = NSColor.tertiaryLabelColor

    // Separators & borders
    static let borderColor = NSColor.separatorColor.withAlphaComponent(0.4)

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // Corner Radius
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 10
    static let radiusLG: CGFloat = 14

    // Fonts
    static let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
    static let subtitleFont = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let sectionHeaderFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
    static let bodyFont = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let bodyMediumFont = NSFont.systemFont(ofSize: 13, weight: .medium)
    static let captionFont = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let monoFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)

    // Card styling
    static func styleCard(_ box: NSBox) {
        box.boxType = .custom
        box.borderWidth = 1
        box.cornerRadius = radiusLG
        box.borderColor = borderColor
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6)
        box.contentViewMargins = NSSize(width: spacingLG, height: spacingLG)
    }

    // Primary button styling
    static func makePrimaryButton(title: String, target: AnyObject?, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.contentTintColor = .white
        return button
    }

    // Secondary button styling
    static func makeSecondaryButton(title: String, target: AnyObject?, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        button.bezelStyle = .rounded
        button.isBordered = true
        return button
    }

    // Pill / tag button
    static func makePresetButton(title: String, tag: Int, target: AnyObject?, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        button.bezelStyle = .rounded
        button.tag = tag
        button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        button.controlSize = .small
        return button
    }
}

// MARK: - Settings Window Controller

@MainActor
final class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
    private var settings: CountdownSettings
    private let onSave: (CountdownSettings, Bool) -> Void

    private let defaultMinutesField = NSTextField()
    private let quickAddMinutesField = NSTextField()
    private let defaultMinutesStepper = NSStepper()
    private let quickAddMinutesStepper = NSStepper()
    private let presetPopup = NSPopUpButton()
    private let playSoundCheckbox = NSButton(checkboxWithTitle: "Play alert sound", target: nil, action: nil)
    private let requestAttentionCheckbox = NSButton(checkboxWithTitle: "Bounce dock icon", target: nil, action: nil)
    private let applyAndResetCheckbox = NSButton(checkboxWithTitle: "Apply and reset timer immediately", target: nil, action: nil)
    private let validationLabel = NSTextField(labelWithString: "")
    private let previewLabel = NSTextField(labelWithString: "")

    init(settings: CountdownSettings, onSave: @escaping (CountdownSettings, Bool) -> Void) {
        self.settings = settings
        self.onSave = onSave
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configureWindow()
        configureUI()
        populateFields(using: settings)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func open(with settings: CountdownSettings) {
        self.settings = settings
        populateFields(using: settings)
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(defaultMinutesField)
    }

    private func configureWindow() {
        window?.title = "Countdown Settings"
        window?.isReleasedWhenClosed = false
        window?.titleVisibility = .visible
        window?.center()
    }

    private func configureUI() {
        guard let contentView = window?.contentView else { return }
        configureInputs()

        let container = NSStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.orientation = .vertical
        container.spacing = 14
        container.alignment = .leading

        let subtitle = NSTextField(labelWithString: "Adjust timer defaults for quick daily use.")
        subtitle.textColor = .secondaryLabelColor

        let defaultControl = makeNumericControlStack(field: defaultMinutesField, stepper: defaultMinutesStepper)
        let quickAddControl = makeNumericControlStack(field: quickAddMinutesField, stepper: quickAddMinutesStepper)
        presetPopup.widthAnchor.constraint(equalToConstant: 190).isActive = true

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: "Default countdown (minutes)"), defaultControl],
            [NSTextField(labelWithString: "Quick add (minutes)"), quickAddControl],
            [NSTextField(labelWithString: "Preset"), presetPopup],
        ])
        grid.rowSpacing = 10
        grid.columnSpacing = 14
        grid.xPlacement = .leading
        grid.yPlacement = .center
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .leading

        let timerBox = NSBox()
        timerBox.title = "Timer"
        timerBox.contentViewMargins = NSSize(width: 12, height: 12)
        timerBox.contentView = grid

        let alertStack = NSStackView()
        alertStack.orientation = .vertical
        alertStack.spacing = 8
        alertStack.addArrangedSubview(playSoundCheckbox)
        alertStack.addArrangedSubview(requestAttentionCheckbox)
        alertStack.addArrangedSubview(applyAndResetCheckbox)

        let alertBox = NSBox()
        alertBox.title = "When timer ends"
        alertBox.contentViewMargins = NSSize(width: 12, height: 12)
        alertBox.contentView = alertStack

        validationLabel.textColor = .systemRed
        validationLabel.font = NSFont.systemFont(ofSize: 12)
        validationLabel.isHidden = true
        previewLabel.textColor = .secondaryLabelColor
        previewLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        let buttonsRow = NSStackView()
        buttonsRow.orientation = .horizontal
        buttonsRow.spacing = 8
        buttonsRow.alignment = .centerY

        let resetDefaultsButton = NSButton(title: "Reset Defaults", target: self, action: #selector(resetDefaults))
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSettings))
        cancelButton.keyEquivalent = "\u{1b}"
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.keyEquivalent = "\r"
        saveButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        buttonsRow.addArrangedSubview(resetDefaultsButton)
        buttonsRow.addArrangedSubview(spacer)
        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(saveButton)

        container.addArrangedSubview(subtitle)
        container.addArrangedSubview(timerBox)
        container.addArrangedSubview(alertBox)
        container.addArrangedSubview(validationLabel)
        container.addArrangedSubview(previewLabel)
        container.addArrangedSubview(buttonsRow)
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            timerBox.widthAnchor.constraint(equalTo: container.widthAnchor),
            alertBox.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    private func configureInputs() {
        for field in [defaultMinutesField, quickAddMinutesField] {
            field.alignment = .right
            field.delegate = self
            field.target = self
            field.action = #selector(textFieldDidCommit)
            field.widthAnchor.constraint(equalToConstant: 70).isActive = true
        }
        defaultMinutesField.placeholderString = "25"
        quickAddMinutesField.placeholderString = "5"

        defaultMinutesStepper.minValue = CountdownSettings.defaultMinutesRange.lowerBound
        defaultMinutesStepper.maxValue = CountdownSettings.defaultMinutesRange.upperBound
        defaultMinutesStepper.increment = 1
        defaultMinutesStepper.target = self
        defaultMinutesStepper.action = #selector(defaultStepperChanged)

        quickAddMinutesStepper.minValue = CountdownSettings.quickAddMinutesRange.lowerBound
        quickAddMinutesStepper.maxValue = CountdownSettings.quickAddMinutesRange.upperBound
        quickAddMinutesStepper.increment = 1
        quickAddMinutesStepper.target = self
        quickAddMinutesStepper.action = #selector(quickAddStepperChanged)

        presetPopup.removeAllItems()
        presetPopup.addItems(withTitles: [
            "Custom",
            "Pomodoro (25 / 5)",
            "Deep Work (50 / 10)",
            "Sprint (15 / 3)"
        ])
        presetPopup.target = self
        presetPopup.action = #selector(applyPresetSelection)

        playSoundCheckbox.target = self
        playSoundCheckbox.action = #selector(toggleChanged)
        requestAttentionCheckbox.target = self
        requestAttentionCheckbox.action = #selector(toggleChanged)
        applyAndResetCheckbox.target = self
        applyAndResetCheckbox.action = #selector(toggleChanged)
    }

    private func makeNumericControlStack(field: NSTextField, stepper: NSStepper) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.addArrangedSubview(field)
        stack.addArrangedSubview(stepper)
        return stack
    }

    private func populateFields(using settings: CountdownSettings) {
        defaultMinutesField.stringValue = Self.format(minutes: settings.defaultMinutes)
        quickAddMinutesField.stringValue = Self.format(minutes: settings.quickAddMinutes)
        defaultMinutesStepper.doubleValue = settings.defaultMinutes
        quickAddMinutesStepper.doubleValue = settings.quickAddMinutes
        playSoundCheckbox.state = settings.playSoundOnDone ? .on : .off
        requestAttentionCheckbox.state = settings.requestAttentionOnDone ? .on : .off
        applyAndResetCheckbox.state = .off
        presetPopup.selectItem(at: 0)
        validationLabel.isHidden = true
        validationLabel.stringValue = ""
        refreshPreview()
    }

    @objc private func defaultStepperChanged() {
        defaultMinutesField.stringValue = Self.format(minutes: defaultMinutesStepper.doubleValue)
        refreshPreview()
    }

    @objc private func quickAddStepperChanged() {
        quickAddMinutesField.stringValue = Self.format(minutes: quickAddMinutesStepper.doubleValue)
        refreshPreview()
    }

    @objc private func toggleChanged() {
        refreshPreview()
    }

    @objc private func textFieldDidCommit() {
        syncSteppersFromFields()
        refreshPreview()
    }

    @objc private func applyPresetSelection() {
        switch presetPopup.indexOfSelectedItem {
        case 1:
            applyPreset(defaultMinutes: 25, quickAddMinutes: 5)
        case 2:
            applyPreset(defaultMinutes: 50, quickAddMinutes: 10)
        case 3:
            applyPreset(defaultMinutes: 15, quickAddMinutes: 3)
        default:
            return
        }
    }

    @objc private func resetDefaults() {
        applyPreset(defaultMinutes: 25, quickAddMinutes: 5)
        playSoundCheckbox.state = .on
        requestAttentionCheckbox.state = .on
        applyAndResetCheckbox.state = .off
        presetPopup.selectItem(at: 1)
    }

    private func applyPreset(defaultMinutes: Double, quickAddMinutes: Double) {
        defaultMinutesField.stringValue = Self.format(minutes: defaultMinutes)
        quickAddMinutesField.stringValue = Self.format(minutes: quickAddMinutes)
        defaultMinutesStepper.doubleValue = defaultMinutes
        quickAddMinutesStepper.doubleValue = quickAddMinutes
        refreshPreview()
    }

    func controlTextDidChange(_ obj: Notification) {
        syncSteppersFromFields()
        refreshPreview()
    }

    private func syncSteppersFromFields() {
        updateStepper(defaultMinutesStepper, from: defaultMinutesField, range: CountdownSettings.defaultMinutesRange)
        updateStepper(quickAddMinutesStepper, from: quickAddMinutesField, range: CountdownSettings.quickAddMinutesRange)
    }

    private func updateStepper(_ stepper: NSStepper, from field: NSTextField, range: ClosedRange<Double>) {
        guard let value = parsePositiveNumber(field.stringValue) else { return }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        stepper.doubleValue = clamped
    }

    private func refreshPreview() {
        guard let draft = makeDraftSettings() else {
            previewLabel.textColor = .systemRed
            previewLabel.stringValue = "Preview unavailable"
            validationLabel.stringValue = "Please enter valid values. Default: 0.1-1440, Quick add: 0.1-240."
            validationLabel.isHidden = false
            return
        }

        previewLabel.textColor = .secondaryLabelColor
        validationLabel.isHidden = true
        previewLabel.stringValue = "Preview: Reset to \(labelForMinutes(draft.defaultMinutes)) | Quick add +\(labelForMinutes(draft.quickAddMinutes))"
    }

    private func makeDraftSettings() -> CountdownSettings? {
        guard
            let defaultMinutes = parsePositiveNumber(defaultMinutesField.stringValue),
            let quickAddMinutes = parsePositiveNumber(quickAddMinutesField.stringValue),
            CountdownSettings.defaultMinutesRange.contains(defaultMinutes),
            CountdownSettings.quickAddMinutesRange.contains(quickAddMinutes)
        else {
            return nil
        }

        return CountdownSettings(
            defaultMinutes: CountdownSettings.sanitize(defaultMinutes, fallback: settings.defaultMinutes, range: CountdownSettings.defaultMinutesRange),
            quickAddMinutes: CountdownSettings.sanitize(quickAddMinutes, fallback: settings.quickAddMinutes, range: CountdownSettings.quickAddMinutesRange),
            playSoundOnDone: playSoundCheckbox.state == .on,
            requestAttentionOnDone: requestAttentionCheckbox.state == .on
        )
    }

    @objc private func cancelSettings() {
        window?.performClose(nil)
    }

    @objc private func saveSettings() {
        guard let updatedSettings = makeDraftSettings() else {
            showValidationError()
            return
        }

        settings = updatedSettings
        onSave(updatedSettings, applyAndResetCheckbox.state == .on)
        window?.performClose(nil)
    }

    private func parsePositiveNumber(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized), parsed > 0 else {
            return nil
        }
        return parsed
    }

    private func showValidationError() {
        guard let window else { return }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Invalid value"
        alert.informativeText = "Please enter positive numbers.\n\nDefault countdown: 0.1 – 1,440 minutes\nQuick add: 0.1 – 240 minutes"
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }

    private func labelForMinutes(_ minutes: Double) -> String {
        let rounded = (minutes * 10).rounded() / 10
        if rounded >= 60 {
            let hours = Int(rounded / 60)
            let remainingMinutes = rounded - Double(hours * 60)
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(formatSingleValue(remainingMinutes))m"
        }
        return "\(formatSingleValue(rounded))m"
    }

    private static func format(minutes: Double) -> String {
        let rounded = (minutes * 10).rounded() / 10
        if rounded.rounded() == rounded {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private func formatSingleValue(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Countdown Controller

@MainActor
final class CountdownController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var settings: CountdownSettings
    private var targetDate: Date
    private var timer: Timer?
    private var infoMenuItem: NSMenuItem?
    private var resetMenuItem: NSMenuItem?
    private var addTimeMenuItem: NSMenuItem?
    private var pauseMenuItem: NSMenuItem?
    private var settingsWindowController: SettingsWindowController?
    private var isPaused = false
    private var remainingWhenPaused: TimeInterval = 0

    private var defaultDuration: TimeInterval {
        settings.defaultMinutes * 60
    }

    private var quickAddDuration: TimeInterval {
        settings.quickAddMinutes * 60
    }

    init(defaultMinutes: Double) {
        let fallbackDefault = max(defaultMinutes, 0.1)
        self.settings = CountdownSettings.load(fallbackDefaultMinutes: fallbackDefault)
        let duration = self.settings.defaultMinutes * 60
        self.targetDate = Date().addingTimeInterval(duration)
        super.init()
        configureStatusItem()
        scheduleTimerIfNeeded()
        updateStatusTitle()
    }

    private func configureStatusItem() {
        // Setup text-only status button
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.title = "--:--"
        }

        let menu = NSMenu()

        // Info line
        let infoItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        infoMenuItem = infoItem
        menu.addItem(infoItem)

        menu.addItem(.separator())

        // Pause/Resume
        let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "p")
        pauseItem.target = self
        pauseMenuItem = pauseItem
        menu.addItem(pauseItem)

        // Reset
        let resetItem = NSMenuItem(title: "", action: #selector(resetCountdown), keyEquivalent: "r")
        resetItem.target = self
        resetMenuItem = resetItem
        menu.addItem(resetItem)

        // Add time
        let addTimeItem = NSMenuItem(title: "", action: #selector(addQuickTime), keyEquivalent: "a")
        addTimeItem.target = self
        addTimeMenuItem = addTimeItem
        menu.addItem(addTimeItem)

        menu.addItem(.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenuTitles()
    }

    private func scheduleTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func handleTimerTick() {
        updateStatusTitle()
    }

    private func updateStatusTitle() {
        let remainingSeconds: Int
        if isPaused {
            remainingSeconds = max(Int(remainingWhenPaused.rounded(.down)), 0)
        } else {
            remainingSeconds = max(Int(targetDate.timeIntervalSinceNow.rounded(.down)), 0)
        }

        if remainingSeconds == 0 && !isPaused {
            statusItem.button?.title = "Done"
            timer?.invalidate()
            timer = nil
            if settings.requestAttentionOnDone {
                NSApp.requestUserAttention(.informationalRequest)
            }
            if settings.playSoundOnDone {
                NSSound.beep()
            }
            return
        }

        let prefix = isPaused ? "⏸ " : ""
        statusItem.button?.title = "\(prefix)\(format(seconds: remainingSeconds))"
    }

    @objc private func togglePause() {
        if isPaused {
            // Resume
            targetDate = Date().addingTimeInterval(remainingWhenPaused)
            isPaused = false
            pauseMenuItem?.title = "Pause"
            scheduleTimerIfNeeded()
        } else {
            // Pause
            remainingWhenPaused = max(targetDate.timeIntervalSinceNow, 0)
            isPaused = true
            pauseMenuItem?.title = "Resume"
            timer?.invalidate()
            timer = nil
        }
        updateStatusTitle()
    }

    @objc private func resetCountdown() {
        isPaused = false
        pauseMenuItem?.title = "Pause"
        targetDate = Date().addingTimeInterval(defaultDuration)
        scheduleTimerIfNeeded()
        updateStatusTitle()
    }

    @objc private func addQuickTime() {
        if isPaused {
            remainingWhenPaused += quickAddDuration
        } else {
            let baseDate = max(targetDate, Date())
            targetDate = baseDate.addingTimeInterval(quickAddDuration)
        }
        scheduleTimerIfNeeded()
        updateStatusTitle()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings) { [weak self] updatedSettings, shouldReset in
                self?.applySettings(updatedSettings, resetTimer: shouldReset)
            }
        }

        settingsWindowController?.open(with: settings)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func applySettings(_ updatedSettings: CountdownSettings, resetTimer: Bool) {
        settings = updatedSettings
        settings.save()
        updateMenuTitles()
        if resetTimer {
            resetCountdown()
        }
    }

    private func updateMenuTitles() {
        infoMenuItem?.title = "Default: \(labelForMinutes(settings.defaultMinutes))  ·  Quick add: \(labelForMinutes(settings.quickAddMinutes))"
        resetMenuItem?.title = "Reset (\(labelForMinutes(settings.defaultMinutes)))"
        addTimeMenuItem?.title = "Add \(labelForMinutes(settings.quickAddMinutes))"
    }

    private func format(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }

    private func labelForMinutes(_ minutes: Double) -> String {
        let rounded = (minutes * 10).rounded() / 10
        if rounded >= 60 {
            let hours = Int(rounded / 60)
            let remainingMinutes = rounded - Double(hours * 60)
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(formatSingleValue(remainingMinutes))m"
        }
        return "\(formatSingleValue(rounded))m"
    }

    private func formatSingleValue(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - App Entry Point

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var countdownController: CountdownController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        countdownController = CountdownController(defaultMinutes: Self.initialMinutesFromArguments())
    }

    private static func initialMinutesFromArguments() -> Double {
        guard
            let firstArg = CommandLine.arguments.dropFirst().first,
            let minutes = Double(firstArg),
            minutes > 0
        else {
            return 25
        }
        return minutes
    }
}

@main
@MainActor
struct StatusBarCountdownApp {
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
}
