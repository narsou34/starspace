import type { FastifyInstance, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { deviceNameSchema, emailSchema, parse, passwordSchema, usernameSchema } from '../common/validation.js';
import type { AuthService, RequestContext } from './auth.service.js';
import { requireAuth } from './guard.js';

export function requestContext(request: FastifyRequest, deviceName?: string): RequestContext {
  return {
    ip: request.ip,
    userAgent: request.headers['user-agent'],
    deviceName,
  };
}

const registerBody = z.object({
  username: usernameSchema,
  email: emailSchema,
  password: passwordSchema,
  rememberMe: z.boolean().default(false),
  deviceName: deviceNameSchema,
});

const loginBody = z.object({
  login: z.string({ error: 'Identifiant requis.' }).trim().min(1, 'Identifiant requis.').max(254),
  password: z.string({ error: 'Mot de passe requis.' }).min(1, 'Mot de passe requis.').max(128),
  rememberMe: z.boolean().default(false),
  deviceName: deviceNameSchema,
});

const refreshBody = z.object({
  refreshToken: z.string().min(20).max(200),
});

const forgotBody = z.object({ email: emailSchema });

const resetBody = z.object({
  code: z.string({ error: 'Code requis.' }).trim().min(12, 'Code invalide.').max(32, 'Code invalide.'),
  newPassword: passwordSchema,
});

export async function authRoutes(app: FastifyInstance, opts: { auth: AuthService; authRateLimit: number }) {
  const { auth } = opts;
  const strict = { rateLimit: { max: opts.authRateLimit, timeWindow: '1 minute' } };

  app.post('/register', { config: strict }, async (request, reply) => {
    const body = parse(registerBody, request.body);
    const result = await auth.register(body, requestContext(request, body.deviceName));
    return reply.code(201).send(result);
  });

  app.post('/login', { config: strict }, async (request) => {
    const body = parse(loginBody, request.body);
    return auth.login(body, requestContext(request, body.deviceName));
  });

  app.post('/refresh', { config: { rateLimit: { max: opts.authRateLimit * 3, timeWindow: '1 minute' } } }, async (request) => {
    const body = parse(refreshBody, request.body);
    return auth.refresh(body.refreshToken, requestContext(request));
  });

  app.post('/logout', async (request, reply) => {
    const body = parse(refreshBody, request.body);
    await auth.logout(body.refreshToken, requestContext(request));
    return reply.code(204).send();
  });

  app.post('/logout-all', { preHandler: app.authenticate }, async (request) => {
    const { userId } = requireAuth(request);
    const revoked = await auth.logoutAll(userId, requestContext(request));
    return { revoked };
  });

  app.post('/forgot-password', { config: strict }, async (request) => {
    const body = parse(forgotBody, request.body);
    await auth.forgotPassword(body.email, requestContext(request));
    return {
      message: 'Si un compte correspond à cette adresse, un code de réinitialisation vient d’être envoyé.',
    };
  });

  app.post('/reset-password', { config: strict }, async (request) => {
    const body = parse(resetBody, request.body);
    await auth.resetPassword(body.code, body.newPassword, requestContext(request));
    return { message: 'Mot de passe modifié. Vous pouvez maintenant vous connecter.' };
  });
}
