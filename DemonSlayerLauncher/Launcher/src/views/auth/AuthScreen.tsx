import { useState } from 'react';
import { Emblem } from '../../components/Emblem';
import { ApiStatus, useApiPing } from '../../components/ServerPing';
import { VerticalKanji } from '../../components/VerticalKanji';
import type { AppInfo, PublicConfig } from '../../models/types';
import { LoginForm } from './LoginForm';
import { ForgotForm, ResetForm } from './PasswordForms';
import { RegisterForm } from './RegisterForm';

export type AuthMode = 'login' | 'register' | 'forgot' | 'reset';

export function AuthScreen({ info, config }: { info: AppInfo | null; config: PublicConfig | null }) {
  const [mode, setMode] = useState<AuthMode>('login');
  const [notice, setNotice] = useState<string | null>(null);
  const ping = useApiPing(30_000);
  const registrationOpen = config?.features.registration ?? true;

  const go = (next: AuthMode, message: string | null = null) => {
    setNotice(message);
    setMode(next);
  };

  return (
    <div className="auth">
      <section className="auth__panel">
        <div className="auth__brand">
          <Emblem size={58} />
          <div>
            <h1>
              DEMON SLAYER <em>RP</em>
            </h1>
            <p>Serveur roleplay · nanos world</p>
          </div>
        </div>

        <div className="auth__welcome">
          <h2>{mode === 'register' ? 'Rejoignez le Corps' : 'Bienvenue sur Demon Slayer RP'}</h2>
          <p>
            {mode === 'register'
              ? 'Créez votre compte pour postuler à la whitelist et préparer votre personnage.'
              : mode === 'login'
                ? 'Connectez-vous pour commencer.'
                : 'Récupérez l’accès à votre compte.'}
          </p>
        </div>

        {(mode === 'login' || mode === 'register') && (
          <div className="tabs" role="tablist">
            <button
              type="button"
              role="tab"
              aria-selected={mode === 'login'}
              className={mode === 'login' ? 'is-active' : ''}
              onClick={() => go('login')}
            >
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
            <span className={`tabs__ink tabs__ink--${mode}`} />
          </div>
        )}

        <div className="auth__form" key={mode}>
          {mode === 'login' && <LoginForm notice={notice} onForgot={() => go('forgot')} />}
          {mode === 'register' && <RegisterForm />}
          {mode === 'forgot' && <ForgotForm onBack={() => go('login')} onSent={(msg) => go('reset', msg)} />}
          {mode === 'reset' && (
            <ResetForm notice={notice} onBack={() => go('forgot')} onDone={(msg) => go('login', msg)} />
          )}
        </div>

        <footer className="auth__footer">
          <ApiStatus ping={ping} />
          <span>v{info?.version ?? '—'}</span>
        </footer>
      </section>

      <aside className="auth__art" aria-hidden="true">
        <VerticalKanji text="鬼殺隊" className="auth__vertical" />
        <div className="auth__quote">
          <span>全集中</span>
          <p>« Concentration totale. Que votre souffle ne s’éteigne jamais. »</p>
        </div>
      </aside>
    </div>
  );
}
