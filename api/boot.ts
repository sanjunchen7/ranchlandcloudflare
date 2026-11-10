import { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { appRouter } from "./router";
import { createContext } from "./context";
import { log } from "./lib/logger";
import { handleClientLog } from "./lib/clientlog";
import { REQUEST_ID_HEADER, runWithRequestId } from "./lib/requestcontext";
import { closeRuntime, runWithRuntime, type RuntimeEnv } from "./lib/runtime";
import { seoRoutes } from "./routes/seo";
import { mediaRoutes } from "./routes/media";

const app = new Hono<{ Bindings: RuntimeEnv }>();

// Every API request receives its own bindings and MySQL connection. The
// connection is reused by all services in that request and closed afterwards.
app.use("*", async (c, next) => {
  await runWithRuntime(c.env, async () => {
    try {
      await next();
    } finally {
      await closeRuntime().catch((error) => log.warn("database connection cleanup failed", { error: String(error) }));
    }
  });
});

app.use("*", async (c, next) => {
  const requestId = crypto.randomUUID();
  if (c.req.path === "/api/log") {
    await next();
    return;
  }
  const start = Date.now();
  await runWithRequestId(requestId, async () => {
    await next();
    c.res.headers.set(REQUEST_ID_HEADER, requestId);
    if (!c.req.path.startsWith("/api/")) return;
    log.info("request", {
      method: c.req.method,
      path: c.req.path,
      status: c.res.status,
      durationMs: Date.now() - start,
    });
  });
});

app.use("/api/trpc/*", bodyLimit({ maxSize: 16 * 1024 * 1024 }));
app.use("/api/trpc/*", async (c) => {
  return fetchRequestHandler({
    endpoint: "/api/trpc",
    req: c.req.raw,
    router: appRouter,
    createContext,
  });
});
app.post(
  "/api/log",
  bodyLimit({ maxSize: 64 * 1024, onError: (c) => c.body(null, 413) }),
  handleClientLog,
);
app.route("/", mediaRoutes);
app.route("/", seoRoutes);
app.all("/api/*", (c) => c.json({ error: "Not Found" }, 404));
app.notFound(async (c) => {
  if (!c.env.ASSETS) return c.text("Not Found", 404);
  const response = await c.env.ASSETS.fetch(c.req.raw);
  // Asset responses have immutable headers; clone before the observability
  // middleware adds X-Request-Id.
  return new Response(response.body, response);
});

app.onError((err, c) => {
  log.error("unhandled request error", {
    method: c.req.method,
    path: c.req.path,
    error: err instanceof Error ? err.message : String(err),
    stack: err instanceof Error ? err.stack : undefined,
  });
  return c.json({ error: "Internal Server Error" }, 500);
});

// Cloudflare's Vite plugin discovers this Hono fetch handler as the Worker
// entry. Static React assets and SPA fallback are handled by Workers Assets.
export default app;
