export type FeatureGroup = {
  title: string;
  items: string[];
};

/** Features verified in VERSION_1.md, VERSION_2.md, VERSION_2.1.md, and VERSION_2.2.md */
export const implementedFeatures: FeatureGroup[] = [
  {
    title: "Import & scripts",
    items: [
      "Google Slides — paste URL, speaker notes via read-only OAuth",
      "Keynote (.key) — local file, notes via Keynote.app AppleScript",
      "PowerPoint (.pptx) — import exported deck without Google sign-in",
      "Write / paste — blank rich-text script",
      "Scripts window — source badges, rich-text editor, Edit / Cancel / Save",
      "Local storage — ~/Library/Application Support/NotchPrompter/",
    ],
  },
  {
    title: "Present mode",
    items: [
      "Floating panel at the MacBook notch with notch-shaped clip",
      "Invisible to screen sharing (sharingType = .none)",
      "Auto-scroll — adjustable speed (10–200 px/s)",
      "Voice-activated line scrolling with on-device speech recognition",
      "Real-time word highlighting in voice mode",
      "Manual scroll, hover to pause, countdown before scroll (0–10 s)",
      "Toolbar — camera mirror, text colour, font size ±, edit, stop",
      "Slide indicator, elapsed timer, mic level meter and input picker",
      "In-prompter editing; double-click word for ALL CAPS emphasis",
      "Edit-mode snippet buttons — insert keywords like --PAUSE-- at cursor",
      "Shortcuts — ⌘P present, ⌘↑↓ speed, ⌘+− size, ⌘N new script",
    ],
  },
  {
    title: "Google Slides live sync",
    items: [
      "Follow presenter mode — reads slide from browser tab URL",
      "Scans all browser tabs; prioritises audience slideshow",
      "Auto-selects script by presentation ID",
      "Two-way sync — Save pushes edits back to Google Slides API",
      "Requires macOS Automation permission for your browser",
    ],
  },
  {
    title: "Camera mirror",
    items: [
      "Separate floating window — visible in recordings; prompter stays hidden",
      "Horizontal flip; rectangle or circle crop",
      "Snap positions, display picker, keep in front",
      "macOS camera reactions (thumbs up, balloons, hearts, fireworks, etc.)",
      "Polaroid capture — freeze frame, caption, emoji stickers, save PNG",
      "Emoji picker — search, category tabs, ~1,900 glyphs",
    ],
  },
  {
    title: "Menu bar & settings",
    items: [
      "Menu bar extra — script title, start/stop, open editor, quit",
      "Scrolling defaults, voice activation toggle, mic sensitivity",
      "Camera window type, shape, and position options",
      "Google OAuth Client ID setup and sign out",
    ],
  },
];

export const requirements = [
  "macOS 14.0+",
  "Microphone (voice scroll)",
  "Camera (optional — mirror & Polaroid)",
  "Keynote app (.key import only)",
  "Google Cloud OAuth client (live Slides import)",
];

export const privacyPoints = [
  "Scripts stored locally on your Mac after import",
  "Google Slides — read-only OAuth for import; write-back only when you Save",
  "Keynote import reads notes via AppleScript; does not modify the file",
  "Speech recognition runs on-device for voice scrolling",
];
