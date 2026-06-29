# NotchPrompter

A native macOS teleprompter inspired by [Moody](https://moody.mjarosz.com), with **Google Slides** and **Keynote** speaker notes import as the primary workflow.

> **Version 2.2 milestone** — see [VERSION_2.2.md](VERSION_2.2.md) for the v2.2 feature list and how to revert (`git tag v2.2.0`). Version 2.1: [VERSION_2.1.md](VERSION_2.1.md) (`v2.1.0`). Version 2: [VERSION_2.md](VERSION_2.md) (`v2.0.0`). Version 1: [VERSION_1.md](VERSION_1.md) (`v1.0.0`).

## Import priority

1. **Google Slides (live)** — paste a Slides URL; speaker notes are fetched via the Google Slides API (read-only).
2. **Keynote (.key)** — pick a local Keynote file; presenter notes are read through Keynote.app via AppleScript.
3. **Google Slides export (.pptx)** — no sign-in: in Slides use *File → Download → Microsoft PowerPoint*, then import the `.pptx`.

## Features

- Notch-positioned floating prompter window
- Invisible to screen sharing (`sharingType = .none`)
- Voice-activated scrolling (pauses when you stop speaking)
- Hover to pause
- Built-in script editor with per-slide separators after import
- 100% on-device storage after import

## Requirements

- macOS 14.0+
- Xcode 15+ (to build)
- Keynote (for `.key` import only)
- Google Cloud OAuth Client ID (for live Google Slides import)

## Build

```bash
cd NotchPrompter
open NotchPrompter.xcodeproj   # ⌘R to run
# or
chmod +x build.sh && ./build.sh
```

## Google Slides setup (one-time)

1. [Google Cloud Console](https://console.cloud.google.com/) → create a project
2. Enable **Google Slides API**
3. **Credentials** → **Create credentials** → **OAuth client ID** → **Desktop app**
4. Add authorized redirect URI: `com.notchprompter:/oauth2callback`
5. In NotchPrompter: **Import → Google Setup** → paste Client ID

## Usage

1. Launch NotchPrompter
2. **Import** speaker notes from Google Slides or Keynote
3. Review/edit the combined script in the editor
4. Click **Present** (⌘P) — countdown, then voice-activated scroll at the notch

## Privacy

- Imported scripts are stored locally in `~/Library/Application Support/NotchPrompter/`
- Google Slides import uses read-only OAuth; notes are not uploaded anywhere else
- Keynote import opens the file briefly via AppleScript and does not save changes
