# NotchPrompter — Version 2.2 (Milestone)

**Tagged:** 2026-06-29  
**Git tag:** `v2.2.0`  
**App version:** 2.2.0 (`CFBundleShortVersionString`)

This release builds on [VERSION_2.1.md](VERSION_2.1.md) with edit-mode snippet insertion for speaker notes.

## Revert to Version 2.2

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
git checkout v2.2.0
./build.sh
```

To return to latest work:

```bash
git checkout main
```

## Version 2.2 — Highlights

### Edit-mode snippet buttons
- Row of capsule buttons below the ALL CAPS help text when editing speaker notes
- **`--PAUSE--`** button inserts the keyword at the text cursor (or replaces the selection)
- Snippet bar sits between the toolbar and the notes editor for reliable visibility
- Extensible `PrompterEditSnippet` enum — add more keywords as new button cases

## Build

```bash
cd /Users/ymmit/Projects/admin/NotchPrompter
./build.sh
# Output: dist/NotchPrompter.app
```
