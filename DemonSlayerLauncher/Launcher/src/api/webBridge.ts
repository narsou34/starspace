/**
 * Transport de DÉVELOPPEMENT pour prévisualiser l'interface dans un navigateur.
 * Il n'est jamais utilisé dans le .exe. Tokens en mémoire uniquement :
 * recharger la page = déconnexion.
 */
import type { LauncherError, User } from '../models/types';
import type { HttpMethod, LauncherBridge } from './bridge';

const BASE = (import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8080').replace(/\/$/, '');

interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
}

let tokens: { access: string; refresh: string } | null = null;

async function http<T>(method: HttpMethod, path: string, body?: unknown, bearer?: string): Promise<T> {
  let res: Response;
  try {
    res = await fetch(BASE + path, {
      method,
      headers: {
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw {
      code: 'NETWORK_ERROR',
      message: 'Impossible de joindre le serveur NDR | Demon Slayer. Vérifiez votre connexion internet.',
      status: null,
      details: null,
    } satisfies LauncherError;
  }
  if (res.status === 204) return undefined as T;
  const json = await res.json().catch(() => null);
  if (!res.ok) {
    throw {
      code: json?.error?.code ?? 'HTTP_ERROR',
      message: json?.error?.message ?? `Erreur inattendue du serveur (${res.status}).`,
      status: res.status,
      details: json?.error?.details ?? null,
    } satisfies LauncherError;
  }
  return json as T;
}

async function authenticate(path: string, body: object): Promise<User> {
  const res = await http<AuthResponse>('POST', path, { ...body, deviceName: 'Navigateur (dev)' });
  tokens = { access: res.accessToken, refresh: res.refreshToken };
  return res.user;
}

async function authed<T>(method: HttpMethod, path: string, body?: unknown): Promise<T> {
  if (!tokens) throw { code: 'SESSION_EXPIRED', message: 'Session expirée.', status: 401, details: null };
  try {
    return await http<T>(method, path, body, tokens.access);
  } catch (err) {
    if ((err as LauncherError).status !== 401) throw err;
    const res = await http<AuthResponse>('POST', '/api/auth/refresh', { refreshToken: tokens.refresh }).catch(
      (e) => {
        tokens = null;
        throw e;
      },
    );
    tokens = { access: res.accessToken, refresh: res.refreshToken };
    return http<T>(method, path, body, tokens.access);
  }
}

export const webBridge: LauncherBridge = {
  native: false,
  appInfo: async () => ({ version: '0.1.0-dev', apiBaseUrl: BASE, configSource: 'VITE_API_URL', os: 'web' }),
  ping: async () => {
    const start = performance.now();
    try {
      await http('GET', '/api/health');
      return { online: true, latencyMs: Math.round(performance.now() - start) };
    } catch {
      return { online: false, latencyMs: null };
    }
  },
  publicConfig: () => http('GET', '/api/launcher/config'),
  openExternal: async (url) => {
    window.open(url, '_blank', 'noopener');
  },
  login: (login, password, remember) => authenticate('/api/auth/login', { login, password, rememberMe: remember }),
  register: (username, email, password, remember) =>
    authenticate('/api/auth/register', { username, email, password, rememberMe: remember }),
  restore: async () => null,
  logout: async () => {
    if (tokens) await http('POST', '/api/auth/logout', { refreshToken: tokens.refresh }).catch(() => undefined);
    tokens = null;
  },
  logoutAll: async () => {
    await authed('POST', '/api/auth/logout-all');
    tokens = null;
  },
  forgotPassword: (email) => http('POST', '/api/auth/forgot-password', { email }),
  resetPassword: (code, newPassword) => http('POST', '/api/auth/reset-password', { code, newPassword }),
  request: authed,
};
