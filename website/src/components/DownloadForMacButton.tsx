"use client";

import { Button, type ButtonVariant } from "@/components/ds/primitives";
import { trackCtaClick, type CtaLocation } from "@/lib/analytics";
import { getPayhipCheckoutUrl } from "@/lib/payhip-checkout";

const CTA_LABEL = "Download for Mac";

type DownloadForMacButtonProps = {
  variant?: ButtonVariant;
  size?: "sm" | "md" | "lg";
  className?: string;
  ctaLocation: CtaLocation;
};

export function DownloadForMacButton({
  variant = "cream",
  size = "lg",
  className = "",
  ctaLocation,
}: DownloadForMacButtonProps) {
  const checkoutUrl = getPayhipCheckoutUrl();

  const handleClick = () => {
    trackCtaClick({
      ctaId: "download_mac",
      ctaLabel: CTA_LABEL,
      ctaLocation,
      ctaAction: "checkout",
      destinationHref: checkoutUrl ?? undefined,
    });
  };

  if (checkoutUrl) {
    return (
      <Button
        href={checkoutUrl}
        variant={variant}
        size={size}
        className={className}
        target="_blank"
        rel="noopener noreferrer"
        onClick={handleClick}
      >
        {CTA_LABEL}
      </Button>
    );
  }

  return (
    <Button
      variant={variant}
      size={size}
      className={className}
      onClick={handleClick}
    >
      {CTA_LABEL}
    </Button>
  );
}
