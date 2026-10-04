import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Button, Field, FormAlert } from '../../components/Form';
import { Icon } from '../../components/Icons';
import { useToast } from '../../components/Toasts';
import { Panel } from '../../components/ui';
import { errorMessage, isLauncherError, type AccountSession } from '../../models/types';
import { userService } from '../../services/userService';
import { StrengthMeter, validatePassword } from '../auth/RegisterForm';

const dateTime = new Intl.DateTimeFormat('fr-FR', { dateStyle: 'short', timeStyle: 'short' });

function relative(iso: string): string {
  const minutes = Math.round((Date.now() - new Date(iso).getTime()) / 60_000);
  if (minutes < 2) return 'à l’instant';
  if (minutes < 60) return `il y a ${minutes} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `il y a ${hours} h`;
  return dateTime.format(new Date(iso));
}

/** Changement de mot de passe (API réelle). */
function PasswordForm() {
  const { handleError } = useAuth();
  const toast = useToast();
  const [current, setCurrent] = useState('');
  const [next, setNext] = useState('');
  const [confirm, setConfirm] = useState('');
  const [fields, setFields] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!current) errs.currentPassword = 'Mot de passe actuel requis.';
    const pw = validatePassword(next);
    if (pw) errs.newPassword = pw;
    if (confirm !== next) errs.confirm = 'Les mots de passe ne correspondent pas.';
    setFields(errs);
    if (Object.keys(errs).length) return;
    setLoading(true);
    setError(null);
    try {
      const res = await userService.changePassword(current, next);
      toast.show('success', 'Mot de passe modifié', res.message);
      setCurrent('');
      setNext('');
      setConfirm('');
    } catch (err) {
      handleError(err);
      setError(errorMessage(err));
      if (isLauncherError(err) && err.details?.fields) setFields(err.details.fields);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Panel className="sec" theme="thunder">
      <header className="panel__head">
        <strong>
          <Icon name="lock" size={18} /> Mot de passe
        </strong>
      </header>
      <form onSubmit={submit} noValidate>
        {error && <FormAlert kind="error">{error}</FormAlert>}
        <Field label="Mot de passe actuel" type="password" autoComplete="current-password" value={current} onChange={(e) => setCurrent(e.target.value)} error={fields.currentPassword} maxLength={128} />
        <Field label="Nouveau mot de passe" type="password" autoComplete="new-password" value={next} onChange={(e) => setNext(e.target.value)} error={fields.newPassword} hint={<StrengthMeter password={next} />} maxLength={128} />
        <Field label="Confirmer" type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} error={fields.confirm} maxLength={128} />
        <Button type="submit" loading={loading}>
          Mettre à jour
        </Button>
      </form>
    </Panel>
  );
}

/** Appareils connectés (API réelle). */
function Sessions() {
  const { handleError, logoutAll } = useAuth();
  const toast = useToast();
  const [sessions, setSessions] = useState<AccountSession[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setSessions(await userService.sessions());
    } catch (err) {
      handleError(err);
      toast.show('error', 'Sessions', errorMessage(err));
    }
  }, [handleError, toast]);

  useEffect(() => {
    void load();
  }, [load]);

  const revoke = async (s: AccountSession) => {
    setBusy(s.id);
    try {
      await userService.revokeSession(s.id);
      toast.show('success', 'Appareil déconnecté', s.deviceName ?? 'Session révoquée.');
      await load();
    } catch (err) {
      handleError(err);
      toast.show('error', 'Sessions', errorMessage(err));
    } finally {
      setBusy(null);
    }
  };

  const revokeAll = async () => {
    if (!window.confirm('Déconnecter tous les appareils, y compris celui-ci ?')) return;
    setBusy('all');
    try {
      await logoutAll();
      toast.show('info', 'Tous les appareils ont été déconnectés');
    } catch (err) {
      handleError(err);
      toast.show('error', 'Sessions', errorMessage(err));
      setBusy(null);
    }
  };

  return (
    <Panel className="sec" theme="mist">
      <header className="panel__head">
        <strong>
          <Icon name="device" size={18} /> Appareils connectés
        </strong>
      </header>
      {sessions === null ? (
        <p className="muted">Chargement…</p>
      ) : (
        <ul className="sessions">
          {sessions.map((s) => (
            <li key={s.id} className={s.current ? 'is-current' : ''}>
              <span className="sessions__icon">
                <Icon name="monitor" size={18} />
              </span>
              <div>
                <strong>
                  {s.deviceName ?? 'Appareil inconnu'}
                  {s.current && <span className="here">Cet appareil</span>}
                </strong>
                <small>
                  Actif {relative(s.lastUsedAt)} · IP {s.ip ?? '—'} · {s.remember ? 'Rester connecté' : 'Session courte'}
                </small>
              </div>
              {!s.current && (
                <button type="button" className="link link--danger" disabled={busy !== null} onClick={() => void revoke(s)}>
                  Déconnecter
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
      <Button variant="danger" onClick={() => void revokeAll()} loading={busy === 'all'} disabled={busy !== null}>
        Déconnecter tous les appareils
      </Button>
    </Panel>
  );
}

export function SecurityPanel() {
  return (
    <div className="security">
      <PasswordForm />
      <Sessions />
    </div>
  );
}
