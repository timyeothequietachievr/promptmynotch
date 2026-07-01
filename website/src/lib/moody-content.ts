import { download, faqs, hero, privacy, steps } from "./content";

/** Scrolling lines shown inside the hero notch demo */
export const notchScriptLines = [
  "Maintain eye contact",
  "Google Slides sync",
  "Invisible on screen share",
  "Mirror Check (with effects)",
  "Polaroid photo",
  "Prompt My Notch",
];

export const moodyHero = {
  eyebrow: "Teleprompter for Mac · Notch",
  headline: hero.headline,
  subhead:
    "Your speaker notes. Right next to your camera. Invisible to everyone but you.",
  cta: "Download for Mac",
  ctaNote: hero.ctaNote,
  systemReq: hero.systemReq,
};

export const moodySteps = steps.map((s) => ({
  number: s.step,
  title: s.title,
  body: s.body,
}));

export type MoodyFeature = {
  id: string;
  title: string;
  description: string;
  image?: string;
  imageAlt?: string;
  extra?: boolean;
};

/** Mapped to Moody's feature grid — our real features first */
export const moodyFeatures: MoodyFeature[] = [
  {
    id: "scroll",
    title: "Auto-scroll at your pace",
    description:
      "Set scroll speed from 10–200 px/s. Hover to pause instantly. Drag to scroll manually anytime.",
    extra: false,
  },
  {
    id: "hidden",
    title: "Discreet to others",
    description:
      "When screen sharing, only you can see the prompter. Zoom, Meet, Teams, OBS — your audience never sees your notes.",
    extra: false,
  },
  {
    id: "notch",
    title: "Positioned at your camera",
    description:
      "Speaker notes clip to the MacBook notch — right below your webcam. Better eye contact, more natural delivery.",
    image: "/screenshots/mirror-check.png",
    imageAlt: "Prompt My Notch at the MacBook notch",
    extra: false,
  },
  {
    id: "import",
    title: "Import from Slides & Keynote",
    description:
      "Paste a Google Slides URL, open a Keynote .key file, or import PowerPoint. No copy-paste slide by slide.",
    extra: false,
  },
  {
    id: "pause",
    title: "Pause on hover",
    description:
      "Hover over the prompter to instantly pause or resume. Drag to scroll manually anytime.",
    extra: false,
  },
  {
    id: "pace",
    title: "Control the pace",
    description:
      "Auto-scroll at 10–200 px/s, or use ⌘↑ / ⌘↓ to adjust speed on the fly during your presentation.",
    extra: false,
  },
  {
    id: "slides-sync",
    title: "Google Slides sync",
    description:
      "Your browser advances — your notes follow. Two-way sync writes edits back to Slides when you tap Save.",
    extra: true,
  },
  {
    id: "camera",
    title: "Camera mirror",
    description:
      "A quick camera check from the prompter toolbar. Circle or rectangle, mirrored, snapped to a corner.",
    image: "/screenshots/mirror-check.png",
    imageAlt: "Camera mirror at the notch",
    extra: true,
  },
  {
    id: "polaroid",
    title: "Polaroid capture",
    description:
      "Freeze a frame, eject a Polaroid card, add a caption and emoji stickers. Saves as PNG to your screenshots folder.",
    image: "/screenshots/polaroid-capture.png",
    imageAlt: "Polaroid capture with caption",
    extra: true,
  },
  {
    id: "edit",
    title: "Edit in place",
    description:
      "Fix a line without stopping the show. Double-click a word for ALL CAPS emphasis. Snippet buttons for --PAUSE--.",
    extra: true,
  },
  {
    id: "privacy",
    title: "Your content stays private",
    description: privacy.lead,
    extra: true,
  },
  {
    id: "menubar",
    title: "Menu bar control",
    description:
      "Start or stop presenting, open the editor, and see your current script — all from the menu bar extra.",
    extra: true,
  },
];

export const moodyAudience = [
  {
    title: "Coaches & Educators",
    body: "Courses, webinars, coaching calls. Stay on point without reading from notes.",
  },
  {
    title: "SaaS Founders",
    body: "Product demos, investor pitches, all-hands. Communicate clearly to every audience.",
  },
  {
    title: "Remote Workers",
    body: "Daily standups, client calls, recorded updates. Look at the camera, not a second monitor.",
  },
  {
    title: "Content Creators",
    body: "YouTube, podcasts, social video. Your face is your product — nail every take.",
  },
  {
    title: "Consultants & Trainers",
    body: "Workshops, strategic presentations, media training. Deliver with authority.",
  },
  {
    title: "Anyone on camera",
    body: "If you present on Zoom, Meet, or Teams and wish your notes were invisible — this is for you.",
  },
];

export { download, faqs, privacy };
