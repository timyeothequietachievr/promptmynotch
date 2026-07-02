import { trackGaEvent } from "@/lib/gtag";
import posthog from "posthog-js";

export type CtaLocation =
  | "hero"
  | "download_section"
  | "moody_hero_scroll"
  | "moody_download"
  | "moody_features"
  | "footer_legal";

export type CtaAction = "checkout" | "scroll" | "toggle" | "navigate";

export type CtaClickProps = {
  ctaId: string;
  ctaLabel: string;
  ctaLocation: CtaLocation;
  ctaAction: CtaAction;
  destinationHref?: string;
  extra?: Record<string, string | number | boolean>;
};

function isPostHogReady(): boolean {
  return (
    typeof window !== "undefined" &&
    Boolean(process.env.NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN) &&
    posthog.__loaded
  );
}

function buildCtaPayload({
  ctaId,
  ctaLabel,
  ctaLocation,
  ctaAction,
  destinationHref,
  extra,
}: CtaClickProps) {
  return {
    cta_id: ctaId,
    cta_label: ctaLabel,
    cta_location: ctaLocation,
    cta_action: ctaAction,
    destination_href: destinationHref,
    page_path: window.location.pathname,
    page_url: window.location.href,
    ...extra,
  };
}

export function trackCtaClick(props: CtaClickProps): void {
  if (typeof window === "undefined") return;

  const payload = buildCtaPayload(props);

  if (isPostHogReady()) {
    posthog.capture("cta_clicked", payload);
  }

  trackGaEvent("cta_clicked", payload);
}
