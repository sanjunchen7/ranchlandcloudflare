import { describe, expect, it } from "vitest";
import { decodeBase64, inspectImage } from "./image";

describe("Worker-compatible image inspection", () => {
  it("reads PNG magic bytes and dimensions", () => {
    const bytes = decodeBase64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");
    expect(inspectImage(bytes)).toMatchObject({ format: "png", width: 1, height: 1, mimeType: "image/png" });
  });

  it("reads JPEG SOF dimensions without native image libraries", () => {
    const bytes = new Uint8Array([
      0xff, 0xd8, 0xff, 0xc0, 0x00, 0x11, 0x08, 0x01, 0x68, 0x01, 0x90, 0x03,
      0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01, 0xff, 0xd9,
    ]);
    expect(inspectImage(bytes)).toMatchObject({ format: "jpeg", width: 400, height: 360 });
  });

  it("reads WebP VP8X canvas dimensions", () => {
    const bytes = new Uint8Array(30);
    bytes.set([0x52, 0x49, 0x46, 0x46], 0);
    bytes.set([0x57, 0x45, 0x42, 0x50], 8);
    bytes.set([0x56, 0x50, 0x38, 0x58], 12);
    bytes.set([0x7f, 0x00, 0x00], 24);
    bytes.set([0x7f, 0x00, 0x00], 27);
    expect(inspectImage(bytes)).toMatchObject({ format: "webp", width: 128, height: 128 });
  });

  it("rejects invalid base64, spoofed formats and excessive dimensions", () => {
    expect(() => decodeBase64("not base64!")).toThrow();
    expect(() => inspectImage(new TextEncoder().encode("not an image"))).toThrow(/JPEG, PNG and WebP/);
    const png = decodeBase64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");
    png.set([0xff, 0xff, 0xff, 0xff], 16);
    expect(() => inspectImage(png)).toThrow(/dimensions/);
  });
});
