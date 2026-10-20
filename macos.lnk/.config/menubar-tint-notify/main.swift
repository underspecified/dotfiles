// Usage: menubar-tint-notify <command> [args...]
//        menubar-tint-notify --classify <menubar.png>   (test the sampler on a screenshot)
// Runs `<command> [args...] dark|light` at start and whenever the menu bar's
// tint changes. The tint follows the wallpaper behind the menu bar, not the
// system light/dark mode (that's dark-mode-notify), so a dynamic wallpaper can
// flip it during the day with no mode change.
// How: samples the menu bar's left end (Apple logo + app name) with
// ScreenCaptureKit and checks whether the glyphs are lighter or darker than the
// backdrop, i.e. copies the color macOS actually drew. No API reports that:
// AppKit's private _menuBarAppearanceProxy says VibrantLight over a mid-tone
// wallpaper while macOS draws white glyphs. Needs Screen Recording permission;
// without it, falls back to that proxy. While the display is off there is
// nothing to capture, so it keeps the last tint.
// Samples at start, on tint/mode change, Space change, wake, display wake, and
// every 10s: a dynamic wallpaper ("Macintosh" animates its colors) shifts with
// no notification. Each sample also reruns the command when WhichSpace has
// (re)started or the displays changed since the last run.
// Debug: MENUBAR_TINT_DUMP=<dir> writes each captured sample there.
// Build: swiftc -O main.swift -o /tmp/mtn && mv /tmp/mtn menubar-tint-notify

import Cocoa
import ScreenCaptureKit

@Sendable func warn(_ message: String) {
    FileHandle.standardError.write(Data("\(Date()) menubar-tint-notify: \(message)\n".utf8))
}

// Glyph pixels are those far from the backdrop (the median luminance); the
// tint is dark when most of them are lighter than it (white glyphs).
func classify(_ image: CGImage) -> (tint: String, detail: String)? {
    let w = image.width, h = image.height
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let drawn = px.withUnsafeMutableBytes { buf -> Bool in
        guard let ctx = CGContext(
            data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return true
    }
    guard drawn else { return nil }
    let lum = stride(from: 0, to: px.count, by: 4).map {
        (0.2126 * Double(px[$0]) + 0.7152 * Double(px[$0 + 1]) + 0.0722 * Double(px[$0 + 2])) / 255
    }
    let backdrop = lum.sorted()[lum.count / 2]
    let glyph = lum.filter { abs($0 - backdrop) > 0.2 }
    guard glyph.count >= 12 else { return nil }
    let lighter = glyph.filter { $0 > backdrop }.count
    let tint = lighter * 2 > glyph.count ? "dark" : "light"
    let detail = String(
        format: "backdrop %.2f, %d glyph px, %d%% lighter", backdrop, glyph.count, lighter * 100 / glyph.count)
    return (tint, detail)
}

// Points from the left edge to sample: the Apple logo plus the start of the app name.
let sampleWidth: CGFloat = 160
let pollSeconds: TimeInterval = 10

if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--classify" {
    let url = URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL
    guard let src = CGImageSourceCreateWithURL(url, nil), let image = CGImageSourceCreateImageAtIndex(src, 0, nil)
    else {
        warn("can't read \(CommandLine.arguments[2])")
        exit(1)
    }
    // A screenshot's scale is unknown; treat its full width as the sample.
    print(classify(image).map { "\($0.tint) (\($0.detail))" } ?? "inconclusive")
    exit(0)
}

let command = Array(CommandLine.arguments.dropFirst())
guard !command.isEmpty else {
    FileHandle.standardError.write(Data("usage: menubar-tint-notify <command> [args...]\n".utf8))
    exit(2)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let proxySelector = NSSelectorFromString("_menuBarAppearanceProxy")
let proxy = NSAppearance.responds(to: proxySelector)
    ? (NSAppearance.self as AnyObject).perform(proxySelector)?.takeUnretainedValue() as? NSObject
    : nil
let dumpDir = ProcessInfo.processInfo.environment["MENUBAR_TINT_DUMP"]

if !CGPreflightScreenCaptureAccess() {
    warn("no Screen Recording permission: following the appearance proxy until it's granted")
    CGRequestScreenCaptureAccess()
}

struct CaptureError: Error, CustomStringConvertible { let description: String }

// The left end of the main display's menu bar, as drawn on screen.
@Sendable func captureMenuBar() async throws -> CGImage {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) ?? content.displays.first
    else { throw CaptureError(description: "no display to capture (display off?)") }
    let screen = await MainActor.run {
        NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
                == display.displayID
        }.map { (barHeight: $0.frame.maxY - $0.visibleFrame.maxY, scale: $0.backingScaleFactor) }
    }
    let scale = screen?.scale ?? 2
    let rect = CGRect(x: 0, y: 0, width: sampleWidth, height: max(screen?.barHeight ?? 0, 24))
    let config = SCStreamConfiguration()
    config.sourceRect = rect
    config.width = Int(rect.width * scale)
    config.height = Int(rect.height * scale)
    config.showsCursor = false
    let filter = SCContentFilter(display: display, excludingWindows: [])
    return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
}

