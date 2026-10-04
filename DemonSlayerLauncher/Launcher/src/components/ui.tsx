import { useEffect, useState, type CSSProperties, type ReactNode } from 'react';
import { themeVars, type ThemeId } from '../theme/themes';
import { Icon, type IconName } from './Icons';

/** Panneau translucide. `theme` permet de teinter un panneau isolément. */
export function Panel({
  children,
  className,
  theme,
  style,
  as: Tag = 'section',
}: {
  children: ReactNode;
  className?: string;
  theme?: ThemeId;
  style?: CSSProperties;
  as?: 'section' | 'article' | 'div' | 'aside';
}) {
  return (
    <Tag className={`panel${className ? ` ${className}` : ''}`} style={{ ...(theme ? themeVars(theme) : {}), ...style }}>
      {children}
    </Tag>
  );
}

/** Indique clairement des données d'exemple (fonctionnalité d'une phase à venir). */
export function PreviewTag({ phase }: { phase?: number }) {
  return (
    <span className="preview-tag" title="Données d'exemple : cette fonctionnalité sera reliée au serveur dans une prochaine phase.">
      <Icon name="eye" size={12} /> Aperçu{phase ? ` · phase ${phase}` : ''}
    </span>
  );
}

export function SectionTitle({ kicker, children, right }: { kicker?: string; children: ReactNode; right?: ReactNode }) {
  return (
    <header className="section-title">
      <div>
        {kicker && <p className="kicker">{kicker}</p>}
        <h2>{children}</h2>
      </div>
      {right}
    </header>
  );
}

/** Barre de progression animée au montage. */
export function StatBar({ label, value, theme, icon }: { label: string; value: number; theme?: ThemeId; icon?: IconName }) {
  const [shown, setShown] = useState(0);
  useEffect(() => {
    const id = requestAnimationFrame(() => setShown(value));
    return () => cancelAnimationFrame(id);
  }, [value]);
  return (
    <div className="statbar" style={theme ? themeVars(theme) : undefined}>
      <div className="statbar__head">
        <span>
          {icon && <Icon name={icon} size={15} />}
          {label}
        </span>
        <strong>{value}%</strong>
      </div>
      <div className="statbar__track">
        <div className="statbar__fill" style={{ width: `${shown}%` }} />
      </div>
    </div>
  );
}

/** Jauge circulaire (joueurs connectés, niveau…). */
export function Ring({ value, max, size = 120, children }: { value: number; max: number; size?: number; children?: ReactNode }) {
  const [shown, setShown] = useState(0);
  useEffect(() => {
    const id = requestAnimationFrame(() => setShown(value / max));
    return () => cancelAnimationFrame(id);
  }, [value, max]);
  const r = 46;
  const c = 2 * Math.PI * r;
  return (
    <div className="ring" style={{ width: size, height: size }}>
      <svg viewBox="0 0 100 100">
        <circle cx="50" cy="50" r={r} className="ring__track" />
        <circle
          cx="50"
          cy="50"
          r={r}
          className="ring__fill"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - shown)}
          transform="rotate(-90 50 50)"
        />
      </svg>
      <div className="ring__content">{children}</div>
    </div>
  );
}

export type ReviewStatus = 'accepted' | 'pending' | 'refused' | 'none' | 'suspended';

const STATUS: Record<ReviewStatus, { label: string; icon: IconName }> = {
  accepted: { label: 'Acceptée', icon: 'check' },
  pending: { label: 'En attente', icon: 'hourglass' },
  refused: { label: 'Refusée', icon: 'x' },
  none: { label: 'Non whitelisté', icon: 'info' },
  suspended: { label: 'Suspendue', icon: 'lock' },
};

/** Statut toujours exprimé par couleur + icône + texte. */
export function StatusBadge({ status, label }: { status: ReviewStatus; label?: string }) {
  const s = STATUS[status];
  return (
    <span className={`status status--${status}`}>
      <Icon name={s.icon} size={14} />
      {label ?? s.label}
    </span>
  );
}

export function Tabs<T extends string>({
  value,
  onChange,
  items,
}: {
  value: T;
  onChange: (v: T) => void;
  items: { id: T; label: string; icon?: IconName }[];
}) {
  return (
    <div className="seg" role="tablist">
      {items.map((it) => (
        <button
          key={it.id}
          type="button"
          role="tab"
          aria-selected={value === it.id}
          className={value === it.id ? 'is-active' : ''}
          onClick={() => onChange(it.id)}
        >
          {it.icon && <Icon name={it.icon} size={15} />}
          {it.label}
        </button>
      ))}
    </div>
  );
}

export function Toggle({
  checked,
  onChange,
  label,
  hint,
  disabled,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  label: string;
  hint?: string;
  disabled?: boolean;
}) {
  return (
    <label className={`toggle${disabled ? ' is-disabled' : ''}`}>
      <span className="toggle__text">
        <strong>{label}</strong>
        {hint && <small>{hint}</small>}
      </span>
      <input type="checkbox" checked={checked} disabled={disabled} onChange={(e) => onChange(e.target.checked)} />
      <span className="toggle__track" aria-hidden="true">
        <span className="toggle__thumb" />
      </span>
    </label>
  );
}

export function Modal({ open, onClose, children, theme }: { open: boolean; onClose: () => void; children: ReactNode; theme?: ThemeId }) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);
  if (!open) return null;
  return (
    <div className="modal" role="dialog" aria-modal="true" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal__box" style={theme ? themeVars(theme) : undefined}>
        <button type="button" className="modal__close" onClick={onClose} aria-label="Fermer">
          <Icon name="x" />
        </button>
        {children}
      </div>
    </div>
  );
}

/** Petite étiquette de catégorie teintée. */
export function Chip({ children, theme, icon }: { children: ReactNode; theme?: ThemeId; icon?: IconName }) {
  return (
    <span className="chip" style={theme ? themeVars(theme) : undefined}>
      {icon && <Icon name={icon} size={13} />}
      {children}
    </span>
  );
}
