import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { SiteFooter } from "@/components/SiteFooter";
import { blogPosts, blogPostsBySlug } from "@/lib/blog-posts";
import { siteTheme } from "@/lib/themes";

type BlogPostPageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  return blogPosts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: BlogPostPageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = blogPostsBySlug[slug];

  if (!post) {
    return {
      title: "Post not found — Prompt My Notch",
    };
  }

  return {
    title: `${post.title} — Prompt My Notch`,
    description: post.description,
  };
}

export default async function BlogPostPage({ params }: BlogPostPageProps) {
  const { slug } = await params;
  const post = blogPostsBySlug[slug];
  const scheme = siteTheme;

  if (!post) {
    notFound();
  }

  return (
    <div className="min-h-screen" style={{ backgroundColor: scheme.pageBg, color: scheme.text }}>
      <main className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-16">
        <div>
          <Link
            href="/blog"
            className="text-sm underline-offset-4 hover:underline"
            style={{ color: scheme.textMuted }}
          >
            ← Back to blog
          </Link>
        </div>

        <article className="mt-6 rounded-xl border p-6 sm:p-8" style={{ borderColor: scheme.cardBorder, backgroundColor: scheme.cardBg }}>
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
          <h1 className="font-display text-3xl font-bold leading-tight sm:text-4xl">{post.title}</h1>
          <p className="mt-3 text-sm" style={{ color: scheme.textMuted }}>
            {post.publishedAt} · {post.readTime}
          </p>

          <div className="mt-8 space-y-4 font-reading leading-relaxed" style={{ color: scheme.text }}>
            {post.content.map((paragraph) => {
              if (paragraph.startsWith("- ")) {
                const items = paragraph
                  .split("\n")
                  .map((line) => line.trim())
                  .filter((line) => line.startsWith("- "))
                  .map((line) => line.slice(2));
                return (
                  <ul key={paragraph} className="list-disc space-y-1 pl-6">
                    {items.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                );
              }

              const [lead, ...rest] = paragraph.split("\n");
              return (
                <p key={paragraph}>
                  {lead}
                  {rest.length ? (
                    <>
                      <br />
                      {rest.join("\n")}
                    </>
                  ) : null}
                </p>
              );
            })}
          </div>
        </article>
      </main>
      <SiteFooter homeHref="/" />
    </div>
  );
}
