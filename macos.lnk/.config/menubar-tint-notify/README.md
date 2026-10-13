# menubar-tint-notify

Recolors the WhichSpace menu bar icon to match the menu bar's tint: a white square on a dark menu bar, black on a light one.

macOS picks the menu bar tint from the wallpaper behind it, not from the system light/dark mode. WhichSpace follows only the system mode, so with a dynamic wallpaper its icon ends up the wrong color. `dark-mode-notify` can't fix this either, because it also sees only the system mode.

## Files

| File | Role |
|------|------|
| `main.swift` | Watcher source. Runs `<command> dark\|light` at start, on every tint change, on wake, and when WhichSpace launches. |
| `menubar-tint-notify` | Compiled watcher, committed so other Macs need no build step. |
| `menubar-tint-helper` | Sets WhichSpace's per-Space colors via AppleScript. Skips if WhichSpace isn't running. |
| `~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist` | Runs the watcher at login, keeps it alive. Tracked in `.lnk.macos`. |

Log: `~/Library/Logs/menubar-tint-notify.log`, one line per recolor.

## Usage

- **Rebuild** after editing `main.swift`: `swiftc -O main.swift -o menubar-tint-notify`, then `launchctl kickstart -k gui/$(id -u)/com.eric.menubar-tint-notify`.
- **Load now** instead of at the next login: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist`.
- **Manual toggle:** `bash ~/.config/menubar-tint-notify/menubar-tint-helper dark` or `light`. The argument names the **menu bar** tint, so `dark` gives a white icon. The watcher overrides it at the next tint change.
- **Colors** are hard-coded in the helper and replace whatever is set in WhichSpace's settings.

## How it reads the tint

AppKit's private `+[NSAppearance _menuBarAppearanceProxy]` holds the menu bar's appearance (`NSAppearanceNameVibrantDark` or `VibrantLight`), and AppKit posts `NSWorkspaceMenuBarAppearanceDidChangeNotification` on `NSWorkspace.shared.notificationCenter` on each change. Both were found on macOS 27 and confirmed to follow wallpaper-only changes with the system left in light mode.

If a macOS update removes the proxy, the watcher logs a warning and falls back to the system light/dark mode.

## What didn't work (macOS 27)

- **System light/dark mode** (`AppleInterfaceStyle`, `AppleInterfaceThemeChangedNotification`): misses wallpaper-driven tint changes.
- **Hidden status item + KVO on `button.effectiveAppearance`.** This is the workaround documented online. It works only while the item is placed in the menu bar. Barbee hides new items: their window gets zero height and stops getting updates, even 1pt-wide items set to Shown. Items Barbee moves also stop updating. Read the button's _window_ appearance, too: the button's own flickers to the app's while it redraws.
- **System-wide state:** `MenuBarAgent` draws the menu bar and samples the backdrop luminance itself (`BackdropLuminanceEventHandler`). It posts no distributed or Darwin notification and stores no defaults key. The tint reaches each app privately.
- **Screen sampling** (ScreenCaptureKit) would work but needs Screen Recording permission. It isn't needed while the proxy exists.

## Re-finding the API

If the proxy disappears:

1. Search framework exports: `dyld_info -objc -exports /System/Library/Frameworks/AppKit.framework/AppKit | grep -i -E 'menubarappearance|luminan'`.
2. List matching selectors at runtime: `objc_copyClassNamesForImage` over AppKit, then `class_copyMethodList`. Enumerating _all_ classes crashes.
3. **Run GUI probes outside the Claude Code sandbox**, as a temporary LaunchAgent. Inside it, even `NSApp.effectiveAppearance` reads Aqua in dark mode.
4. To tell the wallpaper tint apart from the system mode, test with the system in light mode and a black wallpaper.
