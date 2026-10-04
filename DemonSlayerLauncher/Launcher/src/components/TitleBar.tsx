import { isTauri } from '../api/bridge';
import { Emblem } from './Emblem';

async function windowAction(action: 'minimize' | 'toggleMaximize' | 'close') {
  const { getCurrentWindow } = await import('@tauri-apps/api/window');
  await getCurrentWindow()[action]();
}

/** Barre de titre personnalisée (fenêtre sans bordure Windows). */
export function TitleBar() {
  return (
    <header className="titlebar" data-tauri-drag-region>
      <div className="titlebar__brand" data-tauri-drag-region>
        <Emblem size={16} />
        <span data-tauri-drag-region>
          <b>NDR</b> | Demon Slayer
        </span>
      </div>
      {isTauri && (
        <div className="titlebar__controls">
          <button type="button" aria-label="Réduire" onClick={() => void windowAction('minimize')}>
            <svg viewBox="0 0 12 12"><path d="M2 6h8" /></svg>
          </button>
          <button type="button" aria-label="Agrandir" onClick={() => void windowAction('toggleMaximize')}>
            <svg viewBox="0 0 12 12"><rect x="2.5" y="2.5" width="7" height="7" /></svg>
          </button>
          <button type="button" className="titlebar__close" aria-label="Fermer" onClick={() => void windowAction('close')}>
            <svg viewBox="0 0 12 12"><path d="M2.5 2.5l7 7M9.5 2.5l-7 7" /></svg>
          </button>
        </div>
      )}
    </header>
  );
}
