import { Hono } from "hono";
import { eq, or, sql } from "drizzle-orm";
import { media } from "@db/schema";
import { getDb } from "../queries/connection";
import { storage } from "../lib/storage";
import { getStaff } from "../staff";
import type { RuntimeEnv } from "../lib/runtime";

export const mediaRoutes = new Hono<{ Bindings: RuntimeEnv }>();

mediaRoutes.get("/api/media/*", async (c) => {
  const key = c.req.path.slice("/api/media/".length).split("/").map((part) => decodeURIComponent(part)).join("/");
  if (!key || key.length > 512) return c.notFound();
  const [item] = await getDb().select().from(media).where(or(
    eq(media.storageKey, key),
    sql`JSON_SEARCH(${media.variants}, 'one', ${key}) IS NOT NULL`,
  )).limit(1);
  if (!item) return c.notFound();
  if (!item.isPublic && !(await getStaff(c.req.raw))) return c.notFound();
  const object = await storage.getFile(key);
  if (!object) return c.notFound();
  const headers = new Headers({
    "Content-Type": object.contentType || item.mimeType,
    "Cache-Control": item.isPublic ? "public, max-age=31536000, immutable" : "private, no-store",
    "X-Content-Type-Options": "nosniff",
    "Content-Disposition": "inline",
  });
  if (object.etag) headers.set("ETag", object.etag);
  if (object.size != null) headers.set("Content-Length", String(object.size));
  return new Response(object.body, { headers });
});
