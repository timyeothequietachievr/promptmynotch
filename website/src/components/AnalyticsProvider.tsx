"use client";

import { trackGaPageView } from "@/lib/gtag";
import { usePathname, useSearchParams } from "next/navigation";
import posthog from "posthog-js";
import { Suspense, useEffect } from "react";

function AnalyticsPageView() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (!pathname) return;

    const query = searchParams.toString();

    if (posthog.__loaded) {
      let url = window.location.origin + pathname;
      if (query) url += `?${query}`;
      posthog.capture("$pageview", { $current_url: url });
    }

    trackGaPageView(pathname, query);
  }, [pathname, searchParams]);

  return null;
}

export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Suspense fallback={null}>
        <AnalyticsPageView />
      </Suspense>
      {children}
    </>
  );
}
