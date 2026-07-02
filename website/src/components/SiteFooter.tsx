import { TrackedNavLink } from "@/components/TrackedNavLink";
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
        <TrackedNavLink
          href="/blog"
          className="underline-offset-4 hover:underline"
          style={{ color: scheme.text }}
          ctaId="blog"
          ctaLabel="Blog"
        >
          Blog
        </TrackedNavLink>
        <TrackedNavLink
          href="/privacy-policy"
          className="underline-offset-4 hover:underline"
          style={{ color: scheme.text }}
          ctaId="privacy_policy"
          ctaLabel="Privacy Policy"
        >
          Privacy Policy
        </TrackedNavLink>
        <TrackedNavLink
          href="/terms-of-service"
          className="underline-offset-4 hover:underline"
          style={{ color: scheme.text }}
          ctaId="terms_of_service"
          ctaLabel="Terms of Service"
        >
          Terms of Service
        </TrackedNavLink>
      </nav>
    </footer>
  );
}
