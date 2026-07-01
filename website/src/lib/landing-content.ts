import {
  download,
  faqs,
  featureBlocks,
  hero,
  intro,
  privacy,
  steps,
  type FeatureBlockContent,
} from "./content";
import {
  simpleDownload,
  simpleFaqs,
  simpleFeatureBlocks,
  simpleHero,
  simpleIntro,
} from "./simple-content";

export type LandingContent = {
  hero: typeof hero;
  intro: typeof intro;
  download: typeof download;
  faqs: typeof faqs;
  featureBlocks: FeatureBlockContent[];
};

export const emberLandingContent: LandingContent = {
  hero,
  intro,
  download,
  faqs,
  featureBlocks,
};

/** Simple (beta) — hero, intro, FAQ, download, and six feature modules from Ember */
export const simpleLandingContent: LandingContent = {
  hero: simpleHero,
  intro: simpleIntro,
  download: simpleDownload,
  faqs: simpleFaqs,
  featureBlocks: simpleFeatureBlocks,
};

export { steps, privacy };
