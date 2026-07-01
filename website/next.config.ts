import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: process.cwd(),
  },
  async redirects() {
    return [
      {
        source: "/simple",
        destination: "/",
        permanent: false,
      },
      {
        source: "/:path(.*\\.zip)",
        destination: "/404",
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
