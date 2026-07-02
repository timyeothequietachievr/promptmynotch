export const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

type GtagCommand = "config" | "event" | "js" | "set";

declare global {
  interface Window {
    gtag?: (command: GtagCommand, ...args: unknown[]) => void;
  }
}

export function isGoogleAnalyticsReady(): boolean {
  return (
    typeof window !== "undefined" &&
    typeof window.gtag === "function" &&
    Boolean(GA_MEASUREMENT_ID)
  );
}

export function trackGaPageView(pathname: string, search = ""): void {
  if (!isGoogleAnalyticsReady() || !GA_MEASUREMENT_ID) return;

  const pagePath = search ? `${pathname}?${search}` : pathname;

  window.gtag!("config", GA_MEASUREMENT_ID, {
    page_path: pagePath,
  });
}

export function trackGaEvent(
  eventName: string,
  params: Record<string, string | number | boolean | undefined>,
): void {
  if (!isGoogleAnalyticsReady()) return;
  window.gtag!("event", eventName, params);
}
