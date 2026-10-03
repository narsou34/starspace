import { useMemo, useState, type FormEvent } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Button, Checkbox, Field, FormAlert } from '../../components/Form';
import { errorMessage, isLauncherError } from '../../models/types';

/** Mêmes règles que le backend (qui reste seul juge). */
export function validatePassword(pw: string): string | undefined {
  if (pw.length < 10) return 'Au moins 10 caractères.';
  if (!/[A-Za-z]/.test(pw) || !/[0-9]/.test(pw)) return 'Au moins une lettre et un chiffre.';
  return undefined;
}

export function passwordStrength(pw: string): number {
  let score = 0;
  if (pw.length >= 10) score++;
  if (pw.length >= 14) score++;
  if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  return Math.min(4, score);
}

export function StrengthMeter({ password }: { password: string }) {
  const score = passwordStrength(password);
  const labels = ['Très faible', 'Faible', 'Moyen', 'Solide', 'Excellent'];
  return (
    <span className="strength" data-score={password ? score : -1}>
      <span className="strength__bars">
        {[0, 1, 2, 3].map((i) => (
          <i key={i} className={password && i < score ? 'on' : ''} />
        ))}
      </span>
      {password ? labels[score] : '10 caractères min., lettres et chiffres'}
    </span>
  );
}

export function RegisterForm() {
  const { register } = useAuth();
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [remember, setRemember] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fields, setFields] = useState<Record<string, string>>({});

  const localErrors = useMemo(() => {
    const errs: Record<string, string> = {};
    if (!/^[A-Za-z0-9_.-]{3,20}$/.test(username.trim()))
      errs.username = '3 à 20 caractères (a-z, 0-9, _ . -).';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) errs.email = 'Adresse e-mail invalide.';
    const pw = validatePassword(password);
    if (pw) errs.password = pw;
    if (confirm !== password) errs.confirm = 'Les mots de passe ne correspondent pas.';
    return errs;
  }, [username, email, password, confirm]);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setFields(localErrors);
    if (Object.keys(localErrors).length) return;
    setLoading(true);
    setError(null);
    try {
      await register(username.trim(), email.trim(), password, remember);
    } catch (err) {
      setError(errorMessage(err));
      if (isLauncherError(err) && err.details?.fields) setFields(err.details.fields);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} noValidate>
      {error && <FormAlert kind="error">{error}</FormAlert>}
      <div className="form-grid">
        <Field
          label="Pseudo"
          autoComplete="username"
          autoFocus
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          error={fields.username}
          maxLength={20}
        />
        <Field
          label="Adresse e-mail"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={fields.email}
          maxLength={254}
        />
      </div>
      <Field
        label="Mot de passe"
        type="password"
        autoComplete="new-password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={fields.password}
        hint={<StrengthMeter password={password} />}
        maxLength={128}
      />
      <Field
        label="Confirmer le mot de passe"
        type="password"
        autoComplete="new-password"
        value={confirm}
        onChange={(e) => setConfirm(e.target.value)}
        error={fields.confirm}
        maxLength={128}
      />
      <div className="auth__row">
        <Checkbox checked={remember} onChange={setRemember}>
          Rester connecté
        </Checkbox>
      </div>
      <Button type="submit" loading={loading} className="btn--wide">
        Créer mon compte
      </Button>
    </form>
  );
}
