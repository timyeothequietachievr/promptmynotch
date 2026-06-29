import "./globals.css";
import { LandingVariant } from "@/components/LandingVariant";
import { colorSchemes } from "@/lib/themes";

export default function Home() {
  return (
    <main>
      <div className="bg-charcoal px-5 py-4 text-center font-mono text-[11px] tracking-[0.14em] text-paper uppercase sm:px-8">
        NotchPrompter website — 3 colour schemes (TQA design system)
      </div>
      {colorSchemes.map((scheme) => (
        <LandingVariant key={scheme.id} scheme={scheme} />
      ))}
    </main>
  );
}
