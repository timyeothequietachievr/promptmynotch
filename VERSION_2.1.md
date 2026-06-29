# NotchPrompter — Version 2.1 (Milestone)

**Tagged:** 2026-06-29  
**Git tag:** `v2.1.0`  
**App version:** 2.1.0 (`CFBundleShortVersionString`)

This release builds on [VERSION_2.md](VERSION_2.md) with Polaroid, emoji picker, and Google Slides sync improvements.

## Revert to Version 2.1

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
git checkout v2.1.0
./build.sh
```

To return to latest work:

```bash
git checkout main
```

## Version 2.1 — Highlights

### Polaroid
- Click-to-edit caption on the white strip (no double-click)
- Separate timestamp on photo bottom-right; user caption in strip only
- Larger caption text; transparent editor (no grey TextField background)
- Circle mode: Polaroid ejects **top-down** into the slot below the circle
- Crash fix: removed nested hosting view that caused layout recursion

### Emoji picker
- macOS-style searchable picker with category tabs
- Full emoji library (~1,900 glyphs) with correct category mapping
- Smileys & People tab populated (faces, gestures, people)
- Default category: Recents (or Smileys when empty)

### Google Slides sync
- Scans all browser tabs (not only the front window)
- Prioritizes audience slideshow over presenter-notes window

### Camera UI
- Custom capture camera icon
- Caption placeholder centered (“Click to add text”)

## Build

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
./build.sh
# Output: dist/NotchPrompter.app
```
