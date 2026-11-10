import { currentRequestId } from "./requestcontext";
import { scrubCtx, scrubValue } from "./scrub";

type Level = "debug" | "info" | "warn" | "error";
const RESERVED_KEYS = new Set(["ts", "level", "msg", "requestId"]);

function write(level: Level, msg: string, ctx?: Record<string, unknown>): void {
  try {
    const requestId = currentRequestId();
    const extra = Object.fromEntries(
      Object.entries(scrubCtx(ctx) ?? {}).filter(([key]) => !RESERVED_KEYS.has(key)),
    );
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      level,
      ...(requestId ? { requestId } : {}),
      msg: scrubValue(msg),
      ...extra,
    });
    if (level === "error") console.error(line);
    else if (level === "warn") console.warn(line);
    else console.log(line);
  } catch {
    // Logging is always best-effort and must never fail a reservation request.
  }
}

export function appendLine(line: string): void {
  try { console.log(line); } catch { /* Best-effort client log sink. */ }
}

export const log = {
  info: (msg: string, ctx?: Record<string, unknown>) => write("info", msg, ctx),
  warn: (msg: string, ctx?: Record<string, unknown>) => write("warn", msg, ctx),
  error: (msg: string, ctx?: Record<string, unknown>) => write("error", msg, ctx),
  debug: (msg: string, ctx?: Record<string, unknown>) => write("debug", msg, ctx),
};
