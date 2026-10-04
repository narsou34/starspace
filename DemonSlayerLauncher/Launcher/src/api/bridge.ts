/**
 * Pont entre l'interface et le cœur Rust du launcher.
 *
 * Dans le .exe (Tauri), chaque appel est une commande Rust : les tokens
 * restent côté Rust / Windows Credential Manager et ne sont jamais
 * exposés au JavaScript.
 *
 * En mode navigateur (`npm run dev` sans Tauri, pour travailler le design),
 * un transport HTTP de développement garde les tokens en mémoire uniquement.
 */
import type { ApiPing, AppInfo, LauncherError, PublicConfig, User } from '../models/types';
import { createDemoBridge } from './demoBridge';
import { webBridge } from './webBridge';

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export interface LauncherBridge {
  readonly native: boolean;
  appInfo(): Promise<AppInfo>;
  ping(): Promise<ApiPing>;
  publicConfig(): Promise<PublicConfig>;
  openExternal(url: string): Promise<void>;
  login(login: string, password: string, remember: boolean): Promise<User>;
  register(username: string, email: string, password: string, remember: boolean): Promise<User>;
  restore(): Promise<User | null>;
  logout(): Promise<void>;
  logoutAll(): Promise<void>;
  forgotPassword(email: string): Promise<{ message: string }>;
  resetPassword(code: string, newPassword: string): Promise<{ message: string }>;
  request<T>(method: HttpMethod, path: string, body?: unknown): Promise<T>;
}

export const isTauri = typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;

async function nativeInvoke<T>(cmd: string, args?: Record<string, unknown>): Promise<T> {
  const { invoke } = await import('@tauri-apps/api/core');
  try {
    return await invoke<T>(cmd, args);
  } catch (err) {
    // Rust renvoie toujours { code, message, status, details }.
    if (typeof err === 'string') {
      throw { code: 'INTERNAL_ERROR', message: err, status: null, details: null } satisfies LauncherError;
    }
    throw err;
  }
}

const tauriBridge: LauncherBridge = {
  native: true,
  appInfo: () => nativeInvoke('app_info'),
  ping: () => nativeInvoke('api_ping'),
  publicConfig: () => nativeInvoke('launcher_public_config'),
  openExternal: (url) => nativeInvoke('open_external', { url }),
  login: (login, password, remember) => nativeInvoke('auth_login', { login, password, remember }),
  register: (username, email, password, remember) =>
    nativeInvoke('auth_register', { username, email, password, remember }),
  restore: () => nativeInvoke('auth_restore'),
  logout: () => nativeInvoke('auth_logout'),
  logoutAll: () => nativeInvoke('auth_logout_all'),
  forgotPassword: (email) => nativeInvoke('auth_forgot_password', { email }),
  resetPassword: (code, newPassword) => nativeInvoke('auth_reset_password', { code, newPassword }),
  request: (method, path, body) => nativeInvoke('api_request', { method, path, body: body ?? null }),
};

const realBridge: LauncherBridge = isTauri ? tauriBridge : webBridge;
const demoBridge = createDemoBridge(realBridge);
let active: LauncherBridge = realBridge;

/** Mode aperçu : uniquement si le build l'autorise (VITE_DEMO_MODE=true) ou en développement. */
export const DEMO_AVAILABLE = import.meta.env.DEV || import.meta.env.VITE_DEMO_MODE === 'true';

export function setDemoMode(on: boolean): void {
  active = on && DEMO_AVAILABLE ? demoBridge : realBridge;
}

export function isDemoMode(): boolean {
  return active === demoBridge;
}

/** Point d'entrée unique : délègue au transport actif (réel ou aperçu). */
export const bridge: LauncherBridge = new Proxy({} as LauncherBridge, {
  get: (_target, prop) => active[prop as keyof LauncherBridge],
});
