import Image from "next/image";
import { AppScreenshot } from "@/components/AppScreenshot";
import { Button, Container, Eyebrow } from "@/components/ds/primitives";
import {
  implementedFeatures,
  privacyPoints,
  requirements,
} from "@/lib/features";
import type { ColorScheme } from "@/lib/themes";

export function LandingVariant({ scheme }: { scheme: ColorScheme }) {
  const isLight = scheme.id === "paper-ink";

  return (
    <div
      className="border-b-4 border-charcoal"
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
      {/* Scheme label */}
      <div
        className="border-b px-5 py-3 text-center font-mono text-[11px] tracking-[0.18em] uppercase sm:px-8"
        style={{
          background: scheme.schemeBannerBg,
          color: scheme.schemeBannerText,
          borderColor: scheme.cardBorder,
        }}
      >
        Colour scheme — {scheme.label} · {scheme.description}
      </div>

      {/* Hero */}
      <section className="py-14 sm:py-20">
        <Container>
          <div className="grid items-start gap-10 lg:grid-cols-[1fr_1.1fr] lg:gap-14">
            <div>
              <Eyebrow tone={scheme.eyebrowTone} className="mb-5">
                NotchPrompter · macOS 14+ · v2.2.0
              </Eyebrow>
              <h1
                className="font-display font-bold"
                style={{
                  color: scheme.heading,
                  fontSize: "clamp(32px, 4vw, 48px)",
                  lineHeight: 1.08,
                  letterSpacing: "-0.02em",
                }}
              >
                Speaker notes at the notch. Invisible to your audience.
              </h1>
              <p
                className="mt-5 max-w-xl font-reading text-lg leading-relaxed"
                style={{ color: scheme.textMuted }}
              >
                Native macOS teleprompter. Import speaker notes from Google
                Slides, Keynote, or PowerPoint. Present with voice-activated
                scrolling and optional camera mirror.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <Button
                  href="#download"
                  variant={scheme.primaryButton}
                  size="lg"
                >
                  Download for Mac
                </Button>
                <Button
                  href={`#features-${scheme.id}`}
                  variant={scheme.secondaryButton}
                  size="lg"
                >
                  Feature list
                </Button>
              </div>
              <p
                className="mt-4 font-reading text-sm"
                style={{ color: scheme.textMuted }}
              >
                Native Swift/SwiftUI · Apple Silicon & Intel
              </p>
            </div>

            <div className="flex flex-col gap-4">
              <AppScreenshot
                src="/screenshots/camera-mirror.png"
                alt="NotchPrompter present mode with camera mirror at the notch"
                caption="App screenshot — present mode, circle camera mirror, toolbar."
                priority={scheme.id === "ink-deep-paper"}
              />
              <div className="flex items-center gap-3">
                <Image
                  src="/app-icon.png"
                  alt="NotchPrompter icon"
                  width={48}
                  height={48}
                  className="rounded-[11px]"
                />
                <p className="font-reading text-sm" style={{ color: scheme.textMuted }}>
                  Scripts stored locally after import
                </p>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Screenshots */}
      <section style={{ background: scheme.sectionAltBg }}>
        <Container className="py-14 sm:py-16">
          <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
            In the app
          </Eyebrow>
          <h2
            className="mb-8 font-display text-2xl font-bold sm:text-3xl"
            style={{ color: scheme.heading }}
          >
            Screenshots from the build
          </h2>
          <div className="grid gap-6 md:grid-cols-2">
            <AppScreenshot
              src="/screenshots/polaroid.png"
              alt="Polaroid capture with caption editing"
              caption="Polaroid capture — caption strip, Save / Cancel."
            />
            <AppScreenshot
              src="/screenshots/emoji-stickers.png"
              alt="Emoji sticker picker"
              caption="Emoji picker — search and category tabs for stickers."
            />
          </div>
        </Container>
      </section>

      {/* Feature list */}
      <section id={`features-${scheme.id}`}>
        <Container className="py-14 sm:py-16">
          <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
            Implemented in v2.2
          </Eyebrow>
          <h2
            className="mb-3 font-display text-2xl font-bold sm:text-3xl"
            style={{ color: scheme.heading }}
          >
            Feature list
          </h2>
          <p
            className="mb-10 max-w-2xl font-reading text-base leading-relaxed"
            style={{ color: scheme.textMuted }}
          >
            Everything below ships in the current app. Sourced from the v2.2
            milestone documentation — no roadmap items.
          </p>

          <div className="grid gap-6 md:grid-cols-2">
            {implementedFeatures.map((group) => (
              <div
                key={group.title}
                className="rounded-xl p-6"
                style={{
                  background: scheme.cardBg,
                  border: `1px solid ${scheme.cardBorder}`,
                }}
              >
                <h3
                  className="mb-4 font-sans text-base font-bold"
                  style={{ color: scheme.accent }}
                >
                  {group.title}
                </h3>
                <ul className="space-y-2.5">
                  {group.items.map((item) => (
                    <li
                      key={item}
                      className="flex gap-2 font-reading text-[15px] leading-relaxed"
                      style={{ color: scheme.text }}
                    >
                      <span style={{ color: scheme.accent }} aria-hidden>
                        ·
                      </span>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </Container>
      </section>

      {/* Privacy & requirements */}
      <section style={{ background: scheme.sectionAltBg }}>
        <Container className="py-14 sm:py-16">
          <div className="grid gap-10 md:grid-cols-2">
            <div>
              <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
                Privacy
              </Eyebrow>
              <h2
                className="mb-4 font-display text-xl font-bold"
                style={{ color: scheme.heading }}
              >
                Local-first
              </h2>
              <ul className="space-y-2.5">
                {privacyPoints.map((point) => (
                  <li
                    key={point}
                    className="font-reading text-[15px] leading-relaxed"
                    style={{ color: scheme.text }}
                  >
                    {point}
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
                Requirements
              </Eyebrow>
              <h2
                className="mb-4 font-display text-xl font-bold"
                style={{ color: scheme.heading }}
              >
                To run NotchPrompter
              </h2>
              <ul className="space-y-2">
                {requirements.map((req) => (
                  <li
                    key={req}
                    className="font-reading text-[15px]"
                    style={{ color: scheme.text }}
                  >
                    {req}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </Container>
      </section>

      {/* Download */}
      <section id={scheme.id === "paper-ink" ? "download" : undefined}>
        <Container className="py-14 text-center sm:py-16">
          <h2
            className="mb-4 font-display text-2xl font-bold sm:text-3xl"
            style={{ color: scheme.heading }}
          >
            Download NotchPrompter 2.2.0
          </h2>
          <p
            className="mx-auto mb-8 max-w-lg font-reading text-base"
            style={{ color: scheme.textMuted }}
          >
            Import. Present. Stay in sync. Stay hidden.
          </p>
          <Button href="#" variant={scheme.primaryButton} size="lg">
            Download for Mac
          </Button>
        </Container>
      </section>

      <footer
        className="border-t px-5 py-6 text-center font-reading text-sm sm:px-8"
        style={{
          borderColor: scheme.cardBorder,
          color: scheme.textMuted,
        }}
      >
        NotchPrompter · {scheme.label}
        {isLight ? "" : " · Inspired by Moody"}
      </footer>
    </div>
  );
}
