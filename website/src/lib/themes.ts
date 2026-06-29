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
  schemeBannerBg: string;
  schemeBannerText: string;
};

export const colorSchemes: ColorScheme[] = [
  {
    id: "ink-deep-paper",
    label: "Ink Deep + Paper",
    description: "Classic TQA — deep navy with cream type",
    pageBg: "#1A1A3A",
    sectionAltBg: "#2B2B52",
    text: "#F5F0D3",
    textMuted: "rgba(245, 240, 211, 0.72)",
    heading: "#F5F0D3",
    cardBg: "#2B2B52",
    cardBorder: "rgba(245, 240, 211, 0.12)",
    accent: "#F5C84B",
    accentSoft: "rgba(245, 200, 75, 0.15)",
    eyebrowTone: "sunrise",
    primaryButton: "cream",
    secondaryButton: "ghost",
    schemeBannerBg: "#2B2B52",
    schemeBannerText: "#F5C84B",
  },
  {
    id: "paper-ink",
    label: "Paper + Ink",
    description: "Light cream background with ink structure",
    pageBg: "#F5F0D3",
    sectionAltBg: "#FAF6E1",
    text: "#4A4638",
    textMuted: "#8A8572",
    heading: "#1E1E1E",
    cardBg: "#FAF6E1",
    cardBorder: "rgba(43, 43, 82, 0.1)",
    accent: "#D54A2F",
    accentSoft: "rgba(213, 74, 47, 0.1)",
    eyebrowTone: "ember",
    primaryButton: "primary",
    secondaryButton: "secondary",
    schemeBannerBg: "#E8E1BE",
    schemeBannerText: "#2B2B52",
  },
  {
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
    schemeBannerBg: "#6B2116",
    schemeBannerText: "#F5C84B",
  },
];
