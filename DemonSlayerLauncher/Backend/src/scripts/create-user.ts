/**
 * Crée un compte depuis la ligne de commande (ex. premier administrateur).
 *
 *   npm run user:create -- --username Narsou --email narsou@example.com --role superadmin
 *
 * Le mot de passe est lu depuis la variable CREATE_USER_PASSWORD, sinon un
 * mot de passe aléatoire est généré et affiché UNE seule fois.
 */
import 'dotenv/config';
import { randomBytes } from 'node:crypto';
import { parseArgs } from 'node:util';
import { hashPassword } from '../auth/password.js';
import { emailSchema, passwordSchema, usernameSchema } from '../common/validation.js';
import { loadEnv } from '../config/env.js';
import { createPool } from '../database/pool.js';
import { UserRepository } from '../players/user.repository.js';
import { isRole } from '../security/rbac.js';

const { values } = parseArgs({
  options: {
    username: { type: 'string' },
    email: { type: 'string' },
    role: { type: 'string', default: 'player' },
  },
});

const role = values.role ?? 'player';
if (!isRole(role)) {
  console.error(`Rôle invalide : ${role}`);
  process.exit(1);
}

const username = usernameSchema.parse(values.username);
const email = emailSchema.parse(values.email);
const generated = !process.env.CREATE_USER_PASSWORD;
const password = passwordSchema.parse(process.env.CREATE_USER_PASSWORD ?? `${randomBytes(12).toString('base64url')}7a`);

const env = loadEnv();
const db = createPool(env.DATABASE_URL);
try {
  const user = await UserRepository.create(db, { username, email, passwordHash: await hashPassword(password), role });
  console.log(`Compte créé : #${user.id} ${user.username} (${user.role})`);
  if (generated) console.log(`Mot de passe généré (à changer) : ${password}`);
} catch (err) {
  console.error('Création impossible :', (err as Error).message);
  process.exitCode = 1;
} finally {
  await db.end();
}
