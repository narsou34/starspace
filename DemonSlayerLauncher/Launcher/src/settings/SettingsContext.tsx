import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { ThemeId } from '../theme/themes';

export type MotionLevel = 'high' | 'low' | 'off';

export interface LauncherSettings {
  /** 'auto' = le thème suit la page ; sinon thème imposé */
  theme: 'auto' | ThemeId;
  motion: MotionLevel;
  parallax: boolean;
  particles: boolean;
  notifications: boolean;
}

const DEFAULTS: LauncherSettings = {
  theme: 'auto',
  motion: 'high',
  parallax: true,
  particles: true,
  notifications: true,
};

const KEY = 'ndr.launcher.settings.v1';

function load(): LauncherSettings {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? { ...DEFAULTS, ...JSON.parse(raw) } : DEFAULTS;
  } catch {
    return DEFAULTS;
  }
}

interface SettingsApi {
  settings: LauncherSettings;
  update(patch: Partial<LauncherSettings>): void;
  reset(): void;
  /** Animations effectives (préférence système « réduire les animations » incluse). */
  motion: MotionLevel;
}

const SettingsContext = createContext<SettingsApi | null>(null);

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<LauncherSettings>(load);
  const [systemReduced, setSystemReduced] = useState(
    () => typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches,
  );

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    const on = () => setSystemReduced(mq.matches);
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(settings));
    } catch {
      /* stockage indisponible : réglages valables pour la session */
    }
  }, [settings]);

  const update = useCallback((patch: Partial<LauncherSettings>) => setSettings((s) => ({ ...s, ...patch })), []);
  const reset = useCallback(() => setSettings(DEFAULTS), []);
  const motion: MotionLevel = systemReduced ? 'off' : settings.motion;

  useEffect(() => {
    document.documentElement.dataset.motion = motion;
  }, [motion]);

  const api = useMemo(() => ({ settings, update, reset, motion }), [settings, update, reset, motion]);
  return <SettingsContext.Provider value={api}>{children}</SettingsContext.Provider>;
}

export function useSettings(): SettingsApi {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error('useSettings doit être utilisé dans <SettingsProvider>');
  return ctx;
}
