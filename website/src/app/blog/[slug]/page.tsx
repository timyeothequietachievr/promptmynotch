import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogPosts, blogPostsBySlug } from "@/lib/blog-posts";

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

  if (!post) {
    notFound();
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-16">
      <Link href="/blog" className="text-sm text-zinc-400 hover:text-zinc-200 hover:underline">
        ← Back to blog
      </Link>

      <article className="mt-6">
        <div className="mb-3 flex flex-wrap gap-2">
          {post.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-full border border-zinc-600/70 px-2.5 py-0.5 text-xs text-zinc-300"
            >
              {tag}
            </span>
          ))}
        </div>
        <h1 className="font-display text-3xl font-bold leading-tight sm:text-4xl">{post.title}</h1>
        <p className="mt-3 text-sm text-zinc-400">
          {post.publishedAt} · {post.readTime}
        </p>

        <div className="mt-8 space-y-4 font-reading leading-relaxed text-zinc-200">
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
  );
}
