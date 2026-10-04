import { createContext, useContext } from 'react';
import type { ApiPing, AppInfo, PublicConfig } from '../models/types';
import type { ViewId } from './navigation';

export interface LauncherCtx {
  info: AppInfo | null;
  config: PublicConfig | null;
  ping: ApiPing | null;
  navigate: (view: ViewId) => void;
}

export const LauncherContext = createContext<LauncherCtx | null>(null);

export function useLauncher(): LauncherCtx {
  const ctx = useContext(LauncherContext);
  if (!ctx) throw new Error('useLauncher doit être utilisé dans le Shell');
  return ctx;
}
