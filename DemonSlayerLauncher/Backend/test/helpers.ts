import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { type Env, loadEnv } from '../src/config/env.js';
import { runMigrations } from '../src/database/migrate.js';
import { type Db, createPool } from '../src/database/pool.js';
import type { Mailer } from '../src/mail/mailer.js';

/**
 * Base de test dédiée. Par défaut : postgres://dsrp:dsrp_dev_pw@127.0.0.1:5432/dsrp_test
 * Surcharger avec TEST_DATABASE_URL. ATTENTION : la base est vidée à chaque test.
 */
export const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? 'postgres://dsrp:dsrp_dev_pw@127.0.0.1:5432/dsrp_test';

export class MemoryMailer implements Mailer {
  public readonly sent: { to: string; code: string }[] = [];
  async sendPasswordReset(to: string, _username: string, code: string): Promise<void> {
    this.sent.push({ to, code });
  }
  lastCodeFor(to: string): string | undefined {
    return [...this.sent].reverse().find((m) => m.to === to)?.code;
  }
}

export interface TestContext {
  app: FastifyInstance;
  db: Db;
  env: Env;
  mailer: MemoryMailer;
}

export async function createTestContext(overrides: Record<string, string> = {}): Promise<TestContext> {
  const env = loadEnv({
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    DATABASE_URL: TEST_DATABASE_URL,
    JWT_SECRET: 'test-secret-test-secret-test-secret-0123456789',
    AUTH_RATE_LIMIT_PER_MINUTE: '1000',
    GLOBAL_RATE_LIMIT_PER_MINUTE: '5000',
    ...overrides,
  });
  const db = createPool(env.DATABASE_URL);
  await runMigrations(db);
  await db.query(
    'TRUNCATE users, sessions, login_attempts, password_resets, security_logs RESTART IDENTITY CASCADE',
  );
  const mailer = new MemoryMailer();
  const app = await buildApp({ env, db, mailer });
  await app.ready();
  return { app, db, env, mailer };
}

export async function destroyTestContext(ctx: TestContext): Promise<void> {
  await ctx.app.close();
  await ctx.db.end();
}

export const VALID_PASSWORD = 'Respiration2026';

export async function registerUser(
  app: FastifyInstance,
  overrides: Partial<{ username: string; email: string; password: string; rememberMe: boolean }> = {},
) {
  const res = await app.inject({
    method: 'POST',
    url: '/api/auth/register',
    payload: {
      username: 'Narsou',
      email: 'narsou@example.com',
      password: VALID_PASSWORD,
      rememberMe: true,
      deviceName: 'PC-TEST',
      ...overrides,
    },
  });
  return res;
}
