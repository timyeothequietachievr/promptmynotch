import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { termsOfService } from "@/lib/legal-content";

export const metadata: Metadata = {
  title: "Terms of Service — Prompt My Notch",
  description: "Terms of Service for the Prompt My Notch website and macOS app.",
};

export default function TermsOfServicePage() {
  return (
    <main>
      <LegalDocument
        title={termsOfService.title}
        sections={termsOfService.sections}
      />
    </main>
  );
}
