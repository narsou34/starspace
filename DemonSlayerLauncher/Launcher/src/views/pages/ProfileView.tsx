import { useEffect, useState, type CSSProperties } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Avatar } from '../../components/Avatar';
import { Icon, type IconName } from '../../components/Icons';
import { Panel, PreviewTag, Ring, StatusBadge, Tabs } from '../../components/ui';
import { PREVIEW_CHARACTER, PREVIEW_PROFILE } from '../../models/preview';
import { ROLE_LABELS } from '../../models/types';
import { userService } from '../../services/userService';
import { themeVars, type ThemeId } from '../../theme/themes';
import { SecurityPanel } from './SecurityPanel';

const monthYear = new Intl.DateTimeFormat('fr-FR', { month: 'long', year: 'numeric' });
const dateTime = new Intl.DateTimeFormat('fr-FR', { dateStyle: 'long', timeStyle: 'short' });

function Fact({ label, value, icon, theme, i }: { label: string; value: string; icon: IconName; theme: ThemeId; i: number }) {
  return (
    <div className="fact reveal" style={{ ...themeVars(theme), '--i': i } as CSSProperties}>
      <span className="fact__icon">
        <Icon name={icon} size={18} />
      </span>
      <small>{label}</small>
      <strong>{value}</strong>
    </div>
  );
}

export function ProfileView() {
  const { user, setUser, handleError } = useAuth();
  const [tab, setTab] = useState<'profile' | 'security'>('profile');
  const p = PREVIEW_PROFILE;
  const c = PREVIEW_CHARACTER;

  // Le profil est relu depuis le serveur (source de vérité).
  useEffect(() => {
    userService
      .profile()
      .then((res) => setUser(res.user))
      .catch(handleError);
  }, [setUser, handleError]);

  if (!user) return null;

  return (
    <div className="profile">
      <section className="profile__banner reveal" style={{ '--i': 0 } as CSSProperties}>
        <Ring value={p.xp} max={100} size={150}>
          <Avatar user={user} size={104} />
        </Ring>
        <div className="profile__id">
          <p className="kicker">Membre depuis {monthYear.format(new Date(user.createdAt))}</p>
          <h1 className="profile__name">{user.username}</h1>
          <div className="profile__tags">
            <span className="pill">ID #{user.id}</span>
            <span className="pill pill--gold">{ROLE_LABELS[user.role]}</span>
            <span className="pill pill--online">Compte actif</span>
            <span className="pill">Niveau {p.level}</span>
          </div>
        </div>
        <Tabs
          value={tab}
          onChange={setTab}
          items={[
            { id: 'profile', label: 'Profil', icon: 'account' },
            { id: 'security', label: 'Sécurité', icon: 'lock' },
          ]}
        />
      </section>

      {tab === 'security' ? (
        <>
          <Panel className="realinfo reveal" style={{ '--i': 1 } as CSSProperties}>
            <span>
              <small>E-mail</small>
              <strong>{user.email}</strong>
            </span>
            <span>
              <small>Inscription</small>
              <strong>{dateTime.format(new Date(user.createdAt))}</strong>
            </span>
            <span>
              <small>Dernière connexion</small>
              <strong>{user.lastLoginAt ? dateTime.format(new Date(user.lastLoginAt)) : '—'}</strong>
            </span>
          </Panel>
          <SecurityPanel />
        </>
      ) : (
        <>
          <div className="profile__row reveal" style={{ '--i': 1 } as CSSProperties}>
            <Panel className="wlcard" theme="thunder">
              <small>Whitelist</small>
              <StatusBadge status={p.whitelist} />
            </Panel>
            <div className="profile__xp">
              <div className="profile__xphead">
                <strong>Progression</strong>
                <small>
                  Niveau {p.level} · {p.xp}% vers le niveau {p.level + 1}
                </small>
                <PreviewTag phase={2} />
              </div>
              <div className="statbar__track statbar__track--lg">
                <div className="statbar__fill" style={{ width: `${p.xp}%` }} />
              </div>
            </div>
          </div>

          <div className="facts">
            <Fact i={2} icon="characters" label="Personnage" value={c.name} theme="water" />
            <Fact i={3} icon="flame" label="Faction" value={c.faction} theme="flame" />
            <Fact i={4} icon="star" label="Grade" value={c.grade} theme="sun" />
            <Fact i={5} icon="wave" label="Respiration" value="Eau" theme="water" />
            <Fact i={6} icon="clock" label="Temps de jeu" value={p.playtime} theme="mist" />
          </div>

          <div className="profile__grid">
            <Panel className="reveal" style={{ '--i': 7 } as CSSProperties}>
              <header className="panel__head">
                <strong>Statistiques</strong>
              </header>
              <div className="minis">
                {p.stats.map((s) => (
                  <div key={s.label} className="mini">
                    <strong>{s.value}</strong>
                    <small>{s.label}</small>
                  </div>
                ))}
              </div>
            </Panel>

            <Panel className="reveal" style={{ '--i': 8 } as CSSProperties}>
              <header className="panel__head">
                <strong>Succès</strong>
              </header>
              <div className="achievements">
                {p.achievements.map((a) => (
                  <div key={a.name} className={`ach${a.done ? '' : ' is-locked'}`} style={themeVars(a.theme)}>
                    <span className="ach__icon">
                      <Icon name={a.done ? 'trophy' : 'lock'} size={18} />
                    </span>
                    <span>
                      <strong>{a.name}</strong>
                      <small>{a.desc}</small>
                    </span>
                  </div>
                ))}
              </div>
            </Panel>

            <Panel className="reveal" style={{ '--i': 9 } as CSSProperties}>
              <header className="panel__head">
                <strong>Historique</strong>
              </header>
              <ol className="timeline">
                {p.history.map((h) => (
                  <li key={h.text}>
                    <small>{h.date}</small>
                    <span>{h.text}</span>
                  </li>
                ))}
              </ol>
            </Panel>
          </div>
        </>
      )}
    </div>
  );
}
