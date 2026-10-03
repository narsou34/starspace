import { useEffect, useRef, useState } from 'react';
import { bridge } from './api/bridge';
import { useAuth } from './auth/AuthContext';
import { Background } from './components/Background';
import { TitleBar } from './components/TitleBar';
import { useToast } from './components/Toasts';
import { errorMessage, type AppInfo, type PublicConfig } from './models/types';
import { AuthScreen } from './views/auth/AuthScreen';
import { BootView } from './views/BootView';
import { Shell } from './views/Shell';

type Phase = 'boot' | 'ready';

export function App() {
  const { user, restore } = useAuth();
  const toast = useToast();
  const [phase, setPhase] = useState<Phase>('boot');
  const [info, setInfo] = useState<AppInfo | null>(null);
  const [config, setConfig] = useState<PublicConfig | null>(null);
  const previousUser = useRef<number | null>(null);

  // Démarrage : infos launcher, configuration publique, session mémorisée.
  useEffect(() => {
    let alive = true;
    (async () => {
      const started = performance.now();
      bridge.appInfo().then((i) => alive && setInfo(i)).catch(() => undefined);
      bridge.publicConfig().then((c) => alive && setConfig(c)).catch(() => undefined);
      try {
        await restore();
      } catch (err) {
        toast.show('error', 'Connexion impossible', errorMessage(err));
      }
      // Affichage minimal de l'écran de démarrage pour éviter un flash.
      const elapsed = performance.now() - started;
      if (elapsed < 700) await new Promise((r) => setTimeout(r, 700 - elapsed));
      if (alive) setPhase('ready');
    })();
    return () => {
      alive = false;
    };
  }, [restore, toast]);

  // Message d'accueil à chaque nouvelle connexion.
  useEffect(() => {
    if (user && previousUser.current !== user.id && phase === 'ready') {
      toast.show('success', `Bienvenue, ${user.username}.`, 'Votre souffle est prêt.');
    }
    previousUser.current = user?.id ?? null;
  }, [user, phase, toast]);

  const variant = phase === 'boot' ? 'boot' : user ? 'app' : 'auth';

  return (
    <div className="app">
      <Background variant={variant} />
      <TitleBar />
      <div className="app__body">
        {phase === 'boot' ? (
          <BootView message="Connexion au quartier général du Corps…" />
        ) : user ? (
          <Shell info={info} config={config} />
        ) : (
          <AuthScreen info={info} config={config} />
        )}
      </div>
    </div>
  );
}
