import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { privacyPolicy } from "@/lib/legal-content";

export const metadata: Metadata = {
  title: "Privacy Policy — Prompt My Notch",
  description: "Privacy Policy for the Prompt My Notch website and macOS app.",
};

export default function PrivacyPolicyPage() {
  return (
    <main>
      <LegalDocument
        title={privacyPolicy.title}
        sections={privacyPolicy.sections}
      />
    </main>
  );
}
