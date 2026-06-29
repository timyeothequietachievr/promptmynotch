import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NotchPrompter — Colour scheme previews",
  description:
    "NotchPrompter landing page previews using The Quiet Achiever design system.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
