import { useEffect, useState } from 'react';
import { bridge } from '../api/bridge';
import type { ApiPing } from '../models/types';

/** Indicateur de disponibilité de l'API (rafraîchi toutes les 60 s). */
export function useApiPing(intervalMs = 60_000) {
  const [ping, setPing] = useState<ApiPing | null>(null);

  useEffect(() => {
    let alive = true;
    const run = () =>
      bridge
        .ping()
        .then((p) => alive && setPing(p))
        .catch(() => alive && setPing({ online: false, latencyMs: null }));
    void run();
    const timer = window.setInterval(() => {
      if (!document.hidden) void run();
    }, intervalMs);
    return () => {
      alive = false;
      window.clearInterval(timer);
    };
  }, [intervalMs]);

  return ping;
}

export function ApiStatus({ ping, label = 'Services' }: { ping: ApiPing | null; label?: string }) {
  const state = ping === null ? 'pending' : ping.online ? 'online' : 'offline';
  return (
    <span className={`status-dot status-dot--${state}`}>
      <i />
      {label}{' '}
      {state === 'pending' ? 'vérification…' : state === 'online' ? `en ligne · ${ping?.latencyMs ?? '—'} ms` : 'hors ligne'}
    </span>
  );
}
