"use client";

import { useEffect, useRef } from "react";
import { notchScriptLines } from "@/lib/moody-content";

export function NotchHeader() {
  const linesRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const headerRef = useRef<HTMLDivElement>(null);
  const pausedRef = useRef({
    isPaused: false,
    pausedTransform: 0,
    animationDuration: 10,
    scrollHeight: 0,
  });

  useEffect(() => {
    const linesEl = linesRef.current;
    const container = containerRef.current;
    if (!linesEl || !container) return;

    const lines = notchScriptLines;

    const buildGroup = () => {
      const frag = document.createDocumentFragment();
      lines.forEach((text) => {
        const line = document.createElement("div");
        line.textContent = text.trim() ? text : "\u00A0";
        frag.appendChild(line);
      });
      return frag;
    };

    linesEl.innerHTML = "";
    linesEl.appendChild(buildGroup());
    linesEl.appendChild(buildGroup());

    const startAnimation = () => {
      const groupSize = lines.length;
      const first = linesEl.children[0] as HTMLElement | undefined;
      const secondGroupFirst = linesEl.children[groupSize] as HTMLElement | undefined;
      if (!first || !secondGroupFirst) return;

      const distance = Math.round(secondGroupFirst.offsetTop - first.offsetTop);
      const speed = 24;
      const duration = distance / speed;
      linesEl.style.setProperty("--scroll-height", `${distance}px`);
      linesEl.style.setProperty("--scroll-duration", `${duration}s`);
      linesEl.style.animation = "none";
      void linesEl.offsetHeight;
      linesEl.style.transform = "translateY(0px)";
      linesEl.style.animation = `moody-scroll-up ${duration}s linear 0.3s infinite`;
      pausedRef.current.animationDuration = duration;
      pausedRef.current.scrollHeight = distance;
    };

    const fontsReady =
      document.fonts && typeof document.fonts.ready?.then === "function"
        ? document.fonts.ready
        : Promise.resolve();

    fontsReady.then(() => {
      requestAnimationFrame(() => {
        requestAnimationFrame(startAnimation);
      });
    });

    const getCurrentTransform = () => {
      const computed = window.getComputedStyle(linesEl);
      const transform = computed.transform;
      if (transform === "none" || !transform) return 0;
      const match = transform.match(/matrix\(([^)]+)\)/);
      if (match?.[1]) {
        const nums = match[1].split(",").map((v) => parseFloat(v.trim()));
        if (nums.length === 6) return nums[5];
      }
      return 0;
    };

    const onEnter = () => {
      const state = pausedRef.current;
      if (state.isPaused) return;
      const computed = window.getComputedStyle(linesEl);
      const animationName = computed.animationName;
      if (animationName === "none" || !animationName) return;

      state.animationDuration =
        parseFloat(computed.getPropertyValue("--scroll-duration")) || 10;
      state.scrollHeight = parseFloat(computed.getPropertyValue("--scroll-height")) || 0;
      if (state.scrollHeight === 0) {
        linesEl.style.animationPlayState = "paused";
        state.isPaused = true;
        return;
      }

      state.pausedTransform = getCurrentTransform();
      linesEl.style.animation = "none";
      linesEl.style.transform = `translateY(${state.pausedTransform}px)`;
      state.isPaused = true;
    };

    const onLeave = () => {
      const state = pausedRef.current;
      if (!state.isPaused) return;
      if (state.scrollHeight === 0 || !state.animationDuration) {
        linesEl.style.animationPlayState = "running";
        state.isPaused = false;
        return;
      }

      const currentOffset = Math.abs(state.pausedTransform);
      const normalizedOffset = currentOffset % state.scrollHeight;
      const progress = normalizedOffset / state.scrollHeight;
      const delay = -(progress * state.animationDuration);

      requestAnimationFrame(() => {
        linesEl.style.transform = "";
        linesEl.style.animation = `moody-scroll-up ${state.animationDuration}s linear ${delay}s infinite`;
      });
      state.isPaused = false;
      state.pausedTransform = 0;
    };

    container.addEventListener("mouseenter", onEnter);
    container.addEventListener("mouseleave", onLeave);

    return () => {
      container.removeEventListener("mouseenter", onEnter);
      container.removeEventListener("mouseleave", onLeave);
    };
  }, []);

  useEffect(() => {
    const header = headerRef.current;
    if (!header) return;

    const threshold = 100;
    header.classList.add("no-anim");

    const handleScroll = () => {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      if (scrollTop > threshold) {
        header.classList.add("is-hidden");
      } else {
        header.classList.remove("is-hidden");
      }
    };

    handleScroll();
    requestAnimationFrame(() => header.classList.remove("no-anim"));

    let ticking = false;
    const onScroll = () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          handleScroll();
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div id="header-wrapper" ref={headerRef}>
      <div className="top-bar" aria-hidden="true">
        <div className="top-bar-left">
          <span></span>
          <span>File</span>
          <span>Edit</span>
          <span>View</span>
        </div>
        <div className="top-bar-center" />
        <div className="top-bar-right">
          <span className="top-bar-pill" />
          <span className="top-bar-pill" />
          <span>100%</span>
        </div>
      </div>

      <div id="notch-prompter" ref={containerRef}>
        <div className="notch-glow" aria-hidden="true" />
        <div className="notch-text">
          <div id="notch-lines" ref={linesRef} />
        </div>
        <div className="notch-fade-overlay" aria-hidden="true" />
      </div>
    </div>
  );
}
