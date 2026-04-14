import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // API-only backend; keep Next server tracing away from optional sharp binaries.
  reactStrictMode: true,
  outputFileTracingExcludes: {
    'next-server': [
      '**/node_modules/sharp/**/*',
      '**/node_modules/@img/sharp*/**/*',
    ],
  },
}

export default nextConfig
