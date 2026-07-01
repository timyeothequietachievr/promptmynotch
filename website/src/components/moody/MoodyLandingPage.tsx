"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import "@/styles/moody.css";
import { NotchHeader } from "@/components/moody/NotchHeader";
import {
  download,
  faqs,
  moodyAudience,
  moodyFeatures,
  moodyHero,
  moodySteps,
  privacy,
} from "@/lib/moody-content";

function AppleIcon() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.09997 22C7.78997 22.05 6.79997 20.68 5.95997 19.47C4.24997 17 2.93997 12.45 4.69997 9.39C5.56997 7.87 7.12997 6.91 8.81997 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z" />
    </svg>
  );
}

function MoodyFaq() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <div className="mx-auto max-w-3xl text-left">
      {faqs.map((item, i) => {
        const isOpen = openIndex === i;
        return (
          <div key={item.q} className="moody-divider border-t first:border-t-0">
            <button
              type="button"
              className="flex w-full items-center justify-between py-6 text-left md:py-8"
              onClick={() => setOpenIndex(isOpen ? null : i)}
              aria-expanded={isOpen}
            >
              <h3 className="moody-heading pr-8 text-xl font-bold leading-tight md:text-2xl">
                {item.q}
              </h3>
              <svg
                className="h-6 w-6 shrink-0 transition-transform duration-300"
                style={{ transform: isOpen ? "rotate(180deg)" : "rotate(0deg)" }}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
            <div
              className="overflow-hidden transition-all duration-300"
              style={{ maxHeight: isOpen ? 400 : 0 }}
            >
              <p className="moody-lead pb-6 text-base leading-relaxed md:pb-8 md:pr-12">{item.a}</p>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function FeatureCard({
  title,
  description,
  image,
  imageAlt,
}: {
  title: string;
  description: string;
  image?: string;
  imageAlt?: string;
}) {
  return (
    <div className="moody-divider border-t p-6 text-left md:p-8">
      <div className="feature-image-container mb-6">
        {image ? (
          <Image
            src={image}
            alt={imageAlt ?? title}
            width={800}
            height={800}
            className="aspect-square w-full object-cover"
          />
        ) : (
          <div className="feature-placeholder" aria-hidden>
            ✦
          </div>
        )}
      </div>
      <h3 className="moody-heading mb-3 text-xl font-bold leading-tight md:text-2xl">{title}</h3>
      <p className="moody-lead text-sm leading-snug md:text-base">{description}</p>
    </div>
  );
}

export function MoodyLandingPage() {
  const [showAllFeatures, setShowAllFeatures] = useState(false);
  const siteRef = useRef<HTMLDivElement>(null);
  const primaryFeatures = moodyFeatures.filter((f) => !f.extra);
  const extraFeatures = moodyFeatures.filter((f) => f.extra);
  const visibleFeatures = showAllFeatures
    ? moodyFeatures
    : primaryFeatures;

  useEffect(() => {
    const el = siteRef.current;
    if (!el) return;
    el.classList.add("ready");
    return () => el.classList.remove("ready");
  }, []);

  return (
    <div
      ref={siteRef}
      className="moody-site relative min-h-screen pb-6 font-sans antialiased"
    >
      <NotchHeader />

      <main className="relative z-10">
        {/* Hero — black stage */}
        <div className="top-stage w-full pb-16" id="hero-stage">
          <div className="relative z-10 mx-auto flex w-full max-w-[1600px] flex-col items-center px-4 md:px-6">
            <div className="mt-[-32px] flex flex-col items-center gap-6 pt-24 md:pt-52">
              <span
                className="moody-eyebrow -mt-24 mb-2 inline-block rounded-full border px-3 py-1.5 text-[10pt] font-medium uppercase tracking-widest"
                style={{ animation: "moody-slide-up 0.5s ease-out 0.2s forwards", opacity: 0 }}
              >
                {moodyHero.eyebrow}
              </span>

              <h1 className="moody-hero-title text-[3rem] font-bold leading-[1.1] md:text-[4.5rem]">
                {moodyHero.headline}
              </h1>

              <h2
                className="moody-hero-sub max-w-[800px] px-0 text-xl font-normal md:px-12"
                style={{ animation: "moody-slide-up 0.5s ease-out 0.4s forwards", opacity: 0 }}
              >
                {moodyHero.subhead.split(". ").map((part, i, arr) => (
                  <span key={part}>
                    {part}
                    {i < arr.length - 1 ? ". " : ""}
                    {i === 0 ? <br className="desktop-br" /> : null}
                  </span>
                ))}
              </h2>

              <div
                className="mt-8 flex flex-col items-center gap-6"
                style={{ animation: "moody-slide-up 0.5s ease-out 0.55s forwards", opacity: 0 }}
              >
                <a href="#download" className="glass-cta">
                  <AppleIcon />
                  <span>{moodyHero.cta}</span>
                </a>
                <p className="moody-hero-sub text-sm">{moodyHero.ctaNote}</p>
                <p className="-mt-2 text-xs text-[rgba(245,240,211,0.55)]">{moodyHero.systemReq}</p>
              </div>
            </div>

            <div className="mx-auto mt-16 max-w-4xl px-4">
              <Image
                src="/screenshots/camera-mirror.png"
                alt="Prompt My Notch present mode at the MacBook notch"
                width={1400}
                height={900}
                className="moody-screenshot w-full"
                priority
              />
            </div>
          </div>
        </div>

        {/* How it works */}
        <section
          className="light-stage section-gap w-full px-4 md:px-6"
          id="how-it-works"
        >
          <div className="mx-auto max-w-5xl">
            <h2 className="moody-heading mb-4 text-[clamp(2rem,4vw,3.5rem)] font-bold leading-tight">
              Ready in under a minute
            </h2>
            <p className="moody-lead mb-12 text-lg">Three steps. That&apos;s it.</p>
            <div className="grid gap-6 md:grid-cols-3">
              {moodySteps.map((step) => (
                <div
                  key={step.number}
                  className="moody-card rounded-2xl p-8 text-left"
                >
                  <div className="moody-step-num mb-4 flex h-10 w-10 items-center justify-center rounded-full text-lg font-bold">
                    {step.number}
                  </div>
                  <h3 className="moody-heading mb-3 text-xl font-bold">{step.title}</h3>
                  <p className="moody-lead text-base leading-relaxed">{step.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Features grid */}
        <section className="light-stage w-full px-4 md:px-6">
          <div className="mx-auto max-w-6xl">
            <h2 className="moody-heading mb-6 text-[clamp(2rem,4vw,3.5rem)] font-bold leading-tight">
              Everything you need to never lose your place again
            </h2>
            <p className="moody-lead mx-auto mb-12 max-w-3xl text-lg leading-relaxed">
              Prompt My Notch helps you deliver presentations smoothly and confidently. Your script
              stays visible right at your camera — eye contact with your audience, never losing your
              place.
            </p>

            <div className="grid md:grid-cols-2 lg:grid-cols-3">
              {visibleFeatures.map((feature) => (
                <FeatureCard
                  key={feature.id}
                  title={feature.title}
                  description={feature.description}
                  image={feature.image}
                  imageAlt={feature.imageAlt}
                />
              ))}
            </div>

            {extraFeatures.length > 0 ? (
              <button
                type="button"
                className="moody-link-toggle moody-divider flex w-full cursor-pointer items-center justify-center gap-2 border-t py-6 text-sm font-semibold transition-colors md:py-8 md:text-base"
                onClick={() => setShowAllFeatures((v) => !v)}
              >
                <span>{showAllFeatures ? "Show less" : "See all features"}</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  style={{
                    transition: "transform 0.3s",
                    transform: showAllFeatures ? "rotate(180deg)" : "rotate(0deg)",
                  }}
                  aria-hidden
                >
                  <polyline points="6 9 12 15 18 9" />
                </svg>
              </button>
            ) : null}
          </div>
        </section>

        {/* Who it's for */}
        <section className="light-stage section-gap w-full px-4 md:px-6">
          <div className="mx-auto max-w-6xl">
            <h2 className="moody-heading mb-12 text-[clamp(2rem,4vw,3rem)] font-bold">
              Built for people who speak on camera
            </h2>
            <div className="who-uses-grid grid gap-0 md:grid-cols-2">
              {moodyAudience.map((item) => (
                <div
                  key={item.title}
                  className="moody-divider border-b p-8 text-left md:p-10"
                >
                  <h3 className="moody-heading mb-3 text-xl font-bold">{item.title}</h3>
                  <p className="moody-lead text-base leading-relaxed">{item.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Privacy */}
        <section className="light-stage w-full px-4 md:px-6">
          <div className="moody-card mx-auto max-w-3xl rounded-3xl p-10 text-left md:p-14">
            <h2 className="moody-heading mb-4 text-3xl font-bold">{privacy.title}</h2>
            <p className="moody-lead mb-6 text-lg">{privacy.lead}</p>
            <ul className="moody-lead space-y-3 text-base">
              {privacy.points.map((point) => (
                <li key={point} className="flex gap-2">
                  <span className="moody-check">✓</span>
                  <span>{point}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Download CTA */}
        <section className="top-stage section-gap w-full px-4 pb-20 pt-16 md:px-6" id="download">
          <div className="mx-auto flex max-w-2xl flex-col items-center">
            <h2 className="moody-hero-title mb-4 text-[clamp(2rem,4vw,3rem)] font-bold">
              {download.title}
            </h2>
            <p className="moody-hero-sub mb-8 text-lg">{download.lead}</p>
            <button type="button" className="glass-cta">
              <AppleIcon />
              <span>Download for Mac</span>
            </button>
            <p className="moody-hero-sub mt-6 text-sm opacity-80">{download.note}</p>
          </div>
        </section>

        {/* FAQ */}
        <section className="light-stage section-gap w-full px-4 md:px-6">
          <div className="mx-auto max-w-3xl">
            <h2 className="moody-heading mb-10 text-[clamp(2rem,4vw,3rem)] font-bold">
              Questions
            </h2>
            <MoodyFaq />
          </div>
        </section>
      </main>

      <footer className="moody-footer relative z-10 px-4 py-8 text-sm">
        <p>Prompt My Notch</p>
        <nav className="mt-3 flex flex-wrap items-center justify-center gap-x-4 gap-y-2">
          <a href="/privacy-policy" className="hover:underline">
            Privacy Policy
          </a>
          <a href="/terms-of-service" className="hover:underline">
            Terms of Service
          </a>
        </nav>
      </footer>
    </div>
  );
}
