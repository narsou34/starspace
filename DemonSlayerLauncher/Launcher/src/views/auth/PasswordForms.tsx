import { useState, type FormEvent } from 'react';
import { bridge } from '../../api/bridge';
import { Button, Field, FormAlert } from '../../components/Form';
import { errorMessage, isLauncherError } from '../../models/types';
import { StrengthMeter, validatePassword } from './RegisterForm';

export function ForgotForm({ onBack, onSent }: { onBack: () => void; onSent: (msg: string | null) => void }) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setError('Adresse e-mail invalide.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await bridge.forgotPassword(email.trim());
      onSent(res.message);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} noValidate>
      <p className="auth__step">
        <span>01</span> Saisissez l’adresse e-mail de votre compte. Vous recevrez un code de réinitialisation.
      </p>
      {error && <FormAlert kind="error">{error}</FormAlert>}
      <Field
        label="Adresse e-mail"
        type="email"
        autoComplete="email"
        autoFocus
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        maxLength={254}
      />
      <Button type="submit" loading={loading} className="btn--wide">
        Envoyer le code
      </Button>
      <div className="auth__links">
        <button type="button" className="link" onClick={onBack}>
          ← Retour à la connexion
        </button>
        <button type="button" className="link" onClick={() => onSent(null)}>
          J’ai déjà un code
        </button>
      </div>
    </form>
  );
}

export function ResetForm({
  notice,
  onBack,
  onDone,
}: {
  notice: string | null;
  onBack: () => void;
  onDone: (msg: string) => void;
}) {
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fields, setFields] = useState<Record<string, string>>({});

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (code.replace(/[^A-Za-z0-9]/g, '').length !== 12) errs.code = 'Le code contient 12 caractères.';
    const pw = validatePassword(password);
    if (pw) errs.newPassword = pw;
    if (confirm !== password) errs.confirm = 'Les mots de passe ne correspondent pas.';
    setFields(errs);
    if (Object.keys(errs).length) return;

    setLoading(true);
    setError(null);
    try {
      const res = await bridge.resetPassword(code, password);
      onDone(res.message);
    } catch (err) {
      setError(errorMessage(err));
      if (isLauncherError(err) && err.details?.fields) setFields(err.details.fields);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} noValidate>
      {notice && <FormAlert kind="info">{notice}</FormAlert>}
      <p className="auth__step">
        <span>02</span> Entrez le code reçu par e-mail et choisissez un nouveau mot de passe.
      </p>
      {error && <FormAlert kind="error">{error}</FormAlert>}
      <Field
        label="Code de réinitialisation"
        placeholder="XXXX-XXXX-XXXX"
        autoFocus
        className="mono"
        value={code}
        onChange={(e) => setCode(e.target.value.toUpperCase())}
        error={fields.code}
        maxLength={20}
      />
      <Field
        label="Nouveau mot de passe"
        type="password"
        autoComplete="new-password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={fields.newPassword}
        hint={<StrengthMeter password={password} />}
        maxLength={128}
      />
      <Field
        label="Confirmer"
        type="password"
        autoComplete="new-password"
        value={confirm}
        onChange={(e) => setConfirm(e.target.value)}
        error={fields.confirm}
        maxLength={128}
      />
      <Button type="submit" loading={loading} className="btn--wide">
        Changer le mot de passe
      </Button>
      <div className="auth__links">
        <button type="button" className="link" onClick={onBack}>
          ← Renvoyer un code
        </button>
      </div>
    </form>
  );
}
