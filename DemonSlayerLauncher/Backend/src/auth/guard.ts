import type { FastifyReply, FastifyRequest } from 'fastify';
import { Errors } from '../common/errors.js';
import type { Db } from '../database/pool.js';
import { type Permission, type Role, hasPermission } from '../security/rbac.js';
import type { TokenService } from './tokens.js';

export interface AuthContext {
  userId: number;
  sessionId: string;
  role: Role;
}

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthContext;
  }
}

/**
 * preHandler d'authentification. Le JWT est vérifié, PUIS la session et le
 * compte sont relus en base : une session révoquée ou un compte suspendu
 * perd l'accès immédiatement, et le rôle provient toujours de la base.
 */
export function createAuthGuard(db: Db, tokens: TokenService) {
  return async function authenticate(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw Errors.unauthorized();

    const claims = await tokens.verifyAccess(header.slice(7).trim());
    if (!claims) throw Errors.sessionExpired();

    const { rows } = await db.query<{ role: Role; status: string; revoked_at: Date | null; expires_at: Date }>(
      `SELECT u.role, u.status, s.revoked_at, s.expires_at
         FROM sessions s JOIN users u ON u.id = s.user_id
        WHERE s.id = $1 AND s.user_id = $2`,
      [claims.sessionId, claims.userId],
    );
    const row = rows[0];
    if (!row || row.revoked_at || row.expires_at.getTime() <= Date.now()) throw Errors.sessionExpired();
    if (row.status !== 'active') throw Errors.suspended(row.status);

    request.auth = { userId: claims.userId, sessionId: claims.sessionId, role: row.role };
  };
}

/** À chaîner après `authenticate` : exige une permission RBAC. */
export function requirePermission(permission: Permission) {
  return async function checkPermission(request: FastifyRequest): Promise<void> {
    if (!request.auth) throw Errors.unauthorized();
    if (!hasPermission(request.auth.role, permission)) throw Errors.forbidden();
  };
}

export function requireAuth(request: FastifyRequest): AuthContext {
  if (!request.auth) throw Errors.unauthorized();
  return request.auth;
}
