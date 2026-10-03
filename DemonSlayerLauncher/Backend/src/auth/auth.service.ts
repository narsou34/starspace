import type { Env } from '../config/env.js';
import { AppError, Errors } from '../common/errors.js';
import { type Db, withTransaction } from '../database/pool.js';
import type { Mailer } from '../mail/mailer.js';
import { type PublicUser, type UserRow, UserRepository, toPublicUser } from '../players/user.repository.js';
import type { SecurityLogger } from '../security/securityLog.js';
import { burnPasswordCheck, hashPassword, verifyPassword } from './password.js';
import {
  type TokenService,
  generateOpaqueToken,
  generateResetCode,
  normalizeResetCode,
  sha256,
} from './tokens.js';

export interface RequestContext {
  ip: string;
  userAgent?: string;
  deviceName?: string;
}

export interface AuthResult {
  user: PublicUser;
  accessToken: string;
  accessTokenExpiresAt: string;
  /** Durée de vie en secondes (le launcher ne dépend pas de l'horloge du PC). */
  accessTokenExpiresIn: number;
  refreshToken: string;
  refreshTokenExpiresAt: string;
}

const RESET_CODE_TTL_MINUTES = 15;

export class AuthService {
  constructor(
    private readonly db: Db,
    private readonly env: Env,
    private readonly tokens: TokenService,
    private readonly mailer: Mailer,
    private readonly security: SecurityLogger,
  ) {}

  // ── Inscription ─────────────────────────────────────────────
  async register(
    input: { username: string; email: string; password: string; rememberMe: boolean },
    ctx: RequestContext,
  ): Promise<AuthResult> {
    if (!this.env.REGISTRATION_ENABLED) {
      throw new AppError(403, 'REGISTRATION_DISABLED', 'Les inscriptions sont actuellement fermées.');
    }

    const passwordHash = await hashPassword(input.password);
    let user: UserRow;
    try {
      user = await UserRepository.create(this.db, {
        username: input.username,
        email: input.email,
        passwordHash,
      });
    } catch (err) {
      const pgErr = err as { code?: string; constraint?: string };
      if (pgErr.code === '23505') {
        if (pgErr.constraint === 'users_username_lower_uq') {
          throw new AppError(409, 'USERNAME_TAKEN', 'Ce pseudo est déjà utilisé.', {
            fields: { username: 'Ce pseudo est déjà utilisé.' },
          });
        }
        throw new AppError(409, 'EMAIL_TAKEN', 'Cette adresse e-mail est déjà utilisée.', {
          fields: { email: 'Cette adresse e-mail est déjà utilisée.' },
        });
      }
      throw err;
    }

    await this.security.record({ event: 'USER_REGISTER', userId: user.id, ip: ctx.ip });
    await UserRepository.touchLogin(this.db, user.id);
    return this.createSession({ ...user, last_login_at: new Date() }, input.rememberMe, ctx);
  }

  // ── Connexion ───────────────────────────────────────────────
  async login(
    input: { login: string; password: string; rememberMe: boolean },
    ctx: RequestContext,
  ): Promise<AuthResult> {
    await this.assertNotLocked(input.login, ctx);

    const user = await UserRepository.findByLogin(this.db, input.login);
    const valid = user
      ? await verifyPassword(user.password_hash, input.password)
      : (await burnPasswordCheck(input.password), false);

    if (!user || !valid) {
      await this.recordAttempt(input.login, ctx.ip, false);
      await this.security.record({
        event: 'LOGIN_FAILED',
        userId: user?.id ?? null,
        ip: ctx.ip,
        details: { login: input.login.slice(0, 254) },
      });
      throw Errors.invalidCredentials();
    }

    if (user.status !== 'active') {
      await this.security.record({ event: 'LOGIN_DENIED_SUSPENDED', userId: user.id, ip: ctx.ip });
      throw Errors.suspended(user.status);
    }

    await this.recordAttempt(input.login, ctx.ip, true);
    await UserRepository.touchLogin(this.db, user.id);
    const result = await this.createSession({ ...user, last_login_at: new Date() }, input.rememberMe, ctx);
    await this.security.record({
      event: 'USER_LOGIN',
      userId: user.id,
      ip: ctx.ip,
      details: { device: ctx.deviceName ?? null, remember: input.rememberMe },
    });
    return result;
  }

