import type { Db, DbClient } from '../database/pool.js';
import type { Role } from '../security/rbac.js';

export type UserStatus = 'active' | 'suspended' | 'banned';

export interface UserRow {
  id: number;
  username: string;
  email: string;
  password_hash: string;
  role: Role;
  status: UserStatus;
  avatar_url: string | null;
  last_login_at: Date | null;
  created_at: Date;
}

/** Représentation publique d'un compte (jamais de hash ni de donnée interne). */
export interface PublicUser {
  id: number;
  username: string;
  email: string;
  role: Role;
  status: UserStatus;
  avatarUrl: string | null;
  createdAt: string;
  lastLoginAt: string | null;
}

export function toPublicUser(row: UserRow): PublicUser {
  return {
    id: row.id,
    username: row.username,
    email: row.email,
    role: row.role,
    status: row.status,
    avatarUrl: row.avatar_url,
    createdAt: row.created_at.toISOString(),
    lastLoginAt: row.last_login_at ? row.last_login_at.toISOString() : null,
  };
}

const COLUMNS = 'id, username, email, password_hash, role, status, avatar_url, last_login_at, created_at';

type Queryable = Db | DbClient;

export const UserRepository = {
  async findById(db: Queryable, id: number): Promise<UserRow | null> {
    const { rows } = await db.query<UserRow>(`SELECT ${COLUMNS} FROM users WHERE id = $1`, [id]);
    return rows[0] ?? null;
  },

  /** Recherche par pseudo OU e-mail, insensible à la casse. */
  async findByLogin(db: Queryable, login: string): Promise<UserRow | null> {
    const { rows } = await db.query<UserRow>(
      `SELECT ${COLUMNS} FROM users WHERE lower(username) = lower($1) OR lower(email) = lower($1) LIMIT 1`,
      [login],
    );
    return rows[0] ?? null;
  },

  async findByEmail(db: Queryable, email: string): Promise<UserRow | null> {
    const { rows } = await db.query<UserRow>(`SELECT ${COLUMNS} FROM users WHERE lower(email) = lower($1)`, [
      email,
    ]);
    return rows[0] ?? null;
  },

  async create(
    db: Queryable,
    input: { username: string; email: string; passwordHash: string; role?: Role },
  ): Promise<UserRow> {
    const { rows } = await db.query<UserRow>(
      `INSERT INTO users (username, email, password_hash, role)
       VALUES ($1, $2, $3, $4) RETURNING ${COLUMNS}`,
      [input.username, input.email, input.passwordHash, input.role ?? 'player'],
    );
    return rows[0]!;
  },

  async touchLogin(db: Queryable, id: number): Promise<void> {
    await db.query('UPDATE users SET last_login_at = now() WHERE id = $1', [id]);
  },

  async updatePassword(db: Queryable, id: number, passwordHash: string): Promise<void> {
    await db.query('UPDATE users SET password_hash = $2, password_changed_at = now() WHERE id = $1', [
      id,
      passwordHash,
    ]);
  },
};
