import type { Metadata } from "next";
import { LandingPage } from "@/components/LandingPage";
import { simpleLandingVariant } from "@/lib/landing-variants";

export const metadata: Metadata = {
  title: "Prompt My Notch — Never forget your lines again",
  description:
    "A teleprompter that stays invisible on screen share. Google Slides sync, camera mirror, and more. macOS public beta.",
};

export default function Home() {
  return (
    <main>
      <LandingPage variant={simpleLandingVariant} />
    </main>
  );
}
