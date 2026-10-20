# menubar-tint-notify

Recolors the WhichSpace menu bar icon to match the menu bar's tint: a light (`#E9F1F3`) square on a dark menu bar, a dark (`#1F1E0B`) one on a light menu bar.

macOS picks the menu bar tint from the wallpaper behind it, not from the system light/dark mode. WhichSpace draws a full-color icon that follows only the system mode, so with a dynamic wallpaper it ends up the wrong color. Other icons are template images, which macOS tints itself. `dark-mode-notify` can't fix this either, because it also sees only the system mode.

## Files

| File | Role |
|------|------|
| `main.swift` | Watcher source. Runs `<command> dark\|light` at start, whenever the sampled tint changes, and when WhichSpace restarts or the displays change. |
| `menubar-tint-notify` | Compiled watcher, committed so other Macs need no build step. |
| `menubar-tint-helper` | Sets WhichSpace's per-Space colors via AppleScript. Skips if WhichSpace isn't running. |
| `~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist` | Runs the watcher at login, keeps it alive. Tracked in `.lnk.macos`. |

Log: `~/Library/Logs/menubar-tint-notify.log`, one watcher line (tint + sample stats) and one helper line per recolor.

## Usage

- **Screen Recording permission** is required on each Mac: System Settings → Privacy & Security → Screen & System Audio Recording → `menubar-tint-notify`. Then `launchctl kickstart -k gui/$(id -u)/com.eric.menubar-tint-notify`. Without it, the log says so and the watcher falls back to the appearance proxy, which is wrong over mid-tone wallpapers.
- **Rebuild** after editing `main.swift`: `swiftc -O main.swift -o /tmp/mtn && mv /tmp/mtn menubar-tint-notify` (replace the inode; never overwrite the running binary), then kickstart. The binary is ad-hoc signed, so **a rebuild can drop the permission** (it did on 10-14, not on 10-15). Check the log after the kickstart. If it says no permission, toggling it off and on doesn't help: remove the entry with **−**, kickstart (the watcher re-requests and re-adds itself), enable it, and kickstart again.
- **Load now** instead of at the next login: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist`.
- **Manual toggle:** `bash ~/.config/menubar-tint-notify/menubar-tint-helper dark` or `light`. The argument names the **menu bar** tint, so `dark` gives the light icon. The watcher overrides it at the next check.
- **Colors** are hard-coded in the helper and replace whatever is set in WhichSpace's settings.

## How it reads the tint

It captures the left end of the main display's menu bar with ScreenCaptureKit (Apple logo + app name, always present at a fixed spot). The median luminance is the backdrop; pixels far from it are glyphs. Mostly lighter glyphs means white glyphs, so the tint is `dark`. This copies the color macOS actually drew, so there is no threshold to tune.

It checks at start, on `NSWorkspaceMenuBarAppearanceDidChangeNotification`, on a system mode change, Space change, wake, display wake, and every 10s, because a dynamic wallpaper shifts with no notification ("Macintosh" animates its colors continuously). The capture shows no screen-recording indicator.

Each check also reruns the helper, even with no tint change, when WhichSpace's pid or the set of displays differs from the last run. A relaunched WhichSpace shows the colors it last saved, which can be stale, and the helper writes only connected displays. This catches a WhichSpace that starts after the watcher (login) or restarts, within one poll. NSWorkspace posts no launch notification for WhichSpace (an `LSUIElement` app), so a launch observer never fired (10-20).

- **Settling:** a WhichSpace counts as running only once it has finished launching and been up 2s. Earlier, it may not be scriptable yet, or may load its saved colors over the helper's. The watcher rechecks when the 2s are up.
- **Repair without a sample:** if the sample is inconclusive at that moment, it repaints the last tint.
- **Retries:** a helper run counts only if it exits 0. A failed run logs "command failed" once and is retried at every check.

While the display is off, ScreenCaptureKit lists no displays and every capture fails. The watcher logs that once ("capture failed, keeping the last tint") and keeps the last sampled tint until the display wakes. It used to fall back to the proxy here, which recolored WhichSpace wrong overnight (10-14). A sample with too few glyph pixels to judge also keeps the last tint. It logs "inconclusive sample" once per run of them, and "sample conclusive again" when the run ends.

## What didn't work (macOS 27)

- **AppKit's menu bar appearance**: `+[NSAppearance _menuBarAppearanceProxy]`, `+[NSMenu _menuBarIsDark]` and `+[NSMenuBarPresentationInstance _carbonMenuBarAppearance]` all agree, and they flip correctly for black or bright wallpapers. Over the mid-tone amber "Macintosh" wallpaper, though, they report light while macOS draws white glyphs (10-14). The glyph color is decided where the bar is drawn on screen, and apps aren't told.
- **System light/dark mode** (`AppleInterfaceStyle`): misses wallpaper-driven tint changes.
- **Hidden status item + KVO on `button.effectiveAppearance`**: works only while the item is placed in the menu bar. Barbee hides new items: their window gets zero height and stops getting updates.
- **Sampling the Control Center icon**: status items aren't separate windows in `CGWindowListCopyWindowInfo` on macOS 27, so their position needs Accessibility permission. The Apple logo needs none.
- **System-wide state:** `MenuBarAgent` samples the backdrop itself and posts no distributed or Darwin notification and stores no defaults key.

## Debugging

- `menubar-tint-notify --classify <menubar.png>` runs the classifier on a screenshot crop of the menu bar's left end.
- `MENUBAR_TINT_DUMP=<dir>` in the LaunchAgent's `EnvironmentVariables` writes every captured sample there (`launchctl setenv` doesn't reach it).
- **Run GUI probes outside the Claude Code sandbox**, as a temporary LaunchAgent. Inside it, `NSApp.effectiveAppearance` reads Aqua in dark mode and the window list is incomplete.
