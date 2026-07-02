"use client";

import { Button, type ButtonVariant } from "@/components/ds/primitives";
import type { CtaLocation } from "@/lib/analytics";
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

  if (checkoutUrl) {
    return (
      <Button
        href={checkoutUrl}
        variant={variant}
        size={size}
        className={className}
        target="_blank"
        rel="noopener noreferrer"
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
    >
      {CTA_LABEL}
    </Button>
  );
}
