import { useState } from 'react';
import type { ApiPing } from '../models/types';
import { Icon } from './Icons';
import { useToast } from './Toasts';

/** Bouton principal du launcher. Le lancement réel arrive en phase 4. */
export function PlayButton({ ping }: { ping: ApiPing | null }) {
  const toast = useToast();
  const [pressed, setPressed] = useState(false);
  const online = ping?.online ?? false;

  const onClick = () => {
    setPressed(true);
    window.setTimeout(() => setPressed(false), 600);
    toast.show(
      'info',
      'Lancement bientôt disponible',
      'JOUER vérifiera le serveur, la whitelist, les fichiers puis lancera nanos world (phase 4).',
    );
  };

  return (
    <div className="playwrap">
      <button type="button" className={`play${pressed ? ' is-pressed' : ''}`} onClick={onClick}>
        <span className="play__aura" aria-hidden="true" />
        <span className="play__icon" aria-hidden="true">
          <Icon name="play" size={26} />
        </span>
        <span className="play__text">
          <strong>JOUER</strong>
          <small>nanos world · NDR | Demon Slayer</small>
        </span>
        <span className="play__shine" aria-hidden="true" />
      </button>
      <p className={`play__state play__state--${ping === null ? 'pending' : online ? 'online' : 'offline'}`}>
        <i />
        {ping === null
          ? 'Vérification des services…'
          : online
            ? `Services en ligne · ${ping.latencyMs ?? '—'} ms · lancement automatique en phase 4`
            : 'Services injoignables — vérifiez votre connexion'}
      </p>
    </div>
  );
}
