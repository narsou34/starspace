import { useEffect, useRef } from 'react';
import type { ParticleKind } from '../theme/themes';

interface P {
  x: number;
  y: number;
  size: number;
  vx: number;
  vy: number;
  rot: number;
  vr: number;
  phase: number;
  alpha: number;
  color: string;
}

/** Comportement par type : sens, vitesse, forme. */
const BEHAVIOUR: Record<ParticleKind, { rising: boolean; speed: number; size: [number, number]; drift: number }> = {
  motes: { rising: true, speed: 0.25, size: [0.6, 2.2], drift: 0.5 },
  embers: { rising: true, speed: 0.55, size: [0.5, 1.9], drift: 0.7 },
  sparks: { rising: true, speed: 0.18, size: [0.5, 1.6], drift: 0.3 },
  petals: { rising: false, speed: 0.6, size: [3, 6], drift: 1.2 },
  leaves: { rising: false, speed: 0.75, size: [3, 6.5], drift: 1.4 },
};

/**
 * Particules d'ambiance sur canvas. Léger : ~30 i/s, pause quand la fenêtre
 * est masquée, nombre réglable dans les paramètres.
 */
export function Particles({ kind, colors, count }: { kind: ParticleKind; colors: string[]; count: number }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;
    const b = BEHAVIOUR[kind];
    let width = 0;
    let height = 0;
    const resize = () => {
      width = canvas.clientWidth;
      height = canvas.clientHeight;
      canvas.width = width;
      canvas.height = height;
    };
    resize();

    const spawn = (initial: boolean): P => ({
      x: Math.random() * width,
      y: initial ? Math.random() * height : b.rising ? height + 10 : -10,
      size: b.size[0] + Math.random() * (b.size[1] - b.size[0]),
      vx: (Math.random() - 0.3) * b.drift,
      vy: (0.4 + Math.random()) * b.speed,
      rot: Math.random() * Math.PI,
      vr: (Math.random() - 0.5) * 0.04,
      phase: Math.random() * Math.PI * 2,
      alpha: 0.35 + Math.random() * 0.5,
      color: colors[Math.floor(Math.random() * colors.length)]!,
    });
    const ps = Array.from({ length: count }, () => spawn(true));

    let raf = 0;
    let last = 0;
    const frame = (t: number) => {
      raf = requestAnimationFrame(frame);
      if (t - last < 33) return;
      last = t;
      ctx.clearRect(0, 0, width, height);
      for (let i = 0; i < ps.length; i++) {
        const p = ps[i]!;
        p.y += b.rising ? -p.vy * 2 : p.vy * 2;
        p.x += p.vx + Math.sin(t / 1600 + p.phase) * b.drift * 0.5;
        p.rot += p.vr;
        if (p.y < -20 || p.y > height + 20 || p.x < -30 || p.x > width + 30) ps[i] = spawn(false);
        const flicker = 0.7 + Math.sin(t / 380 + p.phase) * 0.3;
        ctx.globalAlpha = p.alpha * (kind === 'sparks' ? flicker * flicker : flicker);
        ctx.fillStyle = `rgb(${p.color})`;
        if (kind === 'petals' || kind === 'leaves') {
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rot + Math.sin(t / 700 + p.phase) * 0.6);
          ctx.beginPath();
          ctx.ellipse(0, 0, p.size, p.size * (kind === 'petals' ? 0.55 : 0.35), 0, 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
        } else {
          ctx.shadowColor = `rgba(${p.color},0.9)`;
          ctx.shadowBlur = p.size * 7;
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
          ctx.fill();
          ctx.shadowBlur = 0;
        }
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
  }, [kind, colors, count]);

  return <canvas ref={ref} className="scape__particles" aria-hidden="true" />;
}
