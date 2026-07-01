import Link from "next/link";
import { siteTheme } from "@/lib/themes";

export function SiteFooter() {
  const scheme = siteTheme;

  return (
    <footer
      className="border-t px-5 py-6 text-center font-reading text-sm"
      style={{ borderColor: scheme.cardBorder, color: scheme.textMuted }}
    >
      <p>Prompt My Notch</p>
      <nav className="mt-3 flex flex-wrap items-center justify-center gap-x-4 gap-y-2">
        <Link
          href="/privacy-policy"
          className="underline-offset-4 hover:underline"
          style={{ color: scheme.text }}
        >
          Privacy Policy
        </Link>
        <Link
          href="/terms-of-service"
          className="underline-offset-4 hover:underline"
          style={{ color: scheme.text }}
        >
          Terms of Service
        </Link>
      </nav>
    </footer>
  );
}
