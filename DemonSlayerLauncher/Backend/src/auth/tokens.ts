import { createHash, randomBytes } from 'node:crypto';
import { SignJWT, jwtVerify } from 'jose';
import type { Env } from '../config/env.js';

export interface AccessClaims {
  userId: number;
  sessionId: string;
}

/** Access tokens JWT courts (HS256), liés à une session révocable. */
export class TokenService {
  private readonly key: Uint8Array;

  constructor(private readonly env: Env) {
    this.key = new TextEncoder().encode(env.JWT_SECRET);
  }

  get accessTtlSeconds(): number {
    return this.env.ACCESS_TOKEN_TTL_SECONDS;
  }

  async signAccess(claims: AccessClaims): Promise<{ token: string; expiresAt: Date }> {
    const now = Math.floor(Date.now() / 1000);
    const exp = now + this.env.ACCESS_TOKEN_TTL_SECONDS;
    const token = await new SignJWT({ sid: claims.sessionId })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setSubject(String(claims.userId))
      .setIssuer(this.env.JWT_ISSUER)
      .setAudience(this.env.JWT_AUDIENCE)
      .setIssuedAt(now)
      .setExpirationTime(exp)
      .sign(this.key);
    return { token, expiresAt: new Date(exp * 1000) };
  }

  /** Retourne les claims ou `null` si le token est invalide / expiré. */
  async verifyAccess(token: string): Promise<AccessClaims | null> {
    try {
      const { payload } = await jwtVerify(token, this.key, {
        issuer: this.env.JWT_ISSUER,
        audience: this.env.JWT_AUDIENCE,
        algorithms: ['HS256'],
      });
      const userId = Number(payload.sub);
      const sessionId = payload.sid;
      if (!Number.isSafeInteger(userId) || typeof sessionId !== 'string') return null;
      return { userId, sessionId };
    } catch {
      return null;
    }
  }
}

/** Jeton opaque aléatoire (refresh token). 48 octets = 384 bits d'entropie. */
export function generateOpaqueToken(bytes = 48): string {
  return randomBytes(bytes).toString('base64url');
}

export function sha256(value: string): Buffer {
  return createHash('sha256').update(value, 'utf8').digest();
}

// Alphabet sans caractères ambigus (0/O, 1/I). 32 symboles → aucun biais modulo.
const RESET_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** Code de réinitialisation lisible : XXXX-XXXX-XXXX (60 bits). */
export function generateResetCode(): string {
  const bytes = randomBytes(12);
  let code = '';
  for (let i = 0; i < bytes.length; i++) {
    if (i > 0 && i % 4 === 0) code += '-';
    code += RESET_ALPHABET[bytes[i]! % 32];
  }
  return code;
}

export function normalizeResetCode(input: string): string {
  return input.toUpperCase().replace(/[^A-Z0-9]/g, '');
}
