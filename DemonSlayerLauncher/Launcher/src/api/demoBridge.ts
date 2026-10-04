/**
 * MODE APERÇU (démonstration du design, sans serveur).
 *
 * Disponible uniquement dans les builds compilés avec VITE_DEMO_MODE=true
 * (ou en développement). Aucune donnée n'est envoyée : le compte, les
 * sessions et le mot de passe sont simulés en mémoire, et l'interface
 * affiche clairement « Mode aperçu ».
 */
import type { AccountSession, LauncherError, PublicConfig, User } from '../models/types';
import type { HttpMethod, LauncherBridge } from './bridge';

const demoError = (message: string): LauncherError => ({ code: 'DEMO_MODE', message, status: null, details: null });

const FALLBACK_CONFIG: PublicConfig = {
  apiVersion: 1,
  serverName: 'NDR | Demon Slayer',
  links: { discord: null, website: null, supportEmail: null },
  features: { registration: true, discordOAuth: false, steamLogin: false },
};

export function createDemoBridge(real: LauncherBridge): LauncherBridge {
  let user: User | null = null;
  const now = () => new Date().toISOString();
  let sessions: AccountSession[] = [];

  const signIn = (username: string, email?: string): User => {
    const name = /^[A-Za-z0-9_.-]{3,20}$/.test(username) ? username : 'Narsou';
    user = {
      id: 10000,
      username: name,
      email: email ?? `${name.toLowerCase()}@exemple.fr`,
      role: 'player',
      status: 'active',
      avatarUrl: null,
      createdAt: '2026-09-12T18:00:00.000Z',
      lastLoginAt: now(),
    };
    sessions = [
      { id: 'demo-1', deviceName: 'Ce PC (aperçu)', userAgent: null, ip: '127.0.0.1', remember: true, createdAt: now(), lastUsedAt: now(), expiresAt: now(), current: true },
      { id: 'demo-2', deviceName: 'Launcher · PC-SALON', userAgent: null, ip: '192.168.1.24', remember: true, createdAt: now(), lastUsedAt: '2026-10-02T20:14:00.000Z', expiresAt: now(), current: false },
    ];
    return user;
  };

  return {
    native: real.native,
    appInfo: () => real.appInfo(),
    ping: () => real.ping(),
    publicConfig: () => real.publicConfig().catch(() => FALLBACK_CONFIG),
    openExternal: (url) => real.openExternal(url),
    login: async (login) => signIn(login.includes('@') ? 'Narsou' : login),
    register: async (username, email) => signIn(username, email),
    restore: async () => null,
    logout: async () => {
      user = null;
    },
    logoutAll: async () => {
      user = null;
    },
    forgotPassword: async () => ({ message: 'Mode aperçu : aucun e-mail n’est envoyé.' }),
    resetPassword: async () => ({ message: 'Mode aperçu : mot de passe non modifié.' }),
    request: async <T,>(method: HttpMethod, path: string): Promise<T> => {
      if (!user) throw { ...demoError('Session terminée.'), code: 'SESSION_EXPIRED' };
      if (method === 'GET' && path === '/api/user/profile') return { user, permissions: [] } as T;
      if (method === 'GET' && path === '/api/user/sessions') return { sessions } as T;
      if (method === 'DELETE' && path.startsWith('/api/user/sessions/')) {
        const id = decodeURIComponent(path.split('/').pop()!);
        sessions = sessions.filter((s) => s.id !== id);
        return undefined as T;
      }
      if (method === 'POST' && path === '/api/user/password') {
        return { message: 'Mode aperçu : le mot de passe n’est pas réellement modifié.' } as T;
      }
      throw demoError('Indisponible en mode aperçu.');
    },
  };
}
