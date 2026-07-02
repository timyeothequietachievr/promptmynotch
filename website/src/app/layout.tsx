import type { Metadata } from "next";
import { AnalyticsProvider } from "@/components/AnalyticsProvider";
import { GoogleAnalytics } from "@/components/GoogleAnalytics";
import "./globals.css";

const googleSiteVerification = process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION?.trim();

export const metadata: Metadata = {
  title: "Prompt My Notch — Never forget your lines again",
  description:
    "A teleprompter that stays invisible on screen share. Google Slides sync, camera mirror, and more.",
  ...(googleSiteVerification
    ? { verification: { google: googleSiteVerification } }
    : {}),
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const isMoodyRoot = process.env.LANDING_VARIANT === "moody";
  const gaMeasurementId = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

  return (
    <html lang="en">
      <body className={isMoodyRoot ? "moody-root" : undefined}>
        {gaMeasurementId ? (
          <GoogleAnalytics measurementId={gaMeasurementId} />
        ) : null}
        <AnalyticsProvider>{children}</AnalyticsProvider>
      </body>
    </html>
  );
}
