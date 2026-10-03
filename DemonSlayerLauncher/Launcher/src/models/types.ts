export type Role = 'player' | 'helper' | 'moderator' | 'admin' | 'superadmin';
export type UserStatus = 'active' | 'suspended' | 'banned';

export interface User {
  id: number;
  username: string;
  email: string;
  role: Role;
  status: UserStatus;
  avatarUrl: string | null;
  createdAt: string;
  lastLoginAt: string | null;
}

export interface Profile {
  user: User;
  permissions: string[];
}

export interface AccountSession {
  id: string;
  deviceName: string | null;
  userAgent: string | null;
  ip: string | null;
  remember: boolean;
  createdAt: string;
  lastUsedAt: string;
  expiresAt: string;
  current: boolean;
}

export interface AppInfo {
  version: string;
  apiBaseUrl: string;
  configSource: string;
  os: string;
}

export interface ApiPing {
  online: boolean;
  latencyMs: number | null;
}

export interface PublicConfig {
  apiVersion: number;
  serverName: string;
  links: { discord: string | null; website: string | null; supportEmail: string | null };
  features: { registration: boolean; discordOAuth: boolean; steamLogin: boolean };
}

/** Erreur normalisée renvoyée par Rust (ou par le transport navigateur). */
export interface LauncherError {
  code: string;
  message: string;
  status: number | null;
  details: { fields?: Record<string, string>; retryAfterSeconds?: number } | null;
}

export function isLauncherError(value: unknown): value is LauncherError {
  return typeof value === 'object' && value !== null && 'code' in value && 'message' in value;
}

export function errorMessage(err: unknown): string {
  if (isLauncherError(err)) return err.message;
  if (err instanceof Error) return err.message;
  return 'Une erreur inattendue est survenue.';
}

export const ROLE_LABELS: Record<Role, string> = {
  player: 'Joueur',
  helper: 'Helper',
  moderator: 'Modérateur',
  admin: 'Administrateur',
  superadmin: 'Fondateur',
};
