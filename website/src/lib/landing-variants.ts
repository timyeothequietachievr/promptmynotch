export type LandingVariantConfig = {
  id: "ember" | "simple";
  codeName: string;
  showSteps: boolean;
  showPrivacy: boolean;
};

export const defaultLandingVariant: LandingVariantConfig = {
  id: "ember",
  codeName: "TQA Ember",
  showSteps: true,
  showPrivacy: true,
};

/** Simple — trimmed module set; keeps Google Slides sync and camera features */
export const simpleLandingVariant: LandingVariantConfig = {
  id: "simple",
  codeName: "Simple",
  showSteps: false,
  showPrivacy: false,
};
