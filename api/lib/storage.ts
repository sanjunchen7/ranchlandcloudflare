import { runtimeEnv, type R2BucketLike } from "./runtime";

export type StoredObject = {
  body: ReadableStream;
  contentType?: string;
  size?: number;
  etag?: string;
};

function bucket(): R2BucketLike {
  const binding = runtimeEnv().MEDIA_BUCKET;
  if (!binding) throw new Error("MEDIA_BUCKET R2 binding is not configured.");
  return binding;
}

function mediaPath(key: string): string {
  return `/api/media/${key.split("/").map(encodeURIComponent).join("/")}`;
}

/**
 * R2-backed media storage. The database stores object keys only. URLs are
 * controlled application routes so public/internal authorization remains
 * enforceable and links do not expire like presigned URLs.
 */
export const storage = {
  async uploadFile(input: {
    fileContent: Uint8Array | string;
    fileName: string;
    contentType?: string;
  }) {
    const key = input.fileName.replace(/^\/+/, "");
    await bucket().put(key, input.fileContent, {
      httpMetadata: { contentType: input.contentType || "application/octet-stream" },
    });
    return { key, url: mediaPath(key) };
  },

  async deleteFiles(input: { fileKeys: string[] }) {
    if (input.fileKeys.length) await bucket().delete(input.fileKeys);
  },

  async getFile(key: string): Promise<StoredObject | null> {
    const object = await bucket().get(key);
    if (!object) return null;
    return {
      body: object.body,
      contentType: object.httpMetadata?.contentType,
      size: object.size,
      etag: object.httpEtag,
    };
  },

  // Kept as the existing routers' URL boundary. R2 does not need a presigned
  // URL here; this returns the stable, access-controlled media route instead.
  async getPresignedUrl(input: { key: string }) {
    return { url: mediaPath(input.key) };
  },
};
