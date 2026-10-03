import { useEffect, useRef } from 'react';

interface Ember {
  x: number;
  y: number;
  r: number;
  vy: number;
  drift: number;
  phase: number;
  alpha: number;
  color: string;
}

const COLORS = ['255,92,72', '232,52,74', '255,140,90', '196,22,42', '170,185,255'];

/**
 * Braises qui s'élèvent lentement. Volontairement léger : ~40 particules,
 * ~30 i/s, pause quand la fenêtre est masquée, désactivé si l'utilisateur
 * préfère réduire les animations.
 */
export function Particles({ count = 40 }: { count?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = 0;
    let height = 0;
    const resize = () => {
      width = canvas.clientWidth;
      height = canvas.clientHeight;
      canvas.width = width;
      canvas.height = height;
    };
    resize();

    const spawn = (initial: boolean): Ember => ({
      x: Math.random() * width,
      y: initial ? Math.random() * height : height + 10,
      r: Math.random() * 1.6 + 0.4,
      vy: Math.random() * 0.35 + 0.15,
      drift: Math.random() * 0.6 + 0.2,
      phase: Math.random() * Math.PI * 2,
      alpha: Math.random() * 0.5 + 0.25,
      color: COLORS[Math.floor(Math.random() * COLORS.length)]!,
    });
    const embers = Array.from({ length: count }, () => spawn(true));

    let raf = 0;
    let last = 0;
    const frame = (t: number) => {
      raf = requestAnimationFrame(frame);
      if (t - last < 33) return; // ~30 images/s suffisent
      last = t;
      ctx.clearRect(0, 0, width, height);
      for (let i = 0; i < embers.length; i++) {
        const e = embers[i]!;
        e.y -= e.vy * 2;
        e.x += Math.sin(t / 1800 + e.phase) * e.drift * 0.6;
        if (e.y < -10) embers[i] = spawn(false);
        const flicker = 0.75 + Math.sin(t / 300 + e.phase) * 0.25;
        const fade = Math.min(1, e.y / (height * 0.35));
        ctx.globalAlpha = Math.max(0, e.alpha * flicker * fade);
        ctx.fillStyle = `rgb(${e.color})`;
        ctx.shadowColor = `rgba(${e.color},0.9)`;
        ctx.shadowBlur = e.r * 6;
        ctx.beginPath();
        ctx.arc(e.x, e.y, e.r, 0, Math.PI * 2);
        ctx.fill();
      }
    };

    const onVisibility = () => {
      cancelAnimationFrame(raf);
      if (!document.hidden) raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    window.addEventListener('resize', resize);
    document.addEventListener('visibilitychange', onVisibility);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
      document.removeEventListener('visibilitychange', onVisibility);
    };
  }, [count]);

  return <canvas ref={ref} className="bg__particles" aria-hidden="true" />;
}
