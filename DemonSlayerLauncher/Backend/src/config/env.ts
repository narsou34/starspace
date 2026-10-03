import { z } from 'zod';

const bool = z
  .enum(['true', 'false', '1', '0'])
  .default('false')
  .transform((v) => v === 'true' || v === '1');

const optionalUrl = z
  .string()
  .trim()
  .optional()
  .transform((v) => (v ? v : undefined))
  .pipe(z.url().optional());

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(8080),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  TRUST_PROXY: bool,

  DATABASE_URL: z.string().min(1, 'DATABASE_URL est obligatoire'),

  JWT_SECRET: z.string().min(32, 'JWT_SECRET doit contenir au moins 32 caractères'),
  JWT_ISSUER: z.string().default('dsrp-api'),
  JWT_AUDIENCE: z.string().default('dsrp-launcher'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().min(60).max(3600).default(900),
  REFRESH_TTL_REMEMBER_DAYS: z.coerce.number().int().min(1).max(90).default(30),
  REFRESH_TTL_SESSION_HOURS: z.coerce.number().int().min(1).max(72).default(12),

  LOGIN_MAX_FAILURES: z.coerce.number().int().min(1).default(5),
  LOGIN_MAX_FAILURES_PER_IP: z.coerce.number().int().min(1).default(30),
  LOGIN_LOCK_MINUTES: z.coerce.number().int().min(1).default(15),
  AUTH_RATE_LIMIT_PER_MINUTE: z.coerce.number().int().min(1).default(10),
  GLOBAL_RATE_LIMIT_PER_MINUTE: z.coerce.number().int().min(1).default(120),

  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((v) =>
      v
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),

  REGISTRATION_ENABLED: z
    .enum(['true', 'false', '1', '0'])
    .default('true')
    .transform((v) => v === 'true' || v === '1'),

  SMTP_URL: z
    .string()
    .optional()
    .transform((v) => (v ? v : undefined)),
  MAIL_FROM: z.string().default('Demon Slayer RP <no-reply@localhost>'),

  PUBLIC_SERVER_NAME: z.string().default('Demon Slayer RP'),
  PUBLIC_DISCORD_URL: optionalUrl,
  PUBLIC_WEBSITE_URL: optionalUrl,
  PUBLIC_SUPPORT_EMAIL: z
    .string()
    .trim()
    .optional()
    .transform((v) => (v ? v : undefined))
    .pipe(z.email().optional()),

  AUTO_MIGRATE: bool,
});

export type Env = z.infer<typeof envSchema>;

/**
 * Charge et valide la configuration. Toute valeur sensible provient
 * des variables d'environnement — rien n'est codé en dur.
 */
export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const parsed = envSchema.safeParse(source);
  if (!parsed.success) {
    const details = parsed.error.issues
      .map((i) => `  - ${i.path.join('.')}: ${i.message}`)
      .join('\n');
    throw new Error(`Configuration invalide :\n${details}`);
  }
  return parsed.data;
}
