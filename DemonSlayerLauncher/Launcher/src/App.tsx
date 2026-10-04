import { useCallback, useEffect, useRef, useState } from 'react';
import { bridge } from './api/bridge';
import { useAuth } from './auth/AuthContext';
import { TitleBar } from './components/TitleBar';
import { useToast } from './components/Toasts';
import { errorMessage, type AppInfo, type PublicConfig } from './models/types';
import { Backdrop } from './scenery/Backdrop';
import { useSettings } from './settings/SettingsContext';
import { themeVars } from './theme/themes';
import { AuthScreen } from './views/auth/AuthScreen';
import { BootView } from './views/BootView';
import { VIEWS, type ViewId } from './views/navigation';
import { Shell } from './views/Shell';

type Phase = 'boot' | 'ready';

export function App() {
  const { user, restore } = useAuth();
  const toast = useToast();
  const { settings } = useSettings();
  const [phase, setPhase] = useState<Phase>('boot');
  const [info, setInfo] = useState<AppInfo | null>(null);
  const [config, setConfig] = useState<PublicConfig | null>(null);
  const [view, setView] = useState<ViewId>('home');
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
      const elapsed = performance.now() - started;
      if (elapsed < 900) await new Promise((r) => setTimeout(r, 900 - elapsed));
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
    if (!user) setView('home');
    previousUser.current = user?.id ?? null;
  }, [user, phase, toast]);

  const onViewChange = useCallback((v: ViewId) => setView(v), []);

  // Ambiance : la page choisit thème + illustration ; le joueur peut imposer un thème.
  // Écrans de démarrage et de connexion : Kokushibo, ambiance Brume.
  const inApp = Boolean(user) && phase === 'ready';
  const page = VIEWS[view];
  const art = inApp ? page.art : 'kokushibo';
  const focus = inApp ? page.focus : 'right';
  const pageTheme = inApp ? page.theme : 'mist';
  const theme = settings.theme === 'auto' ? pageTheme : settings.theme;
  // Pages dont le contenu occupe toute la largeur : fond assombri pour la lisibilité.
  const dim = inApp && view !== 'home' && view !== 'character';

  return (
    <div className="app" style={themeVars(theme)}>
      <Backdrop art={art} focus={focus} theme={theme} dim={dim} />
      <TitleBar />
      <div className="app__body">
        {phase === 'boot' ? (
          <BootView message="Connexion au quartier général du Corps…" />
        ) : user ? (
          <Shell info={info} config={config} theme={theme} onViewChange={onViewChange} />
        ) : (
          <AuthScreen info={info} config={config} />
        )}
      </div>
    </div>
  );
}
