import { NextRequest } from 'next/server'

export function makeNextRequest(
  url: string,
  init?: ConstructorParameters<typeof Request>[1],
): NextRequest {
  return new NextRequest(new Request(url, init))
}
