import Image from "next/image";
import { Faq } from "@/components/Faq";
import { FeatureBlock } from "@/components/FeatureBlock";
import { SiteFooter } from "@/components/SiteFooter";
import { TqaNotchHero } from "@/components/TqaNotchHero";
import { Button, Container, Eyebrow } from "@/components/ds/primitives";
import {
  emberLandingContent,
  privacy,
  simpleLandingContent,
  steps,
} from "@/lib/landing-content";
import {
  defaultLandingVariant,
  type LandingVariantConfig,
} from "@/lib/landing-variants";
import { siteTheme } from "@/lib/themes";

type LandingPageProps = {
  variant?: LandingVariantConfig;
};

export function LandingPage({ variant = defaultLandingVariant }: LandingPageProps) {
  const scheme = siteTheme;
  const content =
    variant.id === "simple" ? simpleLandingContent : emberLandingContent;

  return (
    <div
      style={
        {
          background: scheme.pageBg,
          color: scheme.text,
          "--shot-bg": scheme.cardBg,
          "--shot-border": scheme.cardBorder,
          "--shot-caption": scheme.textMuted,
        } as React.CSSProperties
      }
    >
      {/* Hero — Moody scrolling notch + TQA copy */}
      <TqaNotchHero scheme={scheme} hero={content.hero} />

      {/* What is this / Yeah but why — Hand Mirror tone */}
      <section style={{ background: scheme.sectionAltBg }} className="py-14 sm:py-16">
        <Container>
          <div className="mx-auto max-w-2xl">
            <h2
              className="font-display text-2xl font-bold"
              style={{ color: scheme.heading }}
            >
              {content.intro.question}
            </h2>
            <p
              className="mt-4 font-reading text-lg leading-relaxed"
              style={{ color: scheme.text }}
            >
              {content.intro.answer}
            </p>
            <h3
              className="mt-10 font-display text-xl font-bold"
              style={{ color: scheme.accent }}
            >
              {content.intro.why}
            </h3>
            <p
              className="mt-3 font-reading text-[15px] leading-relaxed"
              style={{ color: scheme.textMuted }}
            >
              {content.intro.whyAnswer}
            </p>
          </div>
        </Container>
      </section>

      {variant.showSteps ? (
        <section className="py-14 sm:py-16">
          <Container>
            <div className="mb-10 text-center">
              <h2
                className="font-display text-3xl font-bold sm:text-4xl"
                style={{ color: scheme.heading }}
              >
                Ready in 30 seconds
              </h2>
              <p
                className="mt-3 font-reading text-lg"
                style={{ color: scheme.textMuted }}
              >
                No learning curve. Import, present, stay hidden.
              </p>
            </div>
            <div className="grid gap-6 md:grid-cols-3">
              {steps.map((s) => (
                <div
                  key={s.step}
                  className="rounded-xl p-7"
                  style={{
                    background: scheme.cardBg,
                    border: `1px solid ${scheme.cardBorder}`,
                  }}
                >
                  <span
                    className="mb-4 inline-flex h-9 w-9 items-center justify-center rounded-full font-sans text-sm font-bold"
                    style={{
                      background: scheme.accentSoft,
                      color: scheme.accent,
                    }}
                  >
                    {s.step}
                  </span>
                  <h3
                    className="font-display text-xl font-bold"
                    style={{ color: scheme.heading }}
                  >
                    {s.title}
                  </h3>
                  <p
                    className="mt-3 font-reading text-[15px] leading-relaxed"
                    style={{ color: scheme.textMuted }}
                  >
                    {s.body}
                  </p>
                </div>
              ))}
            </div>
          </Container>
        </section>
      ) : null}

      {/* One block per feature */}
      {content.featureBlocks.map((block, i) => (
        <FeatureBlock
          key={block.id}
          block={block}
          scheme={scheme}
          altBg={i % 2 === 0}
        />
      ))}

      {variant.showPrivacy ? (
        <section style={{ background: scheme.sectionAltBg }} className="py-14 sm:py-16">
          <Container>
            <div className="mx-auto max-w-2xl text-center">
              <div className="text-center">
                <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
                  Privacy
                </Eyebrow>
              </div>
              <h2
                className="font-display text-2xl font-bold sm:text-3xl"
                style={{ color: scheme.heading }}
              >
                {privacy.title}
              </h2>
              <p
                className="mt-4 font-reading text-lg leading-relaxed"
                style={{ color: scheme.textMuted }}
              >
                {privacy.lead}
              </p>
            </div>
            <ul className="mx-auto mt-10 grid max-w-3xl gap-3 sm:grid-cols-2">
              {privacy.points.map((point) => (
                <li
                  key={point}
                  className="rounded-lg px-4 py-3 font-reading text-[15px] leading-relaxed"
                  style={{
                    background: scheme.cardBg,
                    border: `1px solid ${scheme.cardBorder}`,
                    color: scheme.text,
                  }}
                >
                  {point}
                </li>
              ))}
            </ul>
          </Container>
        </section>
      ) : null}

      {/* FAQ */}
      <section className="py-14 sm:py-16">
        <Container>
          <h2
            className="mb-8 text-center font-display text-2xl font-bold sm:text-3xl"
            style={{ color: scheme.heading }}
          >
            Frequently asked questions
          </h2>
          <div className="mx-auto max-w-2xl">
            <Faq
              faqs={content.faqs}
              textColor={scheme.heading}
              mutedColor={scheme.textMuted}
              borderColor={scheme.cardBorder}
            />
          </div>
        </Container>
      </section>

      {/* Download */}
      <section id="download" className="py-16 sm:py-20">
        <Container>
          <div className="mx-auto max-w-xl text-center">
            <div className="mb-6 flex justify-center">
              <Image
                src="/app-icon.png"
                alt="Prompt My Notch"
                width={72}
                height={72}
                className="rounded-2xl shadow-lg"
              />
            </div>
            <h2
              className="font-display text-3xl font-bold sm:text-4xl"
              style={{ color: scheme.heading }}
            >
              {content.download.title}
            </h2>
            <p
              className="mt-4 font-reading text-lg"
              style={{ color: scheme.textMuted }}
            >
              {content.download.lead}
            </p>
            <div className="mt-8">
              <Button
                href={content.download.macDownloadUrl}
                variant={scheme.primaryButton}
                size="lg"
              >
                Download for Mac
              </Button>
            </div>
          </div>
        </Container>
      </section>

      <SiteFooter />
    </div>
  );
}
