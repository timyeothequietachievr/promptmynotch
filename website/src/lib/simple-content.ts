/**
 * Simple (beta) — content synced from TQA Ember (`content.ts`).
 * Only the modules still shown on /simple are included here.
 */
import {
  download,
  faqs,
  featureBlocks,
  hero,
  intro,
  type FeatureBlockContent,
} from "./content";

/** Feature modules kept on the Simple (beta) landing page */
export const simpleFeatureIds = [
  "slides-sync",
  "camera",
  "polaroid",
  "emoji",
  "edit",
] as const;

export type SimpleFeatureId = (typeof simpleFeatureIds)[number];

export const simpleHero = hero;
export const simpleIntro = intro;
export const simpleDownload = download;
export const simpleFaqs = faqs;

export const simpleFeatureBlocks: FeatureBlockContent[] = simpleFeatureIds
  .map((id) => featureBlocks.find((block) => block.id === id))
  .filter((block): block is FeatureBlockContent => block !== undefined);
