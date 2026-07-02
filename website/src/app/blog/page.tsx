import Link from "next/link";
import type { Metadata } from "next";
import { SiteFooter } from "@/components/SiteFooter";
import { blogPosts } from "@/lib/blog-posts";
import { siteTheme } from "@/lib/themes";

export const metadata: Metadata = {
  title: "Blog — Prompt My Notch",
  description:
    "Practical guides for public speaking, interviews, and presenting on camera without sounding scripted.",
};

export default function BlogPage() {
  const scheme = siteTheme;

  return (
    <div className="min-h-screen" style={{ backgroundColor: scheme.pageBg, color: scheme.text }}>
      <main className="mx-auto max-w-4xl px-4 py-14 sm:px-6 sm:py-16">
        <Link
          href="/"
          className="text-sm underline-offset-4 hover:underline"
          style={{ color: scheme.textMuted }}
        >
          ← back
        </Link>

        <h1 className="mt-5 font-display text-3xl font-bold sm:text-4xl">Prompt My Notch Blog</h1>
        <p className="mt-3 max-w-2xl font-reading text-base sm:text-lg" style={{ color: scheme.textMuted }}>
          Public speaking and interview guides to help you stay clear, confident, and natural on
          camera.
        </p>

        <div className="mt-10 space-y-5">
          {blogPosts.map((post) => (
            <article
              key={post.slug}
              className="rounded-xl border p-6"
              style={{ borderColor: scheme.cardBorder, backgroundColor: scheme.cardBg }}
            >
              <div className="mb-3 flex flex-wrap gap-2">
                {post.tags.map((tag) => (
                  <span
                    key={tag}
                    className="rounded-full border px-2.5 py-0.5 text-xs"
                    style={{ borderColor: scheme.cardBorder, color: scheme.textMuted }}
                  >
                    {tag}
                  </span>
                ))}
              </div>
              <h2 className="font-display text-2xl font-semibold">
                <Link className="underline-offset-4 hover:underline" href={`/blog/${post.slug}`}>
                  {post.title}
                </Link>
              </h2>
              <p className="mt-2 font-reading" style={{ color: scheme.textMuted }}>
                {post.description}
              </p>
              <p className="mt-3 text-sm" style={{ color: scheme.textMuted }}>
                {post.publishedAt} · {post.readTime}
              </p>
            </article>
          ))}
        </div>
      </main>
      <SiteFooter homeHref="/" />
    </div>
  );
}
