import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // API-only backend — no React pages needed
  reactStrictMode: true,
  typescript: {
    // TODO: Fix all async/await type errors from live-config migration
    // then remove this flag
    ignoreBuildErrors: true,
  },
}

export default nextConfig
