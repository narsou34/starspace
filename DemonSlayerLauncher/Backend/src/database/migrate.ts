import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import type { Db } from './pool.js';

// Fonctionne depuis src/ (tsx) comme depuis dist/ (node) : Backend/migrations
const MIGRATIONS_DIR = fileURLToPath(new URL('../../migrations/', import.meta.url));
const LOCK_ID = 74_210_001;

export interface MigrationResult {
  applied: string[];
}

export async function runMigrations(db: Db, log: (msg: string) => void = () => {}): Promise<MigrationResult> {
  const client = await db.connect();
  const applied: string[] = [];
  try {
    // Verrou consultatif : deux instances de l'API ne migrent jamais en même temps.
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_ID]);
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name        TEXT PRIMARY KEY,
        applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);

    const done = new Set(
      (await client.query<{ name: string }>('SELECT name FROM schema_migrations')).rows.map((r) => r.name),
    );
    const files = (await readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith('.sql')).sort();

    for (const file of files) {
      if (done.has(file)) continue;
      const sql = await readFile(new URL(file, `file://${MIGRATIONS_DIR}`), 'utf8');
      log(`Migration ${file}…`);
      try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
        await client.query('COMMIT');
        applied.push(file);
      } catch (err) {
        await client.query('ROLLBACK');
        throw new Error(`Échec de la migration ${file} : ${(err as Error).message}`);
      }
    }
  } finally {
    await client.query('SELECT pg_advisory_unlock($1)', [LOCK_ID]).catch(() => undefined);
    client.release();
  }
  return { applied };
}

// Exécution directe : `npm run migrate`
const isMain = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const { config } = await import('dotenv');
  config();
  const { loadEnv } = await import('../config/env.js');
  const { createPool } = await import('./pool.js');
  const env = loadEnv();
  const db = createPool(env.DATABASE_URL);
  try {
    const { applied } = await runMigrations(db, (m) => console.log(m));
    console.log(applied.length ? `${applied.length} migration(s) appliquée(s).` : 'Base déjà à jour.');
  } catch (err) {
    console.error((err as Error).message);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
}
