import crypto from "crypto";

// Plaid access token은 은행 계좌에 직접 접근 가능한 비밀값이라 DB에 평문으로
// 두면 안 된다. AES-256-GCM으로 암호화해서 저장하고, 쓸 때만 복호화한다.
const ALGORITHM = "aes-256-gcm";
const IV_LENGTH = 12;

function loadKey(): Buffer {
  const raw = process.env.PLAID_TOKEN_KEY;
  if (!raw) {
    throw new Error("PLAID_TOKEN_KEY is not set; cannot encrypt/decrypt Plaid tokens");
  }
  const key = Buffer.from(raw, "base64");
  if (key.length !== 32) {
    throw new Error("PLAID_TOKEN_KEY must decode to exactly 32 bytes (base64-encoded AES-256 key)");
  }
  return key;
}

export function encryptPlaidToken(plainToken: string): string {
  const key = loadKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([cipher.update(plainToken, "utf8"), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return `v1:${iv.toString("base64")}:${authTag.toString("base64")}:${ciphertext.toString("base64")}`;
}

// 기존에 평문으로 저장된 토큰과의 호환을 위해, "v1:" 접두사가 없으면
// 암호화 이전 값으로 보고 그대로 반환한다.
export function decryptPlaidToken(storedValue: string): string {
  if (!storedValue.startsWith("v1:")) {
    return storedValue;
  }

  const [, ivB64, tagB64, ciphertextB64] = storedValue.split(":");
  const key = loadKey();
  const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(ivB64, "base64"));
  decipher.setAuthTag(Buffer.from(tagB64, "base64"));
  const plaintext = Buffer.concat([
    decipher.update(Buffer.from(ciphertextB64, "base64")),
    decipher.final(),
  ]);
  return plaintext.toString("utf8");
}
