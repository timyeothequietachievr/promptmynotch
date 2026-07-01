import type { Metadata } from "next";
import { MoodyLandingPage } from "@/components/moody/MoodyLandingPage";

export const metadata: Metadata = {
  title: "Prompt My Notch — Teleprompter for Mac (Notch)",
  description:
    "Your speaker notes, right next to your camera — invisible to everyone but you. Moody-style layout preview.",
};

export default function MoodyPage() {
  return <MoodyLandingPage />;
}
