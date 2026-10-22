// Usage: menubar-tint-notify <command> [args...]
//        menubar-tint-notify --classify <menubar.png>   (test the sampler on a screenshot)
// Runs `<command> [args...] dark|light [RRGGBB]` at start and whenever the menu
// bar's tint or glyph color changes. RRGGBB is the sRGB color the status items
// show: the sampled glyph color with a little of the backdrop mixed in. It's
// left out when there's no sample (no Screen Recording) or too few solid glyph
// pixels. The tint follows the wallpaper behind the menu bar,
// not the system light/dark mode (that's dark-mode-notify), so a dynamic
// wallpaper can flip it during the day with no mode change.
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
// (re)started, the displays changed, or a Space was added or removed since the
// last run.
// Debug: MENUBAR_TINT_DUMP=<dir> writes each captured sample there.
// Build (signing identity from setup-signing.sh; see the README):
//   swiftc -O main.swift -o /tmp/mtn && codesign -f -s menubar-tint-notify \
//     --identifier com.eric.menubar-tint-notify /tmp/mtn && mv /tmp/mtn menubar-tint-notify

import Cocoa
import ScreenCaptureKit

@Sendable func warn(_ message: String) {
    FileHandle.standardError.write(Data("\(Date()) menubar-tint-notify: \(message)\n".utf8))
}

// An sRGB color, the space WhichSpace parses its AppleScript hex colors in.
struct RGB: Equatable {
    let r, g, b: Int
    var hex: String { String(format: "%02X%02X%02X", r, g, b) }
}

extension RGB {
    init(_ c: [Double]) { self.init(r: Int(c[0].rounded()), g: Int(c[1].rounded()), b: Int(c[2].rounded())) }
}

// A color change of at most this (in every channel, 0-255) doesn't recolor, so
// a slowly animating wallpaper doesn't rerun the command at every poll.
let colorThreshold = 8

// nil = the helper's fixed color for the tint.
func moved(_ a: RGB?, _ b: RGB?) -> Bool {
    guard let a, let b else { return (a == nil) != (b == nil) }
    return max(abs(a.r - b.r), abs(a.g - b.g), abs(a.b - b.b)) > colorThreshold
}

// color: the color to paint, or nil when the sample gives none (the proxy, or
// no trustworthy glyph color).
struct Sample { let tint: String, color: RGB?, detail: String }

// The Apple logo and app name are drawn solid white or black, but the status
// items around WhichSpace (input source, clock) let this much of the wallpaper
// through. Empirical: 10-13% on two wallpapers (10-21).
let backdropShare = 0.12

// Menu bar glyphs are near-neutral. A solid color with a wider channel spread
// (0-255) is app content under the strip: a full-screen Space with the menu bar
// hidden, or an open menu's highlight.
let maxGlyphSpread = 16.0

