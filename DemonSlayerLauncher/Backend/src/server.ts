import 'dotenv/config';
import { buildApp } from './app.js';
import { loadEnv } from './config/env.js';
import { runMigrations } from './database/migrate.js';
import { createPool } from './database/pool.js';

const env = loadEnv();
const db = createPool(env.DATABASE_URL);

if (env.AUTO_MIGRATE) {
  await runMigrations(db, (m) => console.log(m));
}

const app = await buildApp({ env, db });

if (env.NODE_ENV === 'production' && !env.TRUST_PROXY) {
  app.log.warn('Production sans TRUST_PROXY : placez l’API derrière un reverse proxy HTTPS.');
}

const shutdown = async (signal: string) => {
  app.log.info(`${signal} reçu, arrêt en cours…`);
  await app.close();
  await db.end();
  process.exit(0);
};
process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));

try {
  await app.listen({ host: env.HOST, port: env.PORT });
} catch (err) {
  app.log.error(err);
  await db.end();
  process.exit(1);
}
