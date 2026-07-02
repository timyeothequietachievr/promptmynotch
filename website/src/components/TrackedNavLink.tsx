"use client";

import Link from "next/link";
import { trackCtaClick, type CtaLocation } from "@/lib/analytics";

type TrackedNavLinkProps = {
  href: string;
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  ctaId: string;
  ctaLabel: string;
  ctaLocation?: CtaLocation;
};

export function TrackedNavLink({
  href,
  children,
  className,
  style,
  ctaId,
  ctaLabel,
  ctaLocation = "footer_legal",
}: TrackedNavLinkProps) {
  return (
    <Link
      href={href}
      className={className}
      style={style}
      onClick={() => {
        trackCtaClick({
          ctaId,
          ctaLabel,
          ctaLocation,
          ctaAction: "navigate",
          destinationHref: href,
        });
      }}
    >
      {children}
    </Link>
  );
}
