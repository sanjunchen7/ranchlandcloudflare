export type InspectedImage = {
  format: "jpeg" | "png" | "webp";
  mimeType: "image/jpeg" | "image/png" | "image/webp";
  extension: "jpg" | "png" | "webp";
  width: number;
  height: number;
};

const u16be = (b: Uint8Array, p: number) => (b[p] << 8) | b[p + 1];
const u32be = (b: Uint8Array, p: number) => ((b[p] << 24) >>> 0) + (b[p + 1] << 16) + (b[p + 2] << 8) + b[p + 3];
const u24le = (b: Uint8Array, p: number) => b[p] + (b[p + 1] << 8) + (b[p + 2] << 16);

function result(format: InspectedImage["format"], width: number, height: number): InspectedImage {
  if (!Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1 || width * height > 50_000_000) {
    throw new Error("Invalid or excessive image dimensions.");
  }
  return {
    format,
    width,
    height,
    mimeType: `image/${format}`,
    extension: format === "jpeg" ? "jpg" : format,
  };
}

function jpeg(bytes: Uint8Array): InspectedImage {
  const sof = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);
  let p = 2;
  while (p + 9 < bytes.length) {
    if (bytes[p] !== 0xff) throw new Error("Invalid JPEG segment.");
    while (bytes[p] === 0xff) p++;
    const marker = bytes[p++];
    if (marker === 0xd9 || marker === 0xda) break;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (p + 2 > bytes.length) throw new Error("Truncated JPEG segment.");
    const length = u16be(bytes, p);
    if (length < 2 || p + length > bytes.length) throw new Error("Invalid JPEG segment length.");
    if (sof.has(marker)) return result("jpeg", u16be(bytes, p + 5), u16be(bytes, p + 3));
    p += length;
  }
  throw new Error("JPEG dimensions were not found.");
}

function webp(bytes: Uint8Array): InspectedImage {
  const chunk = String.fromCharCode(...bytes.slice(12, 16));
  if (chunk === "VP8X" && bytes.length >= 30) {
    return result("webp", u24le(bytes, 24) + 1, u24le(bytes, 27) + 1);
  }
  if (chunk === "VP8 " && bytes.length >= 30 && bytes[23] === 0x9d && bytes[24] === 0x01 && bytes[25] === 0x2a) {
    const width = (bytes[26] | (bytes[27] << 8)) & 0x3fff;
    const height = (bytes[28] | (bytes[29] << 8)) & 0x3fff;
    return result("webp", width, height);
  }
  if (chunk === "VP8L" && bytes.length >= 25 && bytes[20] === 0x2f) {
    const width = 1 + bytes[21] + ((bytes[22] & 0x3f) << 8);
    const height = 1 + (bytes[22] >> 6) + (bytes[23] << 2) + ((bytes[24] & 0x0f) << 10);
    return result("webp", width, height);
  }
  throw new Error("Unsupported or truncated WebP image.");
}

export function decodeBase64(value: string): Uint8Array {
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(value) || value.length % 4 !== 0) throw new Error("Invalid base64 image data.");
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

export function inspectImage(bytes: Uint8Array): InspectedImage {
  if (bytes.length >= 24 && bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47 && bytes[4] === 0x0d && bytes[5] === 0x0a && bytes[6] === 0x1a && bytes[7] === 0x0a) {
    if (String.fromCharCode(...bytes.slice(12, 16)) !== "IHDR") throw new Error("Invalid PNG header.");
    return result("png", u32be(bytes, 16), u32be(bytes, 20));
  }
  if (bytes.length >= 10 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return jpeg(bytes);
  if (bytes.length >= 25 && String.fromCharCode(...bytes.slice(0, 4)) === "RIFF" && String.fromCharCode(...bytes.slice(8, 12)) === "WEBP") return webp(bytes);
  throw new Error("Only valid JPEG, PNG and WebP images are supported.");
}
