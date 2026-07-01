import Link from "next/link";
import { Container } from "@/components/ds/primitives";
import { SiteFooter } from "@/components/SiteFooter";
import { legalMeta } from "@/lib/legal-content";
import { siteTheme } from "@/lib/themes";

type LegalSection = {
  heading: string;
  body: string[];
  list?: string[];
};

type LegalDocumentProps = {
  title: string;
  sections: LegalSection[];
};

export function LegalDocument({ title, sections }: LegalDocumentProps) {
  const scheme = siteTheme;

  return (
    <div
      style={{
        background: scheme.pageBg,
        color: scheme.text,
        minHeight: "100vh",
      }}
    >
      <Container className="py-12 sm:py-16">
        <div className="mx-auto max-w-3xl">
          <Link
            href="/"
            className="font-reading text-sm underline-offset-4 hover:underline"
            style={{ color: scheme.textMuted }}
          >
            ← Back to home
          </Link>

          <h1
            className="mt-6 font-display text-3xl font-bold sm:text-4xl"
            style={{ color: scheme.heading }}
          >
            {title}
          </h1>
          <p
            className="mt-3 font-reading text-sm"
            style={{ color: scheme.textMuted }}
          >
            Last updated: {legalMeta.lastUpdated}
          </p>

          <div className="mt-10 space-y-10">
            {sections.map((section) => (
              <section key={section.heading}>
                <h2
                  className="font-display text-xl font-bold"
                  style={{ color: scheme.heading }}
                >
                  {section.heading}
                </h2>
                <div className="mt-3 space-y-3">
                  {section.body.map((paragraph) => (
                    <p
                      key={paragraph}
                      className="font-reading text-[15px] leading-relaxed"
                      style={{ color: scheme.textMuted }}
                    >
                      {paragraph}
                    </p>
                  ))}
                </div>
                {section.list && (
                  <ul className="mt-3 list-disc space-y-2 pl-5">
                    {section.list.map((item) => (
                      <li
                        key={item}
                        className="font-reading text-[15px] leading-relaxed"
                        style={{ color: scheme.textMuted }}
                      >
                        {item}
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            ))}
          </div>

          <p
            className="mt-12 font-reading text-[15px] leading-relaxed"
            style={{ color: scheme.textMuted }}
          >
            Contact:{" "}
            <a
              href={`mailto:${legalMeta.contactEmail}`}
              className="underline-offset-4 hover:underline"
              style={{ color: scheme.text }}
            >
              {legalMeta.contactEmail}
            </a>
          </p>
        </div>
      </Container>

      <SiteFooter />
    </div>
  );
}
