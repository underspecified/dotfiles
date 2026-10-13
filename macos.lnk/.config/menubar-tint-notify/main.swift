// Usage: menubar-tint-notify <command> [args...]
// Runs `<command> [args...] dark|light` at start and whenever the menu bar's
// tint changes. The tint follows the wallpaper behind the menu bar, not the
// system light/dark mode (that's dark-mode-notify), so a dynamic wallpaper can
// flip it during the day with no mode change.
// How: AppKit's private +[NSAppearance _menuBarAppearanceProxy] holds the menu
// bar's appearance, and NSWorkspaceMenuBarAppearanceDidChangeNotification
// fires on each change (found on macOS 27). Needs no menu bar item, so a menu
// bar manager like Barbee can't hide it. If a macOS update removes the proxy,
// this logs a warning and falls back to the system light/dark mode.
// Also reruns on wake and when WhichSpace launches, so a late-starting
// WhichSpace gets recolored.
// Build: swiftc -O main.swift -o menubar-tint-notify

import Cocoa

let command = Array(CommandLine.arguments.dropFirst())
guard !command.isEmpty else {
    FileHandle.standardError.write(Data("usage: menubar-tint-notify <command> [args...]\n".utf8))
    exit(2)
}

@Sendable func warn(_ message: String) {
    FileHandle.standardError.write(Data("\(Date()) menubar-tint-notify: \(message)\n".utf8))
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let proxySelector = NSSelectorFromString("_menuBarAppearanceProxy")
let proxy = NSAppearance.responds(to: proxySelector)
    ? (NSAppearance.self as AnyObject).perform(proxySelector)?.takeUnretainedValue() as? NSObject
    : nil
if proxy == nil {
    warn("no _menuBarAppearanceProxy: following the system light/dark mode instead")
}
var lastTint: String?

@MainActor
func notify(force: Bool = false) {
    let appearance = proxy?.value(forKey: "effectiveAppearance") as? NSAppearance ?? app.effectiveAppearance
    let tint = appearance.name.rawValue.lowercased().contains("dark") ? "dark" : "light"
    guard force || tint != lastTint else { return }
    lastTint = tint
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = command + [tint]
    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        warn("\(error)")
    }
}

// AppKit posts these notifications on the main thread.
let center = NSWorkspace.shared.notificationCenter
center.addObserver(
    forName: Notification.Name("NSWorkspaceMenuBarAppearanceDidChangeNotification"), object: nil, queue: .main
) { _ in
    MainActor.assumeIsolated { notify() }
}
// Fallback trigger when the proxy is missing.
DistributedNotificationCenter.default().addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main
) { _ in
    MainActor.assumeIsolated { notify() }
}
center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
    MainActor.assumeIsolated { notify(force: true) }
}
center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { note in
    let launched = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if launched?.bundleIdentifier == "io.gechr.WhichSpace" {
        MainActor.assumeIsolated { notify(force: true) }
    }
}

MainActor.assumeIsolated { notify() }
app.run()
