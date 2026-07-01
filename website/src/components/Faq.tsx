"use client";

import { useState } from "react";
import type { LandingContent } from "@/lib/landing-content";

export function Faq({
  faqs,
  textColor,
  mutedColor,
  borderColor,
}: {
  faqs: LandingContent["faqs"];
  textColor: string;
  mutedColor: string;
  borderColor: string;
}) {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <div
      className="overflow-hidden rounded-xl"
      style={{ border: `1px solid ${borderColor}` }}
    >
      {faqs.map((item, i) => (
        <div key={item.q} style={{ borderBottom: i < faqs.length - 1 ? `1px solid ${borderColor}` : undefined }}>
          <button
            type="button"
            onClick={() => setOpen(open === i ? null : i)}
            className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left font-sans text-[15px] font-semibold"
            style={{ color: textColor }}
          >
            {item.q}
            <span className="shrink-0 text-xl font-light opacity-40">
              {open === i ? "−" : "+"}
            </span>
          </button>
          {open === i && (
            <p
              className="px-5 pb-4 font-reading text-[15px] leading-relaxed"
              style={{ color: mutedColor }}
            >
              {item.a}
            </p>
          )}
        </div>
      ))}
    </div>
  );
}
