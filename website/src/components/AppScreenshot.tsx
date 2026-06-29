import Image from "next/image";

export function AppScreenshot({
  src,
  alt,
  caption,
  priority = false,
}: {
  src: string;
  alt: string;
  caption?: string;
  priority?: boolean;
}) {
  return (
    <figure className="overflow-hidden rounded-xl border border-[var(--shot-border)] bg-[var(--shot-bg)]">
      <Image
        src={src}
        alt={alt}
        width={1600}
        height={1000}
        priority={priority}
        className="h-auto w-full"
        sizes="(max-width: 768px) 100vw, 900px"
      />
      {caption && (
        <figcaption className="border-t border-[var(--shot-border)] px-4 py-2.5 font-reading text-sm text-[var(--shot-caption)]">
          {caption}
        </figcaption>
      )}
    </figure>
  );
}
