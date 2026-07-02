export type BlogPost = {
  slug: string;
  title: string;
  description: string;
  publishedAt: string;
  readTime: string;
  tags: string[];
  content: string[];
};

export const blogPosts: BlogPost[] = [
  {
    slug: "eye-contact-remote-meetings-interviews",
    title: "Eye Contact in Remote Meetings and Interviews: How to Build Rapport",
    description:
      "Learn practical eye-contact tactics for Zoom interviews and virtual meetings so you look confident, build connection, and stop glancing away from the camera.",
    publishedAt: "2026-07-02",
    readTime: "6 min read",
    tags: ["interviews", "remote meetings", "eye contact"],
    content: [
      "If you present on camera, eye contact is one of the fastest ways to build trust. In remote interviews and meetings, though, eye contact feels awkward because the person’s face and your webcam are in different places.",
      "The key shift is simple: for important moments, look at the camera lens, not the video tile. Your audience experiences that as direct eye contact.",
      "Use this practical pattern in virtual calls:",
      "- Keep interviewer video tiles near the top of your screen, close to your camera.",
      "- Put speaking notes directly under the camera so your glance-down distance stays short.",
      "- When answering key points, return your gaze to the lens.",
      "- Avoid staring at one spot for too long; use natural gaze changes while thinking.",
      "In in-person panels, the same principle applies differently. Rotate your gaze between interviewers so everyone feels included, then settle briefly on the person who asked the question.",
      "Smiling also matters more than people expect. You don’t need a permanent grin, but a warm expression at the start, transitions, and close of each answer makes you more approachable and memorable.",
      "A quick pre-call checklist:",
      "- Open your notes before the call starts.",
      "- Resize windows so camera, notes, and participant tiles sit near each other.",
      "- Test one answer while recording yourself.",
      "- Check whether your eyes drift to lower corners; if yes, move notes upward.",
      "Eye contact is not about perfection. It is about reducing long gaze breaks. Small positioning changes can make you sound calmer and look more confident in every remote conversation.",
    ],
  },
  {
    slug: "how-to-prepare-a-script-that-sounds-natural",
    title: "How to Prepare a Script That Sounds Natural (Not Robotic)",
    description:
      "Use a simple scripting method with pause markers and emphasis cues so you remember your points and still sound like yourself.",
    publishedAt: "2026-07-02",
    readTime: "7 min read",
    tags: ["public speaking", "scripting", "presentation skills"],
    content: [
      "A good script should guide you, not trap you. The goal is to remember your message while sounding natural.",
      "Start with structure before wording:",
      "- Opening: who you are and why this matters.",
      "- Core points: 3 key ideas in logical order.",
      "- Close: one clear takeaway or call-to-action.",
      "Then add delivery cues directly into your script. These cues make a huge difference under pressure.",
      "Use these markup patterns:",
      "- `---PAUSE---` where you want deliberate silence.",
      "- `ALL CAPS` for words that need emphasis.",
      "- Short lines for breath control.",
      "- Optional notes in brackets, e.g. `[slow down]`.",
      "Example:",
      "\"Today I want to share THREE lessons from launching Prompt My Notch. ---PAUSE---\nThe first lesson is SIMPLE: clarity beats complexity.\"",
      "Why this works:",
      "- Pause markers force rhythm and reduce rushing.",
      "- Emphasis words stop monotone delivery.",
      "- Short lines reduce mouthful sentences and filler words.",
      "Script editing checklist:",
      "- Remove long, formal sentences you would never say out loud.",
      "- Replace jargon with plain language.",
      "- Keep one idea per sentence.",
      "- Read it aloud once and cut anything that sounds unnatural.",
      "Practice routine (10 minutes):",
      "- Run 1: read slowly and over-enunciate.",
      "- Run 2: keep meaning, vary speed for contrast.",
      "- Run 3: speak from cues, not full sentence memory.",
      "A script is not cheating. It is preparation. With clear structure and smart cues, you can sound conversational while staying on message.",
    ],
  },
  {
    slug: "interview-phrases-to-avoid-and-what-to-say-instead",
    title: "Interview Phrases to Avoid (and What to Say Instead)",
    description:
      "A practical interview reminder list: what not to say under pressure, plus better alternatives and story prompts so you stay clear and credible.",
    publishedAt: "2026-07-02",
    readTime: "8 min read",
    tags: ["interviews", "communication", "career"],
    content: [
      "Interviews are high-pressure. Most people do not fail because of technical gaps, but because their communication gets messy when they are put on the spot.",
      "Here are common phrases to avoid and what to say instead.",
      "Avoid: \"Umm… I don’t know.\"\nSay: \"Great question. Let me think for a second.\"",
      "Avoid: \"I’m bad at this.\"\nSay: \"I’m improving this area by doing X and Y.\"",
      "Avoid: \"My last salary was…\" (too early)\nSay: \"I’d like to understand the role scope and your salary range first.\"",
      "Avoid: \"I can do everything.\"\nSay: \"My strongest fit is A and B, and I can support C with onboarding.\"",
      "Avoid: rambling without a point.\nSay: use a short story structure: context -> action -> result -> learning.",
      "If your mind blanks, buy time professionally:",
      "- Ask for rephrasing: \"Could you rephrase that part?\"",
      "- Repeat the question in your own words.",
      "- Take notes while they speak to create a response anchor.",
      "- Defer when needed: \"I want to give a thoughtful answer. Can we return to this after the next question?\"",
      "Prepare these story prompts before the interview:",
      "- A project you led end-to-end.",
      "- A conflict you resolved with stakeholders.",
      "- A mistake you made and what changed after.",
      "- A moment you influenced without authority.",
      "Also prepare 5-8 questions for the interviewer, then prioritize the top three.",
      "Strong examples:",
      "- \"What does success look like in the first 90 days?\"",
      "- \"What are the biggest challenges this team is solving now?\"",
      "- \"How do product, design, and engineering collaborate here?\"",
      "Your goal is not to sound perfect. Your goal is to sound clear, intentional, and prepared. A shortlist of better phrases can instantly lift interview quality.",
    ],
  },
];

export const blogPostsBySlug = Object.fromEntries(
  blogPosts.map((post) => [post.slug, post]),
) as Record<string, BlogPost>;
