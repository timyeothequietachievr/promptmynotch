export type FeatureBlockContent = {
  id: string;
  eyebrow?: string;
  title: string;
  lead?: string;
  body?: string[];
  bullets?: string[];
  image?: {
    src: string;
    alt: string;
    caption?: string;
  };
  reverse?: boolean;
};

export const hero = {
  headline: "Never forget your lines again",
  subhead:
    "A teleprompter that stays invisible on screen share. No one will ever know.",
  pills: [
    "Google Slides sync",
    "Hidden from screen share",
    "Mirror Check",
  ],
};
export const intro = {
  question: "What's Prompt My Notch?",
  answer:
    "It's a native macOS app that puts your speaker notes in the notch — right below your camera — so you can read while maintaining eye contact.",
  why: "Yeah but... why do I need this?",
  whyAnswer:
    "You know when you're on a Zoom interview or meeting and you need your notes, but your normal notes app shows up when you screen share? Or your notes are on another monitor and you break eye contact with the attendees? Prompt My Notch fixes that. The script sits where you're already looking. Your audience never sees it.",
};

export const steps = [
  {
    step: "1",
    title: "Import your notes",
    body: "Paste a Google Slides link, open a Keynote file, drop in a PowerPoint export, or write from scratch. Your scripts save locally on your Mac.",
  },
  {
    step: "2",
    title: "Look at camera, read text",
    body: "Hit Present. Notes appear at the notch. Auto-scroll at your pace, or drag to move through the script. Hover to pause.",
  },
  {
    step: "3",
    title: "They never know",
    body: "Share your screen on Zoom, Meet, Teams, or OBS. The prompter stays on your Mac. Your secret stays safe.",
  },
];

