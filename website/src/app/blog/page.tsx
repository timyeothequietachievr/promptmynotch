import Link from "next/link";
import type { Metadata } from "next";
import { blogPosts } from "@/lib/blog-posts";

export const metadata: Metadata = {
  title: "Blog — Prompt My Notch",
  description:
    "Practical guides for public speaking, interviews, and presenting on camera without sounding scripted.",
};

export default function BlogPage() {
  return (
    <main className="mx-auto max-w-4xl px-4 py-14 sm:px-6 sm:py-16">
      <h1 className="font-display text-3xl font-bold sm:text-4xl">Prompt My Notch Blog</h1>
      <p className="mt-3 max-w-2xl font-reading text-base text-zinc-300 sm:text-lg">
        Public speaking and interview guides to help you stay clear, confident, and natural on
        camera.
      </p>

      <div className="mt-10 space-y-5">
        {blogPosts.map((post) => (
          <article
            key={post.slug}
            className="rounded-xl border border-zinc-700/70 bg-zinc-900/45 p-6"
          >
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
            <h2 className="font-display text-2xl font-semibold">
              <Link className="hover:underline" href={`/blog/${post.slug}`}>
                {post.title}
              </Link>
            </h2>
            <p className="mt-2 font-reading text-zinc-300">{post.description}</p>
            <p className="mt-3 text-sm text-zinc-400">
              {post.publishedAt} · {post.readTime}
            </p>
          </article>
        ))}
      </div>
    </main>
  );
}
