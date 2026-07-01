"use client";

import Image from "next/image";
import { useEffect, useRef } from "react";
import "@/styles/moody.css";
import { Button, Eyebrow } from "@/components/ds/primitives";
import { moodyHero } from "@/lib/moody-content";
import type { ColorScheme } from "@/lib/themes";
import { NotchHeader } from "@/components/moody/NotchHeader";

export function MoodyHero({ scheme }: { scheme: ColorScheme }) {
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

      <div className="top-stage w-full pb-16" id="hero-stage">
        <div className="relative z-10 mx-auto flex w-full max-w-[1600px] flex-col items-center px-4 md:px-6">
          <div className="mt-[-32px] flex flex-col items-center gap-6 pt-24 md:pt-52">
            <div
              className="-mt-24 mb-2"
              style={{ animation: "moody-slide-up 0.5s ease-out 0.2s forwards", opacity: 0 }}
            >
              <Eyebrow tone={scheme.eyebrowTone}>{moodyHero.eyebrow}</Eyebrow>
            </div>

            <h1
              className="font-display text-[3rem] font-bold leading-[1.1] md:text-[4.5rem]"
              style={{ color: scheme.heading, letterSpacing: "-0.02em" }}
            >
              {moodyHero.headline}
            </h1>

            <p
              className="max-w-[800px] px-0 font-reading text-xl leading-relaxed md:px-12"
              style={{
                color: scheme.textMuted,
                animation: "moody-slide-up 0.5s ease-out 0.4s forwards",
                opacity: 0,
              }}
            >
              {moodyHero.subhead.split(". ").map((part, i, arr) => (
                <span key={part}>
                  {part}
                  {i < arr.length - 1 ? ". " : ""}
                  {i === 0 ? <br className="desktop-br" /> : null}
                </span>
              ))}
            </p>

            <div
              className="mt-8 flex flex-col items-center gap-6"
              style={{ animation: "moody-slide-up 0.5s ease-out 0.55s forwards", opacity: 0 }}
            >
              <Button href="#download" variant={scheme.primaryButton} size="lg">
                {moodyHero.cta}
              </Button>
              <p className="font-reading text-sm" style={{ color: scheme.textMuted }}>
                {moodyHero.ctaNote}
              </p>
              <p className="-mt-2 font-reading text-xs opacity-70" style={{ color: scheme.textMuted }}>
                {moodyHero.systemReq}
              </p>
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
    </div>
  );
}
