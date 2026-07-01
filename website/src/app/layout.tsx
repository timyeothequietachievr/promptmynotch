import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Prompt My Notch — Never forget your lines again",
  description:
    "A teleprompter that stays invisible on screen share. Google Slides sync, camera mirror, and more. macOS public beta.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const isMoodyRoot = process.env.LANDING_VARIANT === "moody";

  return (
    <html lang="en">
      <body className={isMoodyRoot ? "moody-root" : undefined}>{children}</body>
    </html>
  );
}
