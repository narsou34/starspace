import { useState } from 'react';
import { DEMO_AVAILABLE } from '../../api/bridge';
import { useAuth } from '../../auth/AuthContext';
import { Emblem } from '../../components/Emblem';
import { Icon } from '../../components/Icons';
import { ApiStatus, useApiPing } from '../../components/ServerPing';
import type { AppInfo, PublicConfig } from '../../models/types';
import { LoginForm } from './LoginForm';
import { ForgotForm, ResetForm } from './PasswordForms';
import { RegisterForm } from './RegisterForm';

export type AuthMode = 'login' | 'register' | 'forgot' | 'reset';

export function AuthScreen({ info, config }: { info: AppInfo | null; config: PublicConfig | null }) {
  const [mode, setMode] = useState<AuthMode>('login');
  const [notice, setNotice] = useState<string | null>(null);
  const ping = useApiPing(30_000);
  const { enterDemo } = useAuth();
  const registrationOpen = config?.features.registration ?? true;

  const go = (next: AuthMode, message: string | null = null) => {
    setNotice(message);
    setMode(next);
  };

  return (
    <div className="auth">
      <section className="auth__card">
        <div className="auth__brand">
          <Emblem size={52} />
          <div>
            <strong>
              <span>NDR</span> Demon Slayer
            </strong>
            <small>Serveur roleplay · nanos world</small>
          </div>
        </div>

        <div className="auth__welcome">
          <h2>{mode === 'register' ? 'Rejoignez le Corps' : mode === 'login' ? 'Bon retour, pourfendeur' : 'Récupérer mon compte'}</h2>
          <p>
            {mode === 'register'
              ? 'Créez votre compte pour postuler à la whitelist et préparer votre personnage.'
              : mode === 'login'
                ? 'Connectez-vous pour commencer.'
                : 'Un code vous sera envoyé par e-mail.'}
          </p>
        </div>

        {(mode === 'login' || mode === 'register') && (
          <div className="seg seg--wide" role="tablist">
            <button type="button" role="tab" aria-selected={mode === 'login'} className={mode === 'login' ? 'is-active' : ''} onClick={() => go('login')}>
              Connexion
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={mode === 'register'}
              className={mode === 'register' ? 'is-active' : ''}
              onClick={() => go('register')}
              disabled={!registrationOpen}
              title={registrationOpen ? undefined : 'Inscriptions fermées'}
            >
              Créer un compte
            </button>
          </div>
        )}

        <div className="auth__form" key={mode}>
          {mode === 'login' && <LoginForm notice={notice} onForgot={() => go('forgot')} />}
          {mode === 'register' && <RegisterForm />}
          {mode === 'forgot' && <ForgotForm onBack={() => go('login')} onSent={(msg) => go('reset', msg)} />}
          {mode === 'reset' && <ResetForm notice={notice} onBack={() => go('forgot')} onDone={(msg) => go('login', msg)} />}
        </div>

        {DEMO_AVAILABLE && (
          <button type="button" className="demo-btn" onClick={() => void enterDemo()}>
            <Icon name="eye" size={16} />
            <span>
              <strong>Découvrir en mode aperçu</strong>
              <small>Visite du launcher sans serveur · aucune donnée envoyée</small>
            </span>
          </button>
        )}

        <footer className="auth__footer">
          <ApiStatus ping={ping} />
          <span>v{info?.version ?? '—'}</span>
        </footer>
      </section>

      <aside className="auth__showcase" aria-hidden="true">
        <div className="auth__title">
          <p className="kicker">鬼殺隊 · Corps des pourfendeurs</p>
          <h1 className="brandtitle">
            <span className="brandtitle__ndr">NDR</span>
            <span className="brandtitle__name">Demon Slayer</span>
          </h1>
          <p className="auth__quote">« Concentration totale. Que votre souffle ne s’éteigne jamais. »</p>
        </div>
      </aside>
    </div>
  );
}