  /** Verrouillage temporaire par identifiant et par IP après trop d'échecs. */
  private async assertNotLocked(login: string, ctx: RequestContext): Promise<void> {
    const windowSql = `now() - make_interval(mins => $2)`;
    const { rows: byId } = await this.db.query<{ failures: number; oldest: Date | null }>(
      `SELECT count(*)::int AS failures, min(created_at) AS oldest
         FROM login_attempts
        WHERE lower(identifier) = lower($1)
          AND NOT success
          AND created_at > ${windowSql}
          AND created_at > COALESCE(
                (SELECT max(created_at) FROM login_attempts
                  WHERE lower(identifier) = lower($1) AND success), '-infinity')`,
      [login, this.env.LOGIN_LOCK_MINUTES],
    );
    const { rows: byIp } = await this.db.query<{ failures: number; oldest: Date | null }>(
      `SELECT count(*)::int AS failures, min(created_at) AS oldest
         FROM login_attempts
        WHERE ip = $1 AND NOT success AND created_at > ${windowSql}`,
      [ctx.ip, this.env.LOGIN_LOCK_MINUTES],
    );

    const lockMs = this.env.LOGIN_LOCK_MINUTES * 60_000;
    const check = (row: { failures: number; oldest: Date | null } | undefined, max: number) => {
      if (row && row.failures >= max && row.oldest) {
        return Math.ceil((row.oldest.getTime() + lockMs - Date.now()) / 1000);
      }
      return 0;
    };
    const retryAfter = Math.max(
      check(byId[0], this.env.LOGIN_MAX_FAILURES),
      check(byIp[0], this.env.LOGIN_MAX_FAILURES_PER_IP),
    );
    if (retryAfter > 0) {
      await this.security.record({ event: 'LOGIN_BLOCKED', ip: ctx.ip, details: { login: login.slice(0, 254) } });
      throw Errors.locked(retryAfter);
    }
  }

  private async recordAttempt(identifier: string, ip: string, success: boolean): Promise<void> {
    await this.db.query('INSERT INTO login_attempts (identifier, ip, success) VALUES ($1, $2, $3)', [
      identifier.slice(0, 254),
      ip,
      success,
    ]);
  }

