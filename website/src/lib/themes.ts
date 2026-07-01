import type { ButtonVariant } from "@/components/ds/primitives";

export type ColorScheme = {
  id: string;
  label: string;
  description: string;
  pageBg: string;
  sectionAltBg: string;
  text: string;
  textMuted: string;
  heading: string;
  cardBg: string;
  cardBorder: string;
  accent: string;
  accentSoft: string;
  eyebrowTone: "ink" | "ember" | "cream" | "sunrise";
  primaryButton: ButtonVariant;
  secondaryButton: ButtonVariant;
};

/** Ember Deep + Sunrise Soft — production site theme */
export const siteTheme: ColorScheme = {
  id: "ember-deep-sunrise",
  label: "Ember Deep + Sunrise Soft",
  description: "Rich ember panel with golden highlight",
  pageBg: "#8A2A1C",
  sectionAltBg: "#6B2116",
  text: "#F5F0D3",
  textMuted: "rgba(245, 240, 211, 0.78)",
  heading: "#F5F0D3",
  cardBg: "rgba(0, 0, 0, 0.18)",
  cardBorder: "rgba(245, 200, 75, 0.22)",
  accent: "#F5C84B",
  accentSoft: "rgba(245, 200, 75, 0.18)",
  eyebrowTone: "cream",
  primaryButton: "cream",
  secondaryButton: "ghost",
};
