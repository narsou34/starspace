import { useState, type CSSProperties } from 'react';
import { Icon } from '../../components/Icons';
import { Chip, Panel, PreviewTag, StatBar } from '../../components/ui';
import { PREVIEW_CHARACTER } from '../../models/preview';

export function CharacterView() {
  const c = PREVIEW_CHARACTER;
  const [slot, setSlot] = useState(0);

  return (
    <div className="character">
      {/* Colonne laissée libre : l’illustration du fond (Kokushibo) apparaît ici */}
      <div className="character__art" />

      <section className="character__info">
        <div className="slots reveal" style={{ '--i': 0 } as CSSProperties}>
          <button type="button" className={slot === 0 ? 'is-active' : ''} onClick={() => setSlot(0)}>
            Personnage 1
          </button>
          <button type="button" className={slot === 1 ? 'is-active' : ''} onClick={() => setSlot(1)}>
            <Icon name="plus" size={14} /> Emplacement libre
          </button>
          <PreviewTag phase={2} />
        </div>

        {slot === 0 ? (
          <>
            <h1 className="character__name reveal" style={{ '--i': 1 } as CSSProperties}>
              {c.name}
            </h1>
            <div className="character__chips reveal" style={{ '--i': 2 } as CSSProperties}>
              <Chip theme="flame" icon="characters">
                {c.faction}
              </Chip>
              <Chip theme="sun" icon="star">
                {c.grade}
              </Chip>
              <Chip theme="water" icon="wave">
                {c.breath}
              </Chip>
              <Chip theme="wind" icon="check">
                {c.status}
              </Chip>
            </div>

            <div className="character__level reveal" style={{ '--i': 3 } as CSSProperties}>
              <div>
                <small>Niveau</small>
                <strong>{c.level}</strong>
              </div>
              <div className="character__xp">
                <div className="statbar__track">
                  <div className="statbar__fill" style={{ width: `${c.xp}%` }} />
                </div>
                <small>
                  {c.xp}% vers le niveau {c.level + 1} · {c.playtime} de jeu · grade {c.gradeRank}/{c.gradeTotal}
                </small>
              </div>
            </div>

            <div className="character__stats reveal" style={{ '--i': 4 } as CSSProperties}>
              {c.stats.map((s) => (
                <StatBar key={s.label} label={s.label} value={s.value} />
              ))}
            </div>

            <Panel className="techniques reveal" style={{ '--i': 5 } as CSSProperties}>
              <header className="panel__head">
                <strong>Formes maîtrisées</strong>
                <small>{c.breath}</small>
              </header>
              <ul>
                {c.techniques.map((t) => (
                  <li key={t.name} className={t.unlocked ? '' : 'is-locked'}>
                    <span className="techniques__icon">
                      <Icon name={t.unlocked ? 'wave' : 'lock'} size={16} />
                    </span>
                    <span>
                      <small>{t.form}</small>
                      <strong>{t.name}</strong>
                    </span>
                  </li>
                ))}
              </ul>
            </Panel>
            <p className="note">Les informations du personnage sont contrôlées par le serveur et ne sont pas modifiables ici.</p>
          </>
        ) : (
          <Panel className="emptyslot reveal">
            <Icon name="plus" size={28} />
            <strong>Emplacement libre</strong>
            <p>La création de personnage sera disponible après acceptation de votre whitelist (phase 2).</p>
          </Panel>
        )}
      </section>
    </div>
  );
}
