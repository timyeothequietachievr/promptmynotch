# NotchPrompter — Version 1.0.0 (Milestone)

**Tagged:** 2026-06-29  
**Git tag:** `v1.0.0`  
**App version:** 1.0.0 (`CFBundleShortVersionString`)

This document marks the first stable milestone. All key workflows below were verified working at this point.

## Revert to Version 1

If you ask to **revert to version one** (or **v1 milestone**), restore the codebase to git tag `v1.0.0`:

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
git checkout v1.0.0
```

To return to latest work after inspecting v1:

```bash
git checkout main
```

Rebuild after reverting:

```bash
./build.sh
```

## Version 1 — Working functionality

### Import & scripts
- Google Slides import (OAuth, speaker notes via API)
- Keynote `.key` import
- PowerPoint `.pptx` import
- Scripts window: list, edit, rich text, local persistence (`~/Library/Application Support/NotchPrompter/scripts.json`)

### Present mode (notch prompter)
- Floating notch-positioned prompter panel
- Countdown before scroll
- Auto-scroll with speed control
- Voice-activated line scrolling (mic)
- Manual scroll (drag)
- Slide indicator and elapsed timer
- Toolbar: camera mirror, text color, font +/- , edit, stop (X)
- Large filled-circle toolbar icons (edit, X, video, palette, +/-)

### Edit mode (in prompter)
- Pencil button beside timer enters edit mode
- Full speaker-notes text editing
- Double-click word: toggle normal ↔ ALL CAPS (with amber pulse)
- Save: updates local script, prompter display, scripts window, and Google Slides speaker notes
- Cancel: reverts unsaved edits

### Google Slides sync
- Follow presenter slide from browser URL
- Push speaker-notes text changes back to Google Slides on Save
- Small-caps / emphasis API path (legacy toggle keys; edit mode uses literal ALL CAPS in text)

### Camera
- Camera mirror window (popover / snap positions)
- Polaroid-style capture flow

## Build

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
./build.sh
# Output: dist/NotchPrompter.app
```

## Intentionally not in v1

- Present-mode double-click word emphasis overlay (replaced by edit mode)
- Orange click flash dot on present-mode clicks (removed)
