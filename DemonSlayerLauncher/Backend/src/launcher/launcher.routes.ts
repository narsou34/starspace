import type { FastifyInstance } from 'fastify';
import type { Env } from '../config/env.js';

/**
 * Informations publiques nécessaires au launcher. Rien de sensible :
 * ces valeurs proviennent des variables PUBLIC_* et ne sont jamais
 * codées en dur dans l'exécutable.
 */
export async function launcherRoutes(app: FastifyInstance, opts: { env: Env }) {
  const { env } = opts;
  app.get('/config', async (_request, reply) => {
    reply.header('Cache-Control', 'public, max-age=300');
    return {
      apiVersion: 1,
      serverName: env.PUBLIC_SERVER_NAME,
      links: {
        discord: env.PUBLIC_DISCORD_URL ?? null,
        website: env.PUBLIC_WEBSITE_URL ?? null,
        supportEmail: env.PUBLIC_SUPPORT_EMAIL ?? null,
      },
      features: {
        registration: env.REGISTRATION_ENABLED,
        discordOAuth: false,
        steamLogin: false,
      },
    };
  });
}
