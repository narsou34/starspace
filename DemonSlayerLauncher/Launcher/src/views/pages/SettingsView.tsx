import type { CSSProperties } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Button } from '../../components/Form';
import { Icon } from '../../components/Icons';
import { useToast } from '../../components/Toasts';
import { Panel, Tabs, Toggle } from '../../components/ui';
import { errorMessage } from '../../models/types';
import { useSettings, type MotionLevel } from '../../settings/SettingsContext';
import { THEMES, THEME_ORDER, themeVars } from '../../theme/themes';
import { useLauncher } from '../LauncherContext';

export function SettingsView() {
  const { settings, update, reset } = useSettings();
  const { info } = useLauncher();
  const { logout, logoutAll } = useAuth();
  const toast = useToast();

  return (
    <div className="settings">
      <header className="reveal" style={{ '--i': 0 } as CSSProperties}>
        <p className="kicker">設定 · Personnalisation</p>
        <h1 className="page-title">Paramètres</h1>
      </header>

      <div className="settings__grid">
        <Panel className="settings__block settings__block--wide reveal" style={{ '--i': 1 } as CSSProperties}>
          <header className="panel__head">
            <strong>
              <Icon name="palette" size={18} /> Thème des Respirations
            </strong>
            <small>{settings.theme === 'auto' ? 'Le thème suit chaque page' : THEMES[settings.theme].breath}</small>
          </header>
          <div className="swatches">
            <button type="button" className={`swatch swatch--auto${settings.theme === 'auto' ? ' is-active' : ''}`} onClick={() => update({ theme: 'auto' })}>
              <span className="swatch__dot" />
              <strong>Auto</strong>
              <small>Selon la page</small>
            </button>
            {THEME_ORDER.map((id) => (
              <button
                key={id}
                type="button"
                className={`swatch${settings.theme === id ? ' is-active' : ''}`}
                style={themeVars(id)}
                onClick={() => update({ theme: id })}
              >
                <span className="swatch__dot">{THEMES[id].kanji}</span>
                <strong>{THEMES[id].name}</strong>
                <small>{THEMES[id].breath}</small>
              </button>
            ))}
          </div>
        </Panel>

        <Panel className="settings__block reveal" style={{ '--i': 2 } as CSSProperties}>
          <header className="panel__head">
            <strong>
              <Icon name="monitor" size={18} /> Graphismes
            </strong>
          </header>
          <div className="setting">
            <span>
              <strong>Qualité des animations</strong>
              <small>Réduisez si le launcher tourne sur un PC modeste.</small>
            </span>
            <Tabs<MotionLevel>
              value={settings.motion}
              onChange={(motion) => update({ motion })}
              items={[
                { id: 'high', label: 'Élevée' },
                { id: 'low', label: 'Réduite' },
                { id: 'off', label: 'Aucune' },
              ]}
            />
          </div>
          <Toggle label="Parallaxe" hint="Le décor suit légèrement la souris" checked={settings.parallax} onChange={(parallax) => update({ parallax })} />
          <Toggle label="Particules" hint="Pétales, braises et lucioles" checked={settings.particles} onChange={(particles) => update({ particles })} />
        </Panel>

        <Panel className="settings__block reveal" style={{ '--i': 3 } as CSSProperties}>
          <header className="panel__head">
            <strong>
              <Icon name="bell" size={18} /> Launcher
            </strong>
          </header>
          <Toggle label="Notifications" hint="Whitelist, tickets, maintenances" checked={settings.notifications} onChange={(notifications) => update({ notifications })} />
          <Toggle label="Démarrage automatique" hint="Disponible en phase 6" checked={false} onChange={() => undefined} disabled />
          <Toggle label="Lancer réduit" hint="Disponible en phase 6" checked={false} onChange={() => undefined} disabled />
          <div className="setting">
            <span>
              <strong>Langue</strong>
              <small>D’autres langues pourront être ajoutées.</small>
            </span>
            <span className="setting__value">Français</span>
          </div>
        </Panel>

        <Panel className="settings__block reveal" style={{ '--i': 4 } as CSSProperties}>
          <header className="panel__head">
            <strong>
              <Icon name="folder" size={18} /> Connexion au jeu
            </strong>
          </header>
          <div className="setting">
            <span>
              <strong>Chemin de nanos world</strong>
              <small>Détection automatique en phase 4.</small>
            </span>
            <span className="setting__value is-muted">Non configuré</span>
          </div>
          <div className="setting">
            <span>
              <strong>Serveur d’API</strong>
              <small>Source : {info?.configSource ?? '—'}</small>
            </span>
            <span className="setting__value mono">{info?.apiBaseUrl ?? '—'}</span>
          </div>
          <button
            type="button"
            className="btn btn--ghost"
            onClick={() => {
              reset();
              toast.show('success', 'Réglages réinitialisés');
            }}
          >
            <Icon name="refresh" size={16} /> Réinitialiser les réglages
          </button>
        </Panel>

        <Panel className="settings__block reveal" style={{ '--i': 5 } as CSSProperties}>
          <header className="panel__head">
            <strong>
              <Icon name="account" size={18} /> Compte
            </strong>
          </header>
          <p className="muted">Mot de passe et appareils connectés : page Profil → Sécurité.</p>
          <div className="settings__actions">
            <Button variant="ghost" onClick={() => void logout().catch((e) => toast.show('error', 'Déconnexion', errorMessage(e)))}>
              Se déconnecter
            </Button>
            <Button
              variant="danger"
              onClick={() => {
                if (window.confirm('Déconnecter tous les appareils, y compris celui-ci ?')) {
                  void logoutAll().catch((e) => toast.show('error', 'Sessions', errorMessage(e)));
                }
              }}
            >
              Déconnecter partout
            </Button>
          </div>
        </Panel>
      </div>
    </div>
  );
}
