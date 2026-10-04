import { bridge } from '../api/bridge';
import { useAuth } from '../auth/AuthContext';
import { Icon } from '../components/Icons';
import { IconTile } from '../components/IconTile';
import { ApiStatus, useApiPing } from '../components/ServerPing';
import { useToast } from '../components/Toasts';
import type { PublicConfig } from '../models/types';
import { BREATHS, accentStyle, findNav, type Breath, type ViewId } from './navigation';

/** Accès rapides : chaque carte reprend la couleur de sa section. */
const FEATURES: { id: ViewId; subtitle: string }[] = [
  { id: 'account', subtitle: 'Profil, sécurité, appareils' },
  { id: 'whitelist', subtitle: 'Postuler et suivre ma candidature' },
  { id: 'characters', subtitle: 'Faction, grade, respiration' },
  { id: 'tickets', subtitle: 'Contacter le staff' },
];

const STEPS: { label: string; detail: string; breath: Breath; done?: boolean; target?: ViewId }[] = [
  { label: 'Compte', detail: 'Connecté', breath: 'vent', done: true, target: 'account' },
  { label: 'Whitelist', detail: 'Phase 2', breath: 'insecte', target: 'whitelist' },
  { label: 'Personnage', detail: 'Phase 2', breath: 'tonnerre', target: 'characters' },
  { label: 'Mises à jour', detail: 'Phase 6', breath: 'eau' },
  { label: 'Jouer', detail: 'Phase 4', breath: 'flamme' },
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
          <em>NDR</em>
          <i className="home__sep" aria-hidden="true" />
          <span>DEMON SLAYER</span>
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

      <div className="features">
        {FEATURES.map(({ id, subtitle }) => {
          const item = findNav(id)!;
          return (
            <button
              key={id}
              type="button"
              className="feature"
              style={accentStyle(item.breath)}
              onClick={() => onNavigate(id)}
            >
              <span className="feature__top">
                <IconTile name={item.icon} size="lg" />
                {item.phase ? (
                  <span className="feature__badge">Phase {item.phase}</span>
                ) : (
                  <span className="feature__arrow">→</span>
                )}
              </span>
              <strong>{item.label}</strong>
              <small>{subtitle}</small>
              <span className="feature__kanji" aria-hidden="true">
                {item.kanji}
              </span>
            </button>
          );
        })}
      </div>

      <div className="home__bottom">
        <div className="journey">
          <p className="journey__title">Votre parcours</p>
          <ol>
            {STEPS.map((step, i) => (
              <li key={step.label} className={step.done ? 'is-done' : ''} style={accentStyle(step.breath)}>
                <button
                  type="button"
                  disabled={!step.target}
                  onClick={() => step.target && onNavigate(step.target)}
                  title={BREATHS[step.breath].title}
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
            <button type="button" className="btn btn--discord-cta" onClick={() => void bridge.openExternal(discord)}>
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
            <span className="play__label">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M7 4.5v15l13-7.5z" />
              </svg>
              JOUER
            </span>
            <span className="play__sub">Lancement automatique · phase 4</span>
          </button>
        </div>
      </div>
    </section>
  );
}
