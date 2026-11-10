import { AsyncLocalStorage } from "node:async_hooks";

export type EmailBinding = {
  send(message: {
    to: string;
    from: string;
    subject: string;
    text: string;
  }): Promise<{ messageId?: string }>;
};

export type HyperdriveBinding = {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
};

export type R2ObjectLike = {
  body: ReadableStream;
  httpMetadata?: { contentType?: string };
  size: number;
  httpEtag: string;
};

export type R2BucketLike = {
  put(key: string, value: string | Uint8Array, options?: { httpMetadata?: { contentType?: string } }): Promise<unknown>;
  delete(keys: string | string[]): Promise<void>;
  get(key: string): Promise<R2ObjectLike | null>;
};

export type RuntimeEnv = {
  ENVIRONMENT?: string;
  DATABASE_URL?: string;
  EMAIL_FROM?: string;
  HYPERDRIVE?: HyperdriveBinding;
  MEDIA_BUCKET?: R2BucketLike;
  EMAIL?: EmailBinding;
  ASSETS?: { fetch(request: Request): Promise<Response> };
};

type RequestRuntime = {
  env: RuntimeEnv;
  db?: unknown;
  close?: () => Promise<void>;
};

const requestStorage = new AsyncLocalStorage<RequestRuntime>();

export function runWithRuntime<T>(env: RuntimeEnv, fn: () => T): T {
  return requestStorage.run({ env }, fn);
}

export function currentRuntime(): RequestRuntime | undefined {
  return requestStorage.getStore();
}

export function runtimeEnv(): RuntimeEnv {
  const scoped = currentRuntime();
  if (scoped) return scoped.env;
  // This fallback is for local Drizzle/seed/test scripts, not a second Worker
  // configuration path. Worker requests always enter through runWithRuntime.
  return process.env as RuntimeEnv;
}

export async function closeRuntime(): Promise<void> {
  const scoped = currentRuntime();
  if (!scoped?.close) return;
  const close = scoped.close;
  scoped.close = undefined;
  scoped.db = undefined;
  await close();
}
