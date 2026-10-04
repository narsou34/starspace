import { useState, type CSSProperties, type FormEvent } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Button, Checkbox, Field } from '../../components/Form';
import { Icon } from '../../components/Icons';
import { useToast } from '../../components/Toasts';
import { Panel, PreviewTag, StatusBadge } from '../../components/ui';

const STEPS = ['Informations', 'Expérience RP', 'Motivation', 'Validation'] as const;

interface Application {
  rpName: string;
  age: string;
  steamId: string;
  rpExperience: string;
  dsExperience: string;
  rulesRead: boolean;
  microphone: boolean;
  motivation: string;
  availability: string;
  presentation: string;
}

const EMPTY: Application = {
  rpName: '',
  age: '',
  steamId: '',
  rpExperience: '',
  dsExperience: '',
  rulesRead: false,
  microphone: true,
  motivation: '',
  availability: '',
  presentation: '',
};

function TextArea({ label, value, onChange, error, max = 1500 }: { label: string; value: string; onChange: (v: string) => void; error?: string; max?: number }) {
  return (
    <label className={`area${error ? ' area--error' : ''}`}>
      <span>{label}</span>
      <textarea value={value} maxLength={max} rows={4} onChange={(e) => onChange(e.target.value)} />
      <small>{error ?? `${value.length} / ${max}`}</small>
    </label>
  );
}

