import { useState, type FormEvent } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Button, Checkbox, Field, FormAlert } from '../../components/Form';
import { Icon } from '../../components/Icons';
import { errorMessage, isLauncherError } from '../../models/types';

export function LoginForm({ notice, onForgot }: { notice: string | null; onForgot: () => void }) {
  const { login } = useAuth();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [remember, setRemember] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fields, setFields] = useState<Record<string, string>>({});

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const missing: Record<string, string> = {};
    if (!identifier.trim()) missing.login = 'Identifiant requis.';
    if (!password) missing.password = 'Mot de passe requis.';
    setFields(missing);
    if (Object.keys(missing).length) return;

    setLoading(true);
    setError(null);
    try {
      await login(identifier.trim(), password, remember);
    } catch (err) {
      setError(errorMessage(err));
      if (isLauncherError(err) && err.details?.fields) setFields(err.details.fields);
      setPassword('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} noValidate>
      {notice && <FormAlert kind="success">{notice}</FormAlert>}
      {error && <FormAlert kind="error">{error}</FormAlert>}
      <Field
        label="Identifiant ou e-mail"
        autoComplete="username"
        autoFocus
        value={identifier}
        onChange={(e) => setIdentifier(e.target.value)}
        error={fields.login}
        maxLength={254}
      />
      <Field
        label="Mot de passe"
        type="password"
        autoComplete="current-password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={fields.password}
        maxLength={128}
      />
      <div className="auth__row">
        <Checkbox checked={remember} onChange={setRemember}>
          Rester connecté
        </Checkbox>
        <button type="button" className="link" onClick={onForgot}>
          Mot de passe oublié ?
        </button>
      </div>
      <Button type="submit" loading={loading} className="btn--wide">
        Se connecter
      </Button>

      <div className="divider">
        <span>ou</span>
      </div>
      <div className="social">
        <Button type="button" variant="social" className="btn--discord" disabled title="Connexion Discord — bientôt disponible">
          <Icon name="discord" /> Discord <small>bientôt</small>
        </Button>
        <Button type="button" variant="social" className="btn--steam" disabled title="Connexion Steam — bientôt disponible">
          <Icon name="shield" /> Steam <small>bientôt</small>
        </Button>
      </div>
    </form>
  );
}
