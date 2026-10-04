import { useEffect, useRef } from 'react';
import hero from '../assets/hero.jpg';
import { useSettings } from '../settings/SettingsContext';

/**
 * Illustration du personnage présentée comme une « key art » : fenêtre en
 * arche, liseré doré, halo de la couleur du thème et inclinaison 3D légère
 * qui suit la souris.
 */
export function HeroFigure({ className, strength = 1 }: { className?: string; strength?: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const { settings, motion } = useSettings();
  const enabled = settings.parallax && motion !== 'off';

  useEffect(() => {
    const el = ref.current;
    if (!el || !enabled) return;
    let raf = 0;
    const onMove = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const x = (e.clientX / window.innerWidth) * 2 - 1;
        const y = (e.clientY / window.innerHeight) * 2 - 1;
        el.style.transform = `perspective(1200px) rotateY(${(x * 5 * strength).toFixed(2)}deg) rotateX(${(-y * 3 * strength).toFixed(2)}deg) translate3d(${(-x * 10 * strength).toFixed(1)}px, ${(-y * 6 * strength).toFixed(1)}px, 0)`;
        el.style.setProperty('--sx', `${((x + 1) * 50).toFixed(1)}%`);
      });
    };
    window.addEventListener('pointermove', onMove);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('pointermove', onMove);
    };
  }, [enabled, strength]);

  return (
    <div className={`figure${className ? ` ${className}` : ''}`} aria-hidden="true">
      <div className="figure__glow" />
      <div className="figure__inner" ref={ref}>
        <div className="figure__frame">
          <img src={hero} alt="" draggable={false} />
          <span className="figure__tint" />
          <span className="figure__shine" />
        </div>
        <span className="figure__seal">
          <span>鬼</span>
          <span>殺</span>
          <span>隊</span>
        </span>
      </div>
    </div>
  );
}