@Sendable func dump(_ image: CGImage) {
    guard let dumpDir else { return }
    let url = URL(fileURLWithPath: dumpDir).appendingPathComponent("menubar-\(Int(Date().timeIntervalSince1970)).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

var captureFailing = false
var inconclusive = false

// nil = inconclusive this time: keep the last tint. A failed capture keeps it
// too (it fails whenever the display is off); only a missing permission falls
// back to the proxy, which is wrong over mid-tone wallpapers.
@MainActor @Sendable
func readTint() async -> (tint: String, detail: String)? {
    guard CGPreflightScreenCaptureAccess() else {
        let appearance = proxy?.value(forKey: "effectiveAppearance") as? NSAppearance ?? app.effectiveAppearance
        let tint = appearance.name.rawValue.lowercased().contains("dark") ? "dark" : "light"
        return (tint, "proxy \(appearance.name.rawValue)")
    }
    do {
        let sample = try await captureMenuBar()
        if captureFailing { warn("capture works again") }
        captureFailing = false
        dump(sample)
        let result = classify(sample)
        if result == nil, !inconclusive { warn("inconclusive sample, keeping the last tint until one is clear") }
        inconclusive = result == nil
        return result
    } catch {
        if !captureFailing { warn("capture failed, keeping the last tint until it works: \(error)") }
        captureFailing = true
        return nil
    }
}

// What the command last colored. A WhichSpace restart drops the colors, and
// the helper writes only connected displays. NSWorkspace posts no launch
// notification for WhichSpace (an LSUIElement app), so each sample compares.
struct Target: Equatable {
    let whichSpace: pid_t?
    let displays: [CGDirectDisplayID]

    @MainActor static func current() -> Target {
        Target(
            whichSpace: NSRunningApplication.runningApplications(withBundleIdentifier: "io.gechr.WhichSpace")
                .first?.processIdentifier,
            displays: NSScreen.screens.compactMap {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
            }.sorted())
    }
}

var lastTint: String?
var lastTarget: Target?
var sampling = false
var pending: (force: Bool, queued: Bool) = (false, false)

@MainActor
func notify(force: Bool = false) {
    guard !sampling else {
        pending = (pending.force || force, true)
        return
    }
    sampling = true
    Task { @MainActor in
        let target = Target.current()
        var stale = ""
        if let lastTarget, target.whichSpace != nil, target != lastTarget {
            stale = target.whichSpace != lastTarget.whichSpace ? "; WhichSpace started" : "; displays changed"
        }
        if let (tint, detail) = await readTint(), force || tint != lastTint || !stale.isEmpty {
            lastTint = tint
            lastTarget = target
            warn("\(tint) (\(detail)\(stale))")
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
        sampling = false
        if pending.queued {
            let again = pending.force
            pending = (false, false)
            notify(force: again)
        }
    }
}

// Let the menu bar redraw before sampling it.
func notifySoon(after seconds: Double = 0.5, force: Bool = false) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        MainActor.assumeIsolated { notify(force: force) }
    }
}

// AppKit posts these notifications on the main thread.
let center = NSWorkspace.shared.notificationCenter
center.addObserver(
    forName: Notification.Name("NSWorkspaceMenuBarAppearanceDidChangeNotification"), object: nil, queue: .main
) { _ in notifySoon() }
DistributedNotificationCenter.default().addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main
) { _ in notifySoon() }
center.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { _ in
    notifySoon()
}
center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
    notifySoon(after: 2, force: true)
}
center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { _ in
    notifySoon(after: 1)
}
Timer.scheduledTimer(withTimeInterval: pollSeconds, repeats: true) { _ in
    MainActor.assumeIsolated { notify() }
}

MainActor.assumeIsolated { notify() }
app.run()
