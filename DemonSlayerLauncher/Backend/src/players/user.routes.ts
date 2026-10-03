import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { AuthService } from '../auth/auth.service.js';
import { requestContext } from '../auth/auth.routes.js';
import { requireAuth } from '../auth/guard.js';
import { Errors } from '../common/errors.js';
import { parse, passwordSchema } from '../common/validation.js';
import { permissionsFor } from '../security/rbac.js';
import { UserRepository, toPublicUser } from './user.repository.js';

const changePasswordBody = z.object({
  currentPassword: z.string().min(1, 'Mot de passe actuel requis.').max(128),
  newPassword: passwordSchema,
});

const sessionParams = z.object({ id: z.uuid('Session invalide.') });

export async function userRoutes(app: FastifyInstance, opts: { auth: AuthService; authRateLimit: number }) {
  // Toutes les routes /api/user/* exigent une session valide.
  app.addHook('preHandler', app.authenticate);

  app.get('/profile', async (request) => {
    const { userId, role } = requireAuth(request);
    const user = await UserRepository.findById(app.db, userId);
    if (!user) throw Errors.unauthorized();
    return { user: toPublicUser(user), permissions: permissionsFor(role) };
  });

  app.get('/sessions', async (request) => {
    const { userId, sessionId } = requireAuth(request);
    const { rows } = await app.db.query<{
      id: string;
      device_name: string | null;
      user_agent: string | null;
      ip: string | null;
      remember: boolean;
      created_at: Date;
      last_used_at: Date;
      expires_at: Date;
    }>(
      `SELECT id, device_name, user_agent, host(ip) AS ip, remember, created_at, last_used_at, expires_at
         FROM sessions
        WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > now()
        ORDER BY last_used_at DESC
        LIMIT 50`,
      [userId],
    );
    return {
      sessions: rows.map((s) => ({
        id: s.id,
        deviceName: s.device_name,
        userAgent: s.user_agent,
        ip: s.ip,
        remember: s.remember,
        createdAt: s.created_at.toISOString(),
        lastUsedAt: s.last_used_at.toISOString(),
        expiresAt: s.expires_at.toISOString(),
        current: s.id === sessionId,
      })),
    };
  });

  app.delete('/sessions/:id', async (request, reply) => {
    const { userId } = requireAuth(request);
    const { id } = parse(sessionParams, request.params);
    const { rowCount } = await app.db.query(
      `UPDATE sessions SET revoked_at = now(), revoked_reason = 'revoked_by_user'
        WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL`,
      [id, userId],
    );
    if (!rowCount) throw Errors.notFound('Session');
    await app.security.record({ event: 'SESSION_REVOKED', userId, ip: request.ip, details: { sessionId: id } });
    return reply.code(204).send();
  });

  app.post(
    '/password',
    { config: { rateLimit: { max: opts.authRateLimit, timeWindow: '1 minute' } } },
    async (request) => {
      const { userId, sessionId } = requireAuth(request);
      const body = parse(changePasswordBody, request.body);
      await opts.auth.changePassword(userId, sessionId, body.currentPassword, body.newPassword, requestContext(request));
      return { message: 'Mot de passe modifié. Vos autres appareils ont été déconnectés.' };
    },
  );
}
