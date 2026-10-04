import { useEffect, useRef, useState } from 'react';
import akaza from '../assets/bg-akaza.jpg';
import gyomei from '../assets/bg-gyomei.jpg';
import kokushibo from '../assets/bg-kokushibo.jpg';
import { useSettings } from '../settings/SettingsContext';
import { THEMES, themeVars, type ThemeId } from '../theme/themes';
import { Particles } from './Particles';

export type BackdropId = 'akaza' | 'gyomei' | 'kokushibo';
export type Focus = 'left' | 'right';

/** Illustrations de fond et point d'intérêt (pour le cadrage). */
const ART: Record<BackdropId, { src: string; ratio: number; pos: string }> = {
  akaza: { src: akaza, ratio: 1464 / 1227, pos: '58% 40%' },
  gyomei: { src: gyomei, ratio: 1, pos: '50% 30%' },
  kokushibo: { src: kokushibo, ratio: 1482 / 1857, pos: '50% 35%' },
};

interface Layer {
  key: string;
  art: BackdropId;
  focus: Focus;
}

/**
 * Fond illustré : l'image nette d'un côté, une copie floutée qui remplit
 * la fenêtre, une teinte aux couleurs de la Respiration, brume, particules
 * et léger parallaxe. Fondu enchaîné quand l'illustration change.
 */
export function Backdrop({ art, focus, theme, dim = false }: { art: BackdropId; focus: Focus; theme: ThemeId; dim?: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  const { settings, motion } = useSettings();
  const [layers, setLayers] = useState<Layer[]>([{ key: `${art}-${focus}`, art, focus }]);

  // Fondu enchaîné : la nouvelle image apparaît par-dessus l'ancienne.
  useEffect(() => {
    const key = `${art}-${focus}`;
    setLayers((ls) => (ls[ls.length - 1]?.key === key ? ls : [...ls.slice(-1), { key, art, focus }]));
    const t = window.setTimeout(() => setLayers((ls) => ls.slice(-1)), 1100);
    return () => window.clearTimeout(t);
  }, [art, focus]);

  const parallax = settings.parallax && motion !== 'off';
  useEffect(() => {
    const el = ref.current;
    if (!el || !parallax) return;
    let raf = 0;
    const onMove = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        el.style.setProperty('--mx', ((e.clientX / window.innerWidth) * 2 - 1).toFixed(3));
        el.style.setProperty('--my', ((e.clientY / window.innerHeight) * 2 - 1).toFixed(3));
      });
    };
    window.addEventListener('pointermove', onMove);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('pointermove', onMove);
      el.style.setProperty('--mx', '0');
      el.style.setProperty('--my', '0');
    };
  }, [parallax]);

  const count = !settings.particles || motion === 'off' ? 0 : motion === 'low' ? 16 : 36;
  const t = THEMES[theme];

  return (
    <div ref={ref} className={`backdrop backdrop--${focus}${dim ? ' backdrop--dim' : ''}`} style={themeVars(theme)} aria-hidden="true">
      {layers.map((l) => {
        const a = ART[l.art];
        return (
          <div key={l.key} className={`backdrop__layer backdrop__layer--${l.focus}`}>
            <img className="backdrop__blur" src={a.src} alt="" draggable={false} />
            <img
              className="backdrop__art"
              src={a.src}
              alt=""
              draggable={false}
              style={{ aspectRatio: String(a.ratio), objectPosition: a.pos }}
            />
          </div>
        );
      })}
      <div className="backdrop__tint" />
      <div className="backdrop__mist backdrop__mist--a" />
      <div className="backdrop__mist backdrop__mist--b" />
      {count > 0 && <Particles kind={t.particle} colors={t.particleColors} count={count} />}
      <div className="backdrop__veil" />
      <div className="scape__grain" />
    </div>
  );
}
