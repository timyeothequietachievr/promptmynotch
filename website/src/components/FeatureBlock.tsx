import { AppScreenshot } from "@/components/AppScreenshot";
import { Container, Eyebrow } from "@/components/ds/primitives";
import type { FeatureBlockContent } from "@/lib/content";
import type { ColorScheme } from "@/lib/themes";

export function FeatureBlock({
  block,
  scheme,
  altBg = false,
}: {
  block: FeatureBlockContent;
  scheme: ColorScheme;
  altBg?: boolean;
}) {
  const hasImage = Boolean(block.image);
  const reverse = block.reverse ?? false;

  return (
    <section
      id={block.id}
      style={{ background: altBg ? scheme.sectionAltBg : scheme.pageBg }}
      className="py-14 sm:py-20"
    >
      <Container>
        <div
          className={`grid items-center gap-10 lg:gap-14 ${
            hasImage ? "lg:grid-cols-2" : ""
          }`}
        >
          <div className={hasImage && reverse ? "lg:order-2" : ""}>
            {block.eyebrow && (
              <Eyebrow tone={scheme.eyebrowTone} className="mb-4">
                {block.eyebrow}
              </Eyebrow>
            )}
            <h2
              className="font-display text-2xl font-bold sm:text-3xl"
              style={{ color: scheme.heading, lineHeight: 1.12 }}
            >
              {block.title}
            </h2>
            {block.lead ? (
              <p
                className="mt-4 font-reading text-lg leading-relaxed"
                style={{ color: scheme.text }}
              >
                {block.lead}
              </p>
            ) : null}
            {block.body?.map((para) => (
              <p
                key={para.slice(0, 40)}
                className="mt-4 font-reading text-[15px] leading-relaxed"
                style={{ color: scheme.textMuted }}
              >
                {para}
              </p>
            ))}
            {block.bullets && block.bullets.length > 0 && (
              <ul className="mt-6 space-y-2.5">
                {block.bullets.map((item) => (
                  <li
                    key={item}
                    className="flex gap-2.5 font-reading text-[15px] leading-relaxed"
                    style={{ color: scheme.text }}
                  >
                    <span
                      className="mt-0.5 shrink-0 font-sans font-bold"
                      style={{ color: scheme.accent }}
                      aria-hidden
                    >
                      →
                    </span>
                    {item}
                  </li>
                ))}
              </ul>
            )}
          </div>

          {block.image && (
            <div className={reverse ? "lg:order-1" : ""}>
              <AppScreenshot
                src={block.image.src}
                alt={block.image.alt}
                caption={block.image.caption}
              />
            </div>
          )}
        </div>
      </Container>
    </section>
  );
}