  // ── Sessions ────────────────────────────────────────────────
  private async createSession(user: UserRow, remember: boolean, ctx: RequestContext): Promise<AuthResult> {
    const refreshToken = generateOpaqueToken();
    const ttlMs = remember
      ? this.env.REFRESH_TTL_REMEMBER_DAYS * 86_400_000
      : this.env.REFRESH_TTL_SESSION_HOURS * 3_600_000;
    const expiresAt = new Date(Date.now() + ttlMs);

    const { rows } = await this.db.query<{ id: string }>(
      `INSERT INTO sessions (user_id, refresh_token_hash, device_name, user_agent, ip, remember, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [
        user.id,
        sha256(refreshToken),
        ctx.deviceName ?? null,
        ctx.userAgent?.slice(0, 255) ?? null,
        ctx.ip,
        remember,
        expiresAt,
      ],
    );
    const access = await this.tokens.signAccess({ userId: user.id, sessionId: rows[0]!.id });
    return {
      user: toPublicUser(user),
      accessToken: access.token,
      accessTokenExpiresAt: access.expiresAt.toISOString(),
      accessTokenExpiresIn: this.tokens.accessTtlSeconds,
      refreshToken,
      refreshTokenExpiresAt: expiresAt.toISOString(),
    };
  }

  /**
   * Rotation du refresh token. Si un ancien token déjà remplacé est
   * présenté, la session est considérée comme volée et révoquée.
   */
  async refresh(refreshToken: string, ctx: RequestContext): Promise<AuthResult> {
    const hash = sha256(refreshToken);
    const outcome = await withTransaction(this.db, async (client) => {
      const { rows } = await client.query<{
        id: string;
        user_id: number;
        expires_at: Date;
        revoked_at: Date | null;
      }>(
        `SELECT id, user_id, expires_at, revoked_at FROM sessions
          WHERE refresh_token_hash = $1 FOR UPDATE`,
        [hash],
      );
      const session = rows[0];

      if (!session) {
        const reused = await client.query<{ id: string; user_id: number }>(
          `UPDATE sessions SET revoked_at = now(), revoked_reason = 'token_reuse'
            WHERE previous_token_hash = $1 AND revoked_at IS NULL
            RETURNING id, user_id`,
          [hash],
        );
        const victim = reused.rows[0];
        if (victim) {
          await this.security.record(
            { event: 'SESSION_REFRESH_REUSE', userId: victim.user_id, ip: ctx.ip, details: { sessionId: victim.id } },
            client,
          );
        }
        return { error: Errors.sessionExpired() } as const;
      }
      if (session.revoked_at || session.expires_at.getTime() <= Date.now()) {
        return { error: Errors.sessionExpired() } as const;
      }

      const user = await UserRepository.findById(client, session.user_id);
      if (!user) return { error: Errors.sessionExpired() } as const;
      if (user.status !== 'active') {
        await client.query(
          `UPDATE sessions SET revoked_at = now(), revoked_reason = 'account_suspended' WHERE id = $1`,
          [session.id],
        );
        return { error: Errors.suspended(user.status) } as const;
      }

      const next = generateOpaqueToken();
      await client.query(
        `UPDATE sessions
            SET previous_token_hash = refresh_token_hash,
                refresh_token_hash  = $2,
                last_used_at        = now(),
                ip                  = $3
          WHERE id = $1`,
        [session.id, sha256(next), ctx.ip],
      );
      return { user, sessionId: session.id, expiresAt: session.expires_at, refreshToken: next } as const;
    });

    // Les erreurs sont levées après COMMIT pour conserver la révocation.
    if ('error' in outcome) throw outcome.error;

    const access = await this.tokens.signAccess({ userId: outcome.user.id, sessionId: outcome.sessionId });
    return {
      user: toPublicUser(outcome.user),
      accessToken: access.token,
      accessTokenExpiresAt: access.expiresAt.toISOString(),
      accessTokenExpiresIn: this.tokens.accessTtlSeconds,
      refreshToken: outcome.refreshToken,
      refreshTokenExpiresAt: outcome.expiresAt.toISOString(),
    };
  }

  async logout(refreshToken: string, ctx: RequestContext): Promise<void> {
    const { rows } = await this.db.query<{ user_id: number }>(
      `UPDATE sessions SET revoked_at = now(), revoked_reason = 'logout'
        WHERE refresh_token_hash = $1 AND revoked_at IS NULL RETURNING user_id`,
      [sha256(refreshToken)],
    );
    if (rows[0]) await this.security.record({ event: 'USER_LOGOUT', userId: rows[0].user_id, ip: ctx.ip });
  }

  async logoutAll(userId: number, ctx: RequestContext): Promise<number> {
    const { rowCount } = await this.db.query(
      `UPDATE sessions SET revoked_at = now(), revoked_reason = 'logout_all'
        WHERE user_id = $1 AND revoked_at IS NULL`,
      [userId],
    );
    await this.security.record({ event: 'USER_LOGOUT_ALL', userId, ip: ctx.ip, details: { count: rowCount } });
    return rowCount ?? 0;
  }

  // ── Mot de passe ────────────────────────────────────────────
  /** Réponse identique que le compte existe ou non (pas d'énumération). */
  async forgotPassword(email: string, ctx: RequestContext): Promise<void> {
    const user = await UserRepository.findByEmail(this.db, email);
    if (!user || user.status !== 'active') {
      await burnPasswordCheck(email);
      return;
    }

    const code = generateResetCode();
    await withTransaction(this.db, async (client) => {
      await client.query('UPDATE password_resets SET used_at = now() WHERE user_id = $1 AND used_at IS NULL', [
        user.id,
      ]);
      await client.query(
        `INSERT INTO password_resets (user_id, token_hash, ip, expires_at)
         VALUES ($1, $2, $3, now() + make_interval(mins => $4))`,
        [user.id, sha256(normalizeResetCode(code)), ctx.ip, RESET_CODE_TTL_MINUTES],
      );
    });
    await this.security.record({ event: 'PASSWORD_RESET_REQUESTED', userId: user.id, ip: ctx.ip });
    await this.mailer.sendPasswordReset(user.email, user.username, code, RESET_CODE_TTL_MINUTES);
  }

  async resetPassword(code: string, newPassword: string, ctx: RequestContext): Promise<void> {
    const hash = sha256(normalizeResetCode(code));
    const newHash = await hashPassword(newPassword);

    const userId = await withTransaction(this.db, async (client) => {
      const { rows } = await client.query<{ id: string; user_id: number }>(
        `UPDATE password_resets SET used_at = now()
          WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now()
          RETURNING id, user_id`,
        [hash],
      );
      const reset = rows[0];
      if (!reset) return null;
      await UserRepository.updatePassword(client, reset.user_id, newHash);
      await client.query(
        `UPDATE sessions SET revoked_at = now(), revoked_reason = 'password_reset'
          WHERE user_id = $1 AND revoked_at IS NULL`,
        [reset.user_id],
      );
      return reset.user_id;
    });

    if (!userId) {
      await this.security.record({ event: 'PASSWORD_RESET_INVALID', ip: ctx.ip });
      throw new AppError(400, 'INVALID_RESET_CODE', 'Code invalide ou expiré.');
    }
    await this.security.record({ event: 'PASSWORD_RESET_COMPLETED', userId, ip: ctx.ip });
  }

  /** Change le mot de passe et révoque toutes les autres sessions. */
  async changePassword(
    userId: number,
    currentSessionId: string,
    currentPassword: string,
    newPassword: string,
    ctx: RequestContext,
  ): Promise<void> {
    const user = await UserRepository.findById(this.db, userId);
    if (!user) throw Errors.unauthorized();
    if (!(await verifyPassword(user.password_hash, currentPassword))) {
      throw new AppError(400, 'INVALID_CREDENTIALS', 'Mot de passe actuel incorrect.', {
        fields: { currentPassword: 'Mot de passe actuel incorrect.' },
      });
    }
    const newHash = await hashPassword(newPassword);
    await withTransaction(this.db, async (client) => {
      await UserRepository.updatePassword(client, userId, newHash);
      await client.query(
        `UPDATE sessions SET revoked_at = now(), revoked_reason = 'password_changed'
          WHERE user_id = $1 AND id <> $2 AND revoked_at IS NULL`,
        [userId, currentSessionId],
      );
    });
    await this.security.record({ event: 'PASSWORD_CHANGED', userId, ip: ctx.ip });
  }
}
