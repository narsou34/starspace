import type { FastifyBaseLogger } from 'fastify';
import type { Db, DbClient } from '../database/pool.js';

export type SecurityEvent =
  | 'USER_REGISTER'
  | 'USER_LOGIN'
  | 'LOGIN_FAILED'
  | 'LOGIN_BLOCKED'
  | 'LOGIN_DENIED_SUSPENDED'
  | 'USER_LOGOUT'
  | 'USER_LOGOUT_ALL'
  | 'SESSION_REFRESH_REUSE'
  | 'SESSION_REVOKED'
  | 'PASSWORD_CHANGED'
  | 'PASSWORD_RESET_REQUESTED'
  | 'PASSWORD_RESET_COMPLETED'
  | 'PASSWORD_RESET_INVALID';

export interface SecurityLogEntry {
  event: SecurityEvent;
  userId?: number | null;
  ip?: string | null;
  details?: Record<string, unknown>;
}

/**
 * Journal de sécurité : écrit en base (table security_logs) et dans les logs
 * applicatifs. Une erreur d'écriture du journal ne doit jamais bloquer l'action.
 */
export class SecurityLogger {
  constructor(
    private readonly db: Db,
    private readonly log: FastifyBaseLogger,
  ) {}

  async record(entry: SecurityLogEntry, client?: DbClient): Promise<void> {
    const { event, userId = null, ip = null, details = {} } = entry;
    this.log.info({ security: true, event, userId, ip, ...details }, `SECURITY ${event}`);
    try {
      await (client ?? this.db).query(
        'INSERT INTO security_logs (event, user_id, ip, details) VALUES ($1, $2, $3, $4)',
        [event, userId, ip, JSON.stringify(details)],
      );
    } catch (err) {
      this.log.error({ err, event }, "Impossible d'écrire le journal de sécurité");
    }
  }
}
