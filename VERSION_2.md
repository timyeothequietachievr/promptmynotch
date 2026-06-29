# NotchPrompter — Version 2.0.0 (Milestone)

**Tagged:** 2026-06-29  
**Git tag:** `v2.0.0`  
**App version:** 2.0.0 (`CFBundleShortVersionString`)

This document marks the Version 2 milestone. It builds on [VERSION_1.md](VERSION_1.md) with camera, scripts editor, and prompter UX improvements.

## Revert to Version 2

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
git checkout v2.0.0
./build.sh
```

To return to latest work:

```bash
git checkout main
```

## Version 2 — Highlights

### Scripts window
- Edit / Cancel / Save workflow (no auto-save while editing)
- Google Slides source badge beside title
- Camera icon in title bar; opens mirror anchored to prompter when presenting
- Stop resets presentation and camera to defaults

### Prompter
- Text color palette icon (macOS color panel) with persisted color
- Mic input source label centered above level meter
- Empty slide notes: “Click to add speaker notes” opens edit mode
- Window drag handle and toolbar styling refinements

### Camera mirror
- Default rectangle height matches prompter panel height
- Three-shape toggle: rectangle, circle (big), smaller circle placeholder
- Hover-only toolbar; Polaroid ejects from bottom in circle mode
- Instant close + full reset when hiding camera or stopping (Polaroid discarded, rectangle restored)
- Split-pill reactions control: last-used gesture replay + dropdown chevron
- Unified 32pt control bar height

### Polaroid
- Circle-mode eject below the circle (not centered on video)
- Close camera during Polaroid → clean reopen without size glitches

## Build

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
./build.sh
# Output: dist/NotchPrompter.app
```
