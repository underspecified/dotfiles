# menubar-tint-notify

Recolors the WhichSpace menu bar icon to match the menu bar: a square in the color macOS drew the menu bar glyphs in, sampled from the screen. Without a sample it falls back to a fixed color for the tint: a light (`#E9F1F3`) square on a dark menu bar, a dark (`#1F1E0B`) one on a light menu bar.

macOS picks the menu bar tint from the wallpaper behind it, not from the system light/dark mode. WhichSpace draws a full-color icon that follows only the system mode, so with a dynamic wallpaper it ends up the wrong color. Other icons are template images, which macOS tints itself. `dark-mode-notify` can't fix this either, because it also sees only the system mode.

## Files

| File | Role |
|------|------|
| `main.swift` | Watcher source. Runs `<command> dark\|light [RRGGBB]` at start, whenever the sampled tint or glyph color changes, and when WhichSpace restarts or the displays change. |
| `menubar-tint-notify` | Compiled watcher, committed so other Macs need no build step. |
| `menubar-tint-helper` | Sets WhichSpace's per-Space colors via AppleScript: `RRGGBB` if given, else the tint's fixed color. Skips if WhichSpace isn't running. |
| `setup-signing.sh` | One-time setup of the signing identity used by the rebuild. |
| `~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist` | Runs the watcher at login, keeps it alive. Tracked in `.lnk.macos`. |

Log: `~/Library/Logs/menubar-tint-notify.log`, one watcher line (tint, sampled hex, sample stats) and one helper line (the hex it painted) per recolor.

## Usage

- **Screen Recording permission** is required on each Mac: System Settings → Privacy & Security → Screen & System Audio Recording → `menubar-tint-notify`. Then `launchctl kickstart -k gui/$(id -u)/com.eric.menubar-tint-notify`. Without it, the log says so and the watcher falls back to the appearance proxy, which is wrong over mid-tone wallpapers.
- **Signing setup**, once, on the Mac that rebuilds: `bash setup-signing.sh`. It creates the self-signed code-signing identity `menubar-tint-notify` in the login keychain and lets `codesign` use it. Only a Mac holding that key can rebuild; other Macs run the committed binary.
- **Rebuild** after editing `main.swift`: `swiftc -O main.swift -o /tmp/mtn && codesign -f -s menubar-tint-notify --identifier com.eric.menubar-tint-notify /tmp/mtn && mv /tmp/mtn menubar-tint-notify` (replace the inode; never overwrite the running binary), then kickstart. The designated requirement names the identifier and the certificate, not one build, so **a rebuild keeps Screen Recording** on every Mac. Ad-hoc builds (until 10-21) didn't: each rebuild could drop it.
- **Permission lost anyway** (the first signed build replaces an ad-hoc grant): the log says no permission, and toggling it off and on doesn't help. Remove the entry with **−**, kickstart (the watcher re-requests and re-adds itself), enable it, and kickstart again.
- **Load now** instead of at the next login: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.eric.menubar-tint-notify.plist`.
- **Manual toggle:** `bash ~/.config/menubar-tint-notify/menubar-tint-helper dark` or `light`, optionally followed by an sRGB hex color (`light 2B2A26`). The argument names the **menu bar** tint, so `dark` gives the light icon. The watcher overrides it at its next recolor.
- **Colors** replace whatever is set in WhichSpace's settings. The fixed fallbacks are hard-coded in the helper; the watcher uses them when it has no sample (no Screen Recording) or too few solid glyph pixels.

## How it reads the tint

It captures the left end of the main display's menu bar with ScreenCaptureKit (Apple logo + app name, always present at a fixed spot). The median luminance is the backdrop; pixels far from it are glyphs. Mostly lighter glyphs means white glyphs, so the tint is `dark`. This copies the color macOS actually drew, so there is no threshold to tune.

The square's color is the mean of the 10% of the tint's glyph pixels farthest from the backdrop: the solid strokes, not their anti-aliased edges. It needs at least 12 such pixels, or the helper's fixed color is used. The capture is in the display's color profile; the watcher reads it in sRGB, the space WhichSpace parses AppleScript hex colors in, so the square matches the glyphs on screen. A color change of 8 or less (0–255, in every channel) since the last recolor doesn't recolor, so an animating wallpaper doesn't rerun the helper at every poll. A tint change always does.

It checks at start, on `NSWorkspaceMenuBarAppearanceDidChangeNotification`, on a system mode change, Space change, wake, display wake, and every 10s, because a dynamic wallpaper shifts with no notification ("Macintosh" animates its colors continuously). The capture shows no screen-recording indicator.

Each check also reruns the helper, even with no tint change, when WhichSpace's pid or the set of displays differs from the last run. A relaunched WhichSpace shows the colors it last saved, which can be stale, and the helper writes only connected displays. This catches a WhichSpace that starts after the watcher (login) or restarts, within one poll. NSWorkspace posts no launch notification for WhichSpace (an `LSUIElement` app), so a launch observer never fired (10-20).

- **Settling:** a WhichSpace counts as running only once it has finished launching and been up 2s. Earlier, it may not be scriptable yet, or may load its saved colors over the helper's. The watcher rechecks when the 2s are up.
- **Repair without a sample:** if the sample is inconclusive at that moment, it repaints the last tint and color.
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
