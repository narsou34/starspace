import { bridge } from '../api/bridge';
import { useAuth } from '../auth/AuthContext';
import { Icon } from '../components/Icons';
import { ApiStatus, useApiPing } from '../components/ServerPing';
import { useToast } from '../components/Toasts';
import type { PublicConfig } from '../models/types';
import type { ViewId } from './navigation';

const STEPS: { label: string; detail: string; done?: boolean; target?: ViewId }[] = [
  { label: 'Compte', detail: 'Connecté', done: true, target: 'account' },
  { label: 'Whitelist', detail: 'Phase 2', target: 'whitelist' },
  { label: 'Personnage', detail: 'Phase 2', target: 'characters' },
  { label: 'Mises à jour', detail: 'Phase 6' },
  { label: 'Jouer', detail: 'Phase 4' },
];

export function HomeView({ onNavigate, config }: { onNavigate: (v: ViewId) => void; config: PublicConfig | null }) {
  const { user } = useAuth();
  const toast = useToast();
  const ping = useApiPing();
  const discord = config?.links.discord;

  return (
    <section className="home">
      <div className="home__hero">
        <p className="eyebrow">Bienvenue, {user?.username}.</p>
        <h1 className="home__title">
          <span>DEMON SLAYER</span>
          <em>RP</em>
        </h1>
        <p className="home__tagline">Taisho, ère des pourfendeurs. Votre légende commence ici.</p>

        <div className="home__status">
          <ApiStatus ping={ping} label="Services du launcher" />
          <span className="status-dot status-dot--pending">
            <i />
            Serveur de jeu · statut en direct en phase 4
          </span>
        </div>
      </div>

      <div className="home__bottom">
        <div className="journey">
          <p className="journey__title">Votre parcours</p>
          <ol>
            {STEPS.map((step, i) => (
              <li key={step.label} className={step.done ? 'is-done' : ''}>
                <button
                  type="button"
                  disabled={!step.target}
                  onClick={() => step.target && onNavigate(step.target)}
                >
                  <span className="journey__num">{step.done ? <Icon name="check" size={14} /> : `0${i + 1}`}</span>
                  <span className="journey__text">
                    <strong>{step.label}</strong>
                    <small>{step.detail}</small>
                  </span>
                </button>
              </li>
            ))}
          </ol>
        </div>

        <div className="home__actions">
          {discord && (
            <button type="button" className="btn btn--ghost" onClick={() => void bridge.openExternal(discord)}>
              <Icon name="discord" /> <span className="btn__label">Rejoindre le Discord</span>
            </button>
          )}
          <button
            type="button"
            className="play"
            onClick={() =>
              toast.show(
                'info',
                'Bientôt disponible',
                'Le lancement automatique de nanos world arrive en phase 4 (statut serveur, whitelist, fichiers).',
              )
            }
          >
            <span className="play__label">JOUER</span>
            <span className="play__sub">Lancement automatique · phase 4</span>
          </button>
        </div>
      </div>
    </section>
  );
}