export const featureBlocks: FeatureBlockContent[] = [
  {
    id: "notch",
    eyebrow: "The notch",
    title: "Speaker notes where you're already looking.",
    lead: "Prompt My Notch uses the dead space around your MacBook camera — the bit you never needed for anything else anyway.",
    body: [
      "A floating panel clips to the notch shape and sits right under your webcam. You read your script while looking straight into the lens. No second monitor. No darting eyes.",
      "It uses macOS sharingType = .none, so screen capture tools don't pick it up. Zoom, Google Meet, Microsoft Teams, OBS — your audience sees your slides, not your notes.",
    ],
    bullets: [
      "Drag the top handle to reposition",
      "Countdown before scroll starts (0–10 seconds)",
      "Slide indicator and elapsed timer",
      "⌘P to start or stop presenting",
    ],
    image: {
      src: "/screenshots/camera-mirror.png",
      alt: "Prompt My Notch present mode at the MacBook notch",
      caption: "Present mode — notes at the notch, toolbar, and optional camera mirror.",
    },
  },
  {
    id: "scroll",
    eyebrow: "Scrolling",
    title: "Scroll at your pace. Pause when you need to.",
    lead: "You don't present at a constant speed. You pause for effect. Speed up when excited. Slow down to make a point. Your teleprompter should keep up.",
    body: [
      "Auto-scroll runs at 10–200 px/s — set your default in Settings, then nudge with ⌘↑ and ⌘↓ while presenting.",
      "Prefer hands-on control? Drag to scroll manually, or hover anywhere on the prompter to freeze the script instantly.",
    ],
    bullets: [
      "Countdown before scroll starts (0–10 seconds)",
      "Hover to pause or resume",
      "⌘↑ / ⌘↓ to adjust scroll speed on the fly",
      "⌘+ / ⌘− for font size",
    ],
    reverse: true,
  },
  {
    id: "import",
    eyebrow: "Import",
    title: "Pull notes from the tools you already use.",
    lead: "You shouldn't have to copy-paste speaker notes slide by slide. Prompt My Notch imports them for you.",
    body: [
      "Paste a Google Slides URL and sign in once with read-only OAuth. Pick a local Keynote .key file and notes are read via Keynote.app. Import an exported .pptx without Google sign-in. Or start from a blank rich-text script.",
    ],
    bullets: [
      "Google Slides — live URL, speaker notes via API",
      "Keynote (.key) — AppleScript, file unchanged",
      "PowerPoint (.pptx) — offline import",
      "Write / paste — rich-text editor with source badges",
    ],
  },
  {
    id: "scripts",
    eyebrow: "Scripts window",
    title: "Your scripts live on your Mac. Full stop.",
    lead: "After import, everything stays local. Edit, save, present — no cloud storage, no account required.",
    body: [
      "The scripts window lists every deck with a badge showing where it came from — Google Slides, Keynote, PowerPoint, or manual. Open one, tweak the rich text, and hit Present when you're ready.",
      "Edit / Cancel / Save — no auto-save while you're editing, so you won't accidentally overwrite something mid-thought.",
    ],
    bullets: [
      "Stored in ~/Library/Application Support/PromptMyNotch/",
      "Present (⌘P) and Stop from the editor",
      "Camera icon opens mirror anchored to the prompter",
      "⌘N for a new script",
    ],
    reverse: true,
  },
  {
    id: "slides-sync",
    title: "Google Slides sync",
    lead: "Presenting in Google Slides in the browser? Prompt My Notch reads which slide you're on and shows the matching speaker notes — automatically.",
    body: [
      "Make changes to your speaker notes and they are synced both ways.",
    ],
    bullets: [
      "Works in Chrome, Safari and more",
    ],
  },
  {
    id: "camera",
    title: "Mirror Check",
    lead: "Want to look your best? Use Mirror Check for a quick look and make sure nothing embarrassing is in frame.",
    bullets: [
      "Horizontal flip for a natural mirror view",
      "Rectangle or circle window",
      "Switch cameras",
    ],
    image: {
      src: "/screenshots/mirror-check.png",
      alt: "Prompt My Notch Mirror Check camera preview",
    },
    reverse: true,
  },
  {
    id: "polaroid",
    eyebrow: "Take a photo",
    title: "Save the moment",
    bullets: [
      "Click to add captions",
      "Timestamp (in case you need proof of life 🤪)",
      "Add effects, emojis 🎉",
      "Use Apple's built-in camera reaction effects — Thumbs up, peace sign & more",
    ],
    image: {
      src: "/screenshots/polaroid-capture.png",
      alt: "Prompt My Notch Polaroid capture with caption editing",
    },
  },
  {
    id: "emoji",
    title: "Stickers, because why not.",
    body: [
      "Choose from 1,900 emojis",
    ],
    image: {
      src: "/screenshots/emoji-stickers.png",
      alt: "Prompt My Notch emoji sticker picker",
    },
    reverse: true,
  },
  {
    id: "reactions",
    eyebrow: "Reactions",
    title: "Thumbs up, Peace sign & more",
    lead: "Uses Apple's built-in camera reaction effects",
  },
  {
    id: "edit",
    title: "Fix a line without stopping the slideshow.",
    bullets: [
      "Per-slide editing during presentation",
      "ALL CAPS emphasis on double-click",
      "Save changes to Google Slides speaker notes",
    ],
    reverse: true,
  },
  {
    id: "menubar",
    eyebrow: "Menu bar",
    title: "Start presenting without hunting for the window.",
    lead: "Prompt My Notch lives in your menu bar. Current script title and source badge are always one click away.",
    body: [
      "Start or stop presenting, open the editor, request slide sync permissions, or quit — from the menu bar extra. Settings cover scroll speed defaults, camera shape and position, and Google OAuth setup.",
    ],
    bullets: [
      "Script title and source in the menu",
      "Start / Stop presentation",
      "Open Editor",
      "Google Setup and sign out",
    ],
  },
];

export const privacy = {
  title: "Your scripts stay on your Mac. Always.",
  lead: "No cloud storage. No analytics on your notes. Import uses read-only Google OAuth; write-back only happens when you tap Save.",
  points: [
    "Scripts in ~/Library/Application Support/PromptMyNotch/",
    "Google Slides — read-only for import; edits write back only on Save",
    "Keynote import via AppleScript — your .key file is never modified",
    "Browser URL reading requires explicit Automation permission",
  ],
};

export const download = {
  title: "Forget forgetting your lines",
  lead: "The app is currently in beta (limited spots). Tell us what you'll use it for & download for free.",
  note: "Public beta · Camera optional · Google Slides sync · Keynote for .key import",
};

export const faqs = [
  {
    q: "Does the prompter stay hidden during video calls?",
    a: "Yes. It sits on a macOS layer that screen capture doesn't see. Zoom, Google Meets, Microsoft Teams — none of them pick it up.",
  },
  {
    q: "Can I import from Google Slides?",
    a: "Yes. Paste your Google Slides URL and off you go.",
  },
  {
    q: "How does scrolling work?",
    a: "Hover your cursor over the teleprompter and scroll using your mouse or trackpad.",
  },
  {
    q: "Does it follow my Google Slides tab in the browser?",
    a: "Yes. As you advance slides, the speaker notes are updated.",
  },
  {
    q: "Is the camera mirror visible on screen share?",
    a: "Yes. The Mirror Check camera is visible on screen share. That makes it great for recording tutorial videos with no additional software.",
  },
];
