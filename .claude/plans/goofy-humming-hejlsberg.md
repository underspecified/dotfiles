# Fix kitty cursor not updating on darkman toggle

## Problem

When darkman toggles between light/dark mode:
- GTK apps update cursor live (via gsd-xsettings broadcast) ✓
- Root window updates (via xsetroot) ✓  
- Kitty does NOT update — it's not GTK, so it caches its X11 cursor at startup ✗

The user does not want to manually restart kitty each time.

## Root Cause

X11 apps cache cursor images at window creation time. Only GTK apps listen for the XSETTINGS change notification and reload. Non-GTK apps (kitty, Chrome, 1Password) keep their original cursor.

## Solution

Use the **XFixes** X11 extension (`XFixesChangeCursorByName`), which globally replaces a named cursor for ALL windows — including non-GTK apps — without restarting anything. `libXfixes` is already installed.

Create a small Python script (`change_cursor_theme.sh`) that:
1. Loads the new cursor from the DMZ theme file using `libXcursor`
2. Calls `XFixesChangeCursorByName` to replace the cursor globally

Then call it from the darkman toggle functions in util.sh.

## Files to create/modify

### 1. Create `linux.lnk/.local/bin/change_cursor_theme` (new script)

A Python script using ctypes to call XFixesChangeCursorByName. Takes the theme name and size as arguments.

Usage: `change_cursor_theme DMZ-White 36`

This replaces the cursor globally for all X11 windows.

### 2. Modify `linux.lnk/.local/bin/util.sh`

Replace the `xsetroot -xcf` calls in `toggle_gnome_dark`/`toggle_gnome_light` with `change_cursor_theme`:

```bash
toggle_gnome_dark () {
    ...
    gsettings set org.gnome.desktop.interface cursor-theme "DMZ-White"
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nInherits=DMZ-White\n' > "$HOME/.icons/default/index.theme"
    "$HOME/.local/bin/change_cursor_theme" DMZ-White 36
}
```

The script handles both root window and all app windows, so `xsetroot -xcf` is no longer needed.

### 3. Cleanup

- Delete stale `linux.lnk/.xprofile`
- Remove `export XCURSOR_THEME` lines from `util.sh` (useless — only affects darkman's subprocess)
- Remove `export XCURSOR_THEME` line from `zshrc.x11` (redundant with index.theme)
- Remove `xsetroot -cursor_name left_ptr` from `system.conf` (change_cursor_theme handles it)

## Verification

1. `darkman set light` → all windows (including kitty) should show DMZ-Black cursor
2. `darkman set dark` → all windows (including kitty) should show DMZ-White cursor
3. No app restarts needed