// Glyph pixels are those far from the backdrop (the median luminance); the
// tint is dark when most of them are lighter than it (white glyphs). The solid
// glyph color is the mean of the 10% of those farthest from the backdrop:
// strokes, not anti-aliased edges. The color to paint mixes it with
// backdropShare of the backdrop color (the mean of the pixels near the median),
// like the status items. Pixels are read in sRGB, which converts the capture
// out of the display's profile.
func classify(_ image: CGImage) -> Sample? {
    let w = image.width, h = image.height
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let drawn = px.withUnsafeMutableBytes { buf -> Bool in
        guard let space = CGColorSpace(name: CGColorSpace.sRGB), let ctx = CGContext(
            data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return true
    }
    guard drawn else { return nil }
    let lum = stride(from: 0, to: px.count, by: 4).map {
        (0.2126 * Double(px[$0]) + 0.7152 * Double(px[$0 + 1]) + 0.0722 * Double(px[$0 + 2])) / 255
    }
    let backdrop = lum.sorted()[lum.count / 2]
    let glyph = lum.indices.filter { abs(lum[$0] - backdrop) > 0.2 }
    guard glyph.count >= 12 else { return nil }
    let lighter = glyph.filter { lum[$0] > backdrop }
    let tint = lighter.count * 2 > glyph.count ? "dark" : "light"
    let side = tint == "dark" ? lighter : glyph.filter { lum[$0] < backdrop }
    let solid = side.sorted { abs(lum[$0] - backdrop) > abs(lum[$1] - backdrop) }.prefix(side.count / 10)
    // No color from this sample with too few solid pixels to trust, or a solid
    // color that isn't near-neutral. It is on the tint's side of the backdrop by
    // construction: every solid pixel is, by more than 0.2.
    var color: RGB?
    var glyphHex = "none"
    if solid.count >= 12 {
        func mean(_ of: some Collection<Int>, _ channel: Int) -> Double {
            of.map { Double(px[$0 * 4 + channel]) }.reduce(0, +) / Double(of.count)
        }
        let glyphColor = (0..<3).map { mean(solid, $0) }
        glyphHex = RGB(glyphColor).hex
        if glyphColor.max()! - glyphColor.min()! <= maxGlyphSpread {
            let ground = lum.indices.filter { abs(lum[$0] - backdrop) < 0.05 }
            color = RGB((0..<3).map { glyphColor[$0] * (1 - backdropShare) + mean(ground, $0) * backdropShare })
        }
    }
    let detail = String(
        format: "backdrop %.2f, %d glyph px, %d%% lighter, %d solid px, glyph %@",
        backdrop, glyph.count, lighter.count * 100 / glyph.count, solid.count, glyphHex)
    return Sample(tint: tint, color: color, detail: detail)
}

// The log and --classify name a sample by its tint and, if sampled, its color.
func describe(_ s: Sample, _ more: String = "") -> String {
    "\(s.tint)\(s.color.map { " \($0.hex)" } ?? "") (\(s.detail)\(more))"
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
    print(classify(image).map { describe($0) } ?? "inconclusive")
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

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}

// The left end of the main display's menu bar, as drawn on screen.
@Sendable func captureMenuBar() async throws -> CGImage {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) ?? content.displays.first
    else { throw CaptureError(description: "no display to capture (display off?)") }
    let screen = await MainActor.run {
        NSScreen.screens.first { $0.displayID == display.displayID }
            .map { (barHeight: $0.frame.maxY - $0.visibleFrame.maxY, scale: $0.backingScaleFactor) }
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
func readTint() async -> Sample? {
    guard CGPreflightScreenCaptureAccess() else {
        let appearance = proxy?.value(forKey: "effectiveAppearance") as? NSAppearance ?? app.effectiveAppearance
        let tint = appearance.name.rawValue.lowercased().contains("dark") ? "dark" : "light"
        return Sample(tint: tint, color: nil, detail: "proxy \(appearance.name.rawValue)")
    }
    do {
        let sample = try await captureMenuBar()
        if captureFailing { warn("capture works again") }
        captureFailing = false
        dump(sample)
        let result = classify(sample)
        if result == nil, !inconclusive { warn("inconclusive sample, keeping the last tint until one is clear") }
        if result != nil, inconclusive { warn("sample conclusive again") }
        inconclusive = result == nil
        return result
    } catch {
        if !captureFailing { warn("capture failed, keeping the last tint until it works: \(error)") }
        captureFailing = true
        inconclusive = false
        return nil
    }
}

// A WhichSpace counts as running once it has finished launching and been up
// this long. Earlier it may not be scriptable yet, or may still be loading its
// saved colors over the ones the helper writes.
let settleSeconds: TimeInterval = 2

// The Spaces of each display, fullscreen ones included, from the private call
// WhichSpace builds its Space list from. Needs no permission. Looked up at run
// time, so if macOS drops it only the Space trigger is lost, not the watcher.
let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
let mainConnectionID = dlsym(rtldDefault, "CGSMainConnectionID")
    .map { unsafeBitCast($0, to: (@convention(c) () -> Int32).self) }
let copyManagedDisplaySpaces = dlsym(rtldDefault, "CGSCopyManagedDisplaySpaces")
    .map { unsafeBitCast($0, to: (@convention(c) (Int32) -> Unmanaged<CFArray>?).self) }
var spaceCountMissing = false

// Spaces per display identifier. Empty when the call is missing or returns
// something unexpected, logged once: new Spaces then don't trigger a recolor.
@MainActor func spaceCounts() -> [String: Int] {
    var counts: [String: Int]?
    if let mainConnectionID, let copyManagedDisplaySpaces,
       let displays = copyManagedDisplaySpaces(mainConnectionID())?.takeRetainedValue() as? [[String: Any]]
    {
        counts = [:]
        for display in displays {
            guard let id = display["Display Identifier"] as? String, let spaces = display["Spaces"] as? [Any] else {
                counts = nil
                break
            }
            counts?[id] = spaces.count
        }
    }
    if counts == nil, !spaceCountMissing {
        warn("Space count unavailable, new Spaces won't trigger a recolor")
        spaceCountMissing = true
    }
    return counts ?? [:]
}

// What the command last colored. A relaunched WhichSpace shows the colors it
// last saved, which can be stale, and the helper writes only connected
// displays and the Spaces that exist: WhichSpace keeps colors per Space
// position, so a new Space has none. NSWorkspace posts no launch notification
// for WhichSpace (an LSUIElement app) and none for a new Space, so each sample
// compares.
struct Target: Equatable {
    let whichSpace: pid_t?
    let displays: [CGDirectDisplayID]
    let spaces: [String: Int]

    // settlesIn: seconds until a WhichSpace that is still settling counts.
    @MainActor static func current() -> (target: Target, settlesIn: TimeInterval?) {
        let instance = NSRunningApplication.runningApplications(withBundleIdentifier: "io.gechr.WhichSpace")
            .first { !$0.isTerminated }
        let age = instance?.launchDate.map { -$0.timeIntervalSinceNow } ?? settleSeconds
        let settled = instance?.isFinishedLaunching == true && age >= settleSeconds
        let target = Target(
            whichSpace: settled ? instance?.processIdentifier : nil,
            displays: NSScreen.screens.compactMap(\.displayID).sorted(),
            spaces: spaceCounts())
        return (target, instance != nil && age < settleSeconds ? settleSeconds - age + 0.1 : nil)
    }
}

var lastTint: String?
var lastColor: RGB?
var lastTarget: Target?
// After a run for changed Spaces, run once more at the next check: WhichSpace
// may not have listed a new Space yet when the command ran.
var recheckSpaces = false
var commandFailing = false
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
        let (target, settlesIn) = Target.current()
        if let settlesIn { notifySoon(after: settlesIn) }
        var stale = ""
        if let lastTarget, target.whichSpace != nil, target != lastTarget {
            stale = target.whichSpace != lastTarget.whichSpace ? "; WhichSpace started"
                : target.displays != lastTarget.displays ? "; displays changed" : "; Spaces changed"
        } else if recheckSpaces, target.whichSpace != nil {
            stale = "; Spaces recheck"
        }
        // A restart, display or Space change needs no fresh sample: repaint the last tint and color.
        // A sample with no color keeps the color last painted for its tint, so the
        // square doesn't flash the fixed color: that is for a tint with no color yet.
        let sample = await readTint().map {
            Sample(tint: $0.tint, color: $0.color ?? ($0.tint == lastTint ? lastColor : nil), detail: $0.detail)
        } ?? (stale.isEmpty ? nil : lastTint.map { Sample(tint: $0, color: lastColor, detail: "last tint") })
        if let sample,
           force || commandFailing || sample.tint != lastTint || moved(sample.color, lastColor) || !stale.isEmpty
        {
            // While the command keeps failing, its own line is the only one per retry.
            if !commandFailing { warn(describe(sample, stale)) }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = command + [sample.tint] + (sample.color.map { [$0.hex] } ?? [])
            var ok = false
            do {
                try task.run()
                task.waitUntilExit()
                ok = task.terminationStatus == 0
            } catch {
                warn("\(error)")
            }
            // Only a run that worked counts as done; a failed one is retried at every check.
            if ok {
                if commandFailing { warn("command works again") }
                recheckSpaces = lastTarget.map { $0.spaces != target.spaces } ?? false
                lastTint = sample.tint
                lastColor = sample.color
                lastTarget = target
            } else if !commandFailing {
                warn("command failed, retrying at every check")
            }
            commandFailing = !ok
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
