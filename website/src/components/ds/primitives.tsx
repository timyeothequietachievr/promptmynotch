"use client";

import type { CSSProperties, MouseEvent, ReactNode } from "react";

export function Container({
  children,
  className = "",
  wide = false,
}: {
  children: ReactNode;
  className?: string;
  wide?: boolean;
}) {
  return (
    <div
      className={`mx-auto px-5 sm:px-8 lg:px-12 ${wide ? "max-w-[1320px]" : "max-w-[1200px]"} ${className}`}
    >
      {children}
    </div>
  );
}

type EyebrowTone = "ink" | "ember" | "cream" | "sunrise";

export function Eyebrow({
  children,
  tone = "ink",
  className = "",
}: {
  children: ReactNode;
  tone?: EyebrowTone;
  className?: string;
}) {
  const color =
    tone === "ember"
      ? "#D54A2F"
      : tone === "cream"
        ? "#F5F0D3"
        : tone === "sunrise"
          ? "#E5A402"
          : "#2B2B52";

  return (
    <div
      className={`font-sans font-bold uppercase ${className}`}
      style={{ letterSpacing: "0.18em", fontSize: "12px", color }}
    >
      {children}
    </div>
  );
}

export type ButtonVariant = "primary" | "secondary" | "ghost" | "cream" | "ink";
type ButtonSize = "sm" | "md" | "lg";

export function Button({
  children,
  variant = "primary",
  size = "md",
  href,
  className = "",
}: {
  children: ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  href?: string;
  className?: string;
}) {
  const base =
    "inline-flex items-center justify-center gap-2 font-sans font-semibold transition-colors";
  const sizes: Record<ButtonSize, string> = {
    sm: "h-9 px-4 text-sm",
    md: "h-11 px-5 text-[15px]",
    lg: "h-12 px-6 text-base",
  };
  const styles: Record<ButtonVariant, CSSProperties> = {
    primary: {
      background: "var(--tqa-ember)",
      color: "#F5F0D3",
      borderRadius: "4px",
    },
    secondary: {
      background: "transparent",
      color: "#1E1E1E",
      border: "1.5px solid #1E1E1E",
      borderRadius: "4px",
    },
    ghost: {
      background: "transparent",
      color: "inherit",
      borderRadius: "4px",
      textDecoration: "underline",
      textUnderlineOffset: "4px",
    },
    cream: { background: "#F5F0D3", color: "#2B2B52", borderRadius: "4px" },
    ink: { background: "#2B2B52", color: "#F5F0D3", borderRadius: "4px" },
  };

  const handleEnter = (e: MouseEvent<HTMLElement>) => {
    const el = e.currentTarget;
    if (variant === "primary") el.style.background = "#8A2A1C";
    if (variant === "secondary") {
      el.style.background = "#1E1E1E";
      el.style.color = "#F5F0D3";
    }
    if (variant === "ink") el.style.background = "#1A1A3A";
    if (variant === "cream") el.style.background = "#FAF6E1";
  };

  const handleLeave = (e: MouseEvent<HTMLElement>) => {
    const el = e.currentTarget;
    if (variant === "primary") el.style.background = "#D54A2F";
    if (variant === "secondary") {
      el.style.background = "transparent";
      el.style.color = "#1E1E1E";
    }
    if (variant === "ink") el.style.background = "#2B2B52";
    if (variant === "cream") el.style.background = "#F5F0D3";
  };

  const classNames = `${base} ${sizes[size]} ${className}`;

  if (href) {
    return (
      <a
        href={href}
        className={classNames}
        style={styles[variant]}
        onMouseEnter={handleEnter}
        onMouseLeave={handleLeave}
      >
        {children}
      </a>
    );
  }

  return (
    <button
      type="button"
      className={classNames}
      style={styles[variant]}
      onMouseEnter={handleEnter}
      onMouseLeave={handleLeave}
    >
      {children}
    </button>
  );
}