export function WhitelistView() {
  const { user } = useAuth();
  const toast = useToast();
  const [started, setStarted] = useState(false);
  const [step, setStep] = useState(0);
  const [app, setApp] = useState<Application>({ ...EMPTY, rpName: '' });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const set = <K extends keyof Application>(k: K, v: Application[K]) => setApp((a) => ({ ...a, [k]: v }));

  const validate = (s: number) => {
    const e: Record<string, string> = {};
    if (s === 0) {
      if (app.rpName.trim().length < 3) e.rpName = 'Indiquez un prénom / pseudo RP.';
      const age = Number(app.age);
      if (!Number.isInteger(age) || age < 13 || age > 99) e.age = 'Âge invalide.';
      if (!app.steamId.trim()) e.steamId = 'Identifiant requis.';
    }
    if (s === 1) {
      if (app.rpExperience.trim().length < 30) e.rpExperience = 'Au moins 30 caractères.';
      if (app.dsExperience.trim().length < 20) e.dsExperience = 'Au moins 20 caractères.';
      if (!app.rulesRead) e.rulesRead = 'Vous devez avoir lu le règlement.';
    }
    if (s === 2) {
      if (app.motivation.trim().length < 80) e.motivation = 'Au moins 80 caractères.';
      if (!app.availability.trim()) e.availability = 'Indiquez vos disponibilités.';
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const next = (e: FormEvent) => {
    e.preventDefault();
    if (step < 3) {
      if (validate(step)) setStep(step + 1);
      return;
    }
    toast.show('info', 'Candidature prête', 'L’envoi des candidatures au staff sera activé en phase 2. Votre formulaire est valide.');
  };

  return (
    <div className="whitelist">
      <section className="wl__head reveal" style={{ '--i': 0 } as CSSProperties}>
        <div>
          <p className="kicker">Candidature · 審査</p>
          <h1 className="page-title">Whitelist</h1>
          <p className="lead">Rejoignez le Corps des pourfendeurs. Votre candidature est examinée par le staff.</p>
        </div>
        <Panel className="wl__status">
          <small>Votre statut</small>
          <StatusBadge status="none" />
          <PreviewTag phase={2} />
        </Panel>
      </section>

      <div className="wl__legend reveal" style={{ '--i': 1 } as CSSProperties}>
        <StatusBadge status="accepted" label="Acceptée — vous pouvez jouer" />
        <StatusBadge status="pending" label="En attente — examen par le staff" />
        <StatusBadge status="refused" label="Refusée — vous pourrez repostuler" />
      </div>

      {!started ? (
        <Panel className="wl__cta reveal" style={{ '--i': 2 } as CSSProperties}>
          <span className="wl__ctaicon">
            <Icon name="whitelist" size={34} />
          </span>
          <div>
            <h2>Vous n’avez pas encore postulé</h2>
            <p>Quatre étapes, environ 10 minutes. Soyez précis et sincère : la qualité RP compte plus que la longueur.</p>
          </div>
          <Button onClick={() => setStarted(true)}>Postuler à la whitelist</Button>
        </Panel>
      ) : (
        <>
          <ol className="stepper reveal" style={{ '--i': 2, '--progress': step / 3 } as CSSProperties}>
            {STEPS.map((s, i) => (
              <li key={s} className={i < step ? 'is-done' : i === step ? 'is-current' : ''}>
                <span className="stepper__num">{i < step ? <Icon name="check" size={16} /> : `0${i + 1}`}</span>
                <span className="stepper__label">{s}</span>
              </li>
            ))}
          </ol>

          <Panel className="wl__form reveal" key={step}>
            <form onSubmit={next} noValidate>
              {step === 0 && (
                <div className="grid2">
                  <Field label="Prénom / pseudo RP" value={app.rpName} onChange={(e) => set('rpName', e.target.value)} error={errors.rpName} maxLength={40} />
                  <Field label="Âge" inputMode="numeric" value={app.age} onChange={(e) => set('age', e.target.value.replace(/\D/g, ''))} error={errors.age} maxLength={2} />
                  <Field label="Steam ID / identifiant nanos world" value={app.steamId} onChange={(e) => set('steamId', e.target.value)} error={errors.steamId} maxLength={64} />
                  <Field label="Compte launcher" value={user?.username ?? ''} disabled />
                </div>
              )}
              {step === 1 && (
                <>
                  <TextArea label="Expérience en roleplay" value={app.rpExperience} onChange={(v) => set('rpExperience', v)} error={errors.rpExperience} />
                  <TextArea label="Connaissance de l’univers Demon Slayer" value={app.dsExperience} onChange={(v) => set('dsExperience', v)} error={errors.dsExperience} />
                  <div className="checks">
                    <Checkbox checked={app.rulesRead} onChange={(v) => set('rulesRead', v)}>
                      J’ai lu et j’accepte le règlement du serveur
                    </Checkbox>
                    <Checkbox checked={app.microphone} onChange={(v) => set('microphone', v)}>
                      Je dispose d’un microphone fonctionnel
                    </Checkbox>
                    {errors.rulesRead && <p className="field__error">{errors.rulesRead}</p>}
                  </div>
                </>
              )}
              {step === 2 && (
                <>
                  <TextArea label="Motivation" value={app.motivation} onChange={(v) => set('motivation', v)} error={errors.motivation} />
                  <Field label="Disponibilités" placeholder="Ex. soirs de semaine, week-end" value={app.availability} onChange={(e) => set('availability', e.target.value)} error={errors.availability} maxLength={120} />
                  <TextArea label="Présentation (facultatif)" value={app.presentation} onChange={(v) => set('presentation', v)} max={800} />
                </>
              )}
              {step === 3 && (
                <dl className="recap">
                  <div><dt>Pseudo RP</dt><dd>{app.rpName}</dd></div>
                  <div><dt>Âge</dt><dd>{app.age} ans</dd></div>
                  <div><dt>Identifiant</dt><dd>{app.steamId}</dd></div>
                  <div><dt>Microphone</dt><dd>{app.microphone ? 'Oui' : 'Non'}</dd></div>
                  <div><dt>Disponibilités</dt><dd>{app.availability}</dd></div>
                  <div className="recap__wide"><dt>Motivation</dt><dd>{app.motivation}</dd></div>
                </dl>
              )}

              <footer className="wl__nav">
                <button type="button" className="btn btn--ghost" disabled={step === 0} onClick={() => setStep(step - 1)}>
                  <Icon name="arrow" size={16} className="flip" /> Précédent
                </button>
                <span className="wl__count">Étape {step + 1} / 4</span>
                <Button type="submit">{step < 3 ? 'Continuer' : 'Envoyer ma candidature'}</Button>
              </footer>
            </form>
          </Panel>
        </>
      )}
    </div>
  );
}
