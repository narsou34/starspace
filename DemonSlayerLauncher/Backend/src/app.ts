import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyInstance, type FastifyReply, type FastifyRequest } from 'fastify';
import { authRoutes } from './auth/auth.routes.js';
import { AuthService } from './auth/auth.service.js';
import { createAuthGuard } from './auth/guard.js';
import { TokenService } from './auth/tokens.js';
import { AppError } from './common/errors.js';
import type { Env } from './config/env.js';
import type { Db } from './database/pool.js';
import { launcherRoutes } from './launcher/launcher.routes.js';
import { type Mailer, createMailer } from './mail/mailer.js';
import { userRoutes } from './players/user.routes.js';
import { SecurityLogger } from './security/securityLog.js';

declare module 'fastify' {
  interface FastifyInstance {
    db: Db;
    security: SecurityLogger;
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

export interface BuildOptions {
  env: Env;
  db: Db;
  mailer?: Mailer;
}

export async function buildApp({ env, db, mailer }: BuildOptions): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: env.LOG_LEVEL,
      // Les en-têtes d'authentification et les corps ne sont jamais journalisés.
      redact: ['req.headers.authorization', 'req.headers.cookie'],
    },
    trustProxy: env.TRUST_PROXY,
    bodyLimit: 256 * 1024,
  });

  const tokens = new TokenService(env);
  const security = new SecurityLogger(db, app.log);
  const auth = new AuthService(db, env, tokens, mailer ?? createMailer(env, app.log), security);

  app.decorate('db', db);
  app.decorate('security', security);
  app.decorate('authenticate', createAuthGuard(db, tokens));

  await app.register(helmet, { global: true });
  if (env.CORS_ORIGINS.length > 0) {
    await app.register(cors, {
      origin: env.CORS_ORIGINS,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      maxAge: 600,
    });
  }
  await app.register(rateLimit, {
    global: true,
    max: env.GLOBAL_RATE_LIMIT_PER_MINUTE,
    timeWindow: '1 minute',
    errorResponseBuilder: (_req, context) =>
      new AppError(429, 'RATE_LIMITED', 'Trop de requêtes. Patientez quelques instants.', {
        retryAfterSeconds: Math.ceil(context.ttl / 1000),
      }),
  });

  app.setErrorHandler((error: Error & { statusCode?: number; validation?: unknown }, request, reply) => {
    if (error instanceof AppError) {
      if (error.statusCode === 429 && typeof error.details?.retryAfterSeconds === 'number') {
        reply.header('Retry-After', String(error.details.retryAfterSeconds));
      }
      return reply.code(error.statusCode).send({
        error: { code: error.code, message: error.message, ...(error.details ? { details: error.details } : {}) },
      });
    }
    // Erreurs Fastify (JSON mal formé, corps trop gros…)
    if (error.statusCode && error.statusCode >= 400 && error.statusCode < 500) {
      return reply.code(error.statusCode).send({
        error: { code: 'VALIDATION_ERROR', message: 'Requête invalide.' },
      });
    }
    request.log.error({ err: error }, 'Erreur interne');
    return reply.code(500).send({
      error: { code: 'INTERNAL_ERROR', message: 'Une erreur interne est survenue. Réessayez plus tard.' },
    });
  });

  app.setNotFoundHandler((_request, reply) =>
    reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Route introuvable.' } }),
  );

  app.get('/api/health', async () => {
    await db.query('SELECT 1');
    return { status: 'ok', time: new Date().toISOString() };
  });

  const routeOpts = { auth, authRateLimit: env.AUTH_RATE_LIMIT_PER_MINUTE };
  await app.register(authRoutes, { ...routeOpts, prefix: '/api/auth' });
  await app.register(userRoutes, { ...routeOpts, prefix: '/api/user' });
  await app.register(launcherRoutes, { env, prefix: '/api/launcher' });

  return app;
}
