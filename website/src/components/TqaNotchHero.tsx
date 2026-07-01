"use client";

import Image from "next/image";
import { useEffect, useRef } from "react";
import "@/styles/moody.css";
import { Button, Container } from "@/components/ds/primitives";
import { NotchHeader } from "@/components/moody/NotchHeader";
import type { LandingContent } from "@/lib/landing-content";
import { hero as defaultHero } from "@/lib/content";
import type { ColorScheme } from "@/lib/themes";

type HeroContent = typeof defaultHero;

export function TqaNotchHero({
  scheme,
  hero = defaultHero,
}: {
  scheme: ColorScheme;
  hero?: HeroContent;
}) {
  const shellRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = shellRef.current;
    if (!el) return;
    el.classList.add("ready");
    return () => el.classList.remove("ready");
  }, []);

  return (
    <div ref={shellRef} className="moody-site moody-hero-shell relative">
      <NotchHeader />

      <div className="top-stage w-full pb-8 sm:pb-12">
        <Container>
          <div className="mx-auto max-w-3xl pt-28 text-center sm:pt-36 md:pt-44">
            <h1
              className="font-display font-bold"
              style={{
                color: scheme.heading,
                fontSize: "clamp(36px, 5vw, 56px)",
                lineHeight: 1.06,
                letterSpacing: "-0.02em",
              }}
            >
              {hero.headline}
            </h1>
            <div className="mx-auto mt-8 max-w-5xl sm:mt-10">
              <Image
                src="/screenshots/hero-macbook.png"
                alt="Prompt My Notch teleprompter at the MacBook notch with camera mirror"
                width={1600}
                height={1200}
                priority
                className="h-auto w-full"
                sizes="(max-width: 768px) 100vw, 960px"
              />
            </div>
            <p
              className="mx-auto mt-6 max-w-2xl font-reading text-lg leading-relaxed sm:text-xl"
              style={{ color: scheme.textMuted }}
            >
              {hero.subhead}
            </p>
            <div className="mt-8 flex flex-wrap items-center justify-center gap-2">
              {hero.pills.map((pill) => (
                <span
                  key={pill}
                  className="rounded-full px-3.5 py-1.5 font-sans text-sm font-medium"
                  style={{
                    background: scheme.accentSoft,
                    color: scheme.heading,
                    border: `1px solid ${scheme.cardBorder}`,
                  }}
                >
                  {pill}
                </span>
              ))}
            </div>
            <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
              <Button variant={scheme.primaryButton} size="lg">
                Download for Mac
              </Button>
            </div>
            <p
              className="mt-5 font-reading text-sm"
              style={{ color: scheme.textMuted }}
            >
              macOS 14.0 or later
            </p>
          </div>
        </Container>
      </div>
    </div>
  );
}
