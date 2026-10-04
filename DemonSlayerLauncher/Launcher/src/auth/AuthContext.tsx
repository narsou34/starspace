import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';
import { bridge, isDemoMode, setDemoMode } from '../api/bridge';
import type { User } from '../models/types';
import { isLauncherError } from '../models/types';

interface AuthState {
  user: User | null;
  login(login: string, password: string, remember: boolean): Promise<User>;
  register(username: string, email: string, password: string, remember: boolean): Promise<User>;
  /** Tente de restaurer la session « Rester connecté ». */
  restore(): Promise<User | null>;
  logout(): Promise<void>;
  logoutAll(): Promise<void>;
  setUser(user: User): void;
  /** Ouvre le launcher en mode aperçu (sans serveur). */
  enterDemo(): Promise<void>;
  /** À appeler quand une requête révèle que la session n'est plus valable. */
  handleError(err: unknown): void;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = useCallback(async (id: string, password: string, remember: boolean) => {
    const u = await bridge.login(id, password, remember);
    setUser(u);
    return u;
  }, []);

  const register = useCallback(async (username: string, email: string, password: string, remember: boolean) => {
    const u = await bridge.register(username, email, password, remember);
    setUser(u);
    return u;
  }, []);

  // Une seule restauration en vol à la fois (StrictMode exécute les effets deux fois).
  const restoring = useRef<Promise<User | null> | null>(null);
  const restore = useCallback(async () => {
    restoring.current ??= bridge.restore().finally(() => {
      restoring.current = null;
    });
    const u = await restoring.current;
    setUser(u);
    return u;
  }, []);

  const logout = useCallback(async () => {
    await bridge.logout();
    setDemoMode(false);
    setUser(null);
  }, []);

  const logoutAll = useCallback(async () => {
    await bridge.logoutAll();
    setDemoMode(false);
    setUser(null);
  }, []);

  const enterDemo = useCallback(async () => {
    setDemoMode(true);
    if (!isDemoMode()) return;
    setUser(await bridge.login('Narsou', '', false));
  }, []);

  const handleError = useCallback((err: unknown) => {
    if (isLauncherError(err) && (err.code === 'SESSION_EXPIRED' || err.code === 'ACCOUNT_SUSPENDED')) {
      setDemoMode(false);
      setUser(null);
    }
  }, []);

  const value = useMemo(
    () => ({ user, login, register, restore, logout, logoutAll, setUser, handleError, enterDemo }),
    [user, login, register, restore, logout, logoutAll, handleError, enterDemo],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit être utilisé dans <AuthProvider>');
  return ctx;
}
