import { createContext, useContext, useEffect, useRef, type CSSProperties, type ReactNode } from 'react';
import { useSettings } from '../settings/SettingsContext';
import { THEMES, themeVars, type ThemeId } from '../theme/themes';
import { H, W, bamboo, pagoda, pines, ridge, stars, torii, village } from './geometry';
import { Particles } from './Particles';

export type SceneId = 'mountains' | 'village' | 'forest' | 'shrine' | 'lake';

/** Préfixe des identifiants de dégradés : plusieurs décors coexistent dans la page. */
const UidContext = createContext('f');
function useUrl() {
  const uid = useContext(UidContext);
  return (id: string) => `url(#${uid}${id})`;
}

/* ── Géométrie précalculée (une seule fois) ───────────────────── */
const FAR = ridge(11, 560, 260, 0.8);
const MID = ridge(23, 690, 200, 1.1);
const NEAR = ridge(37, 820, 150, 1.4);
const NEAR_PINES = pines(5, NEAR, 46, 1);
const MID_PINES = pines(9, MID, 30, 0.6);
const STARS = stars(3, 90);
const HOUSES_BACK = village(41, 770, 0, W, 0.7);
const HOUSES_FRONT = village(42, 860, 0, W, 1);
const PAGODA = pagoda(1180, 770, 5, 1.05);
const BAMBOO_BACK = bamboo(51, 34, 5, 10);
const BAMBOO_FRONT = bamboo(52, 14, 14, 26);
const TORII = torii(1290, 770, 0.85);
const SHRINE_HILL = ridge(61, 800, 60, 0.5);

/** Fuji : grand sommet enneigé, emblème du décor d'accueil. */
const FUJI = 'M260 900 Q530 640 670 470 L720 438 L770 470 Q910 640 1180 900 Z';
const FUJI_SNOW = 'M670 470 L720 438 L770 470 L752 500 L736 486 L720 506 L703 488 L687 500 Z';

const MOON_POS: Record<SceneId, [number, number, number]> = {
  mountains: [990, 150, 58],
  village: [840, 118, 50],
  forest: [800, 150, 78],
  shrine: [1290, 230, 78],
  lake: [1330, 170, 60],
};

function Layer({ depth, children, className }: { depth: number; children: ReactNode; className?: string }) {
  return (
    <g className={`scape__layer${className ? ` ${className}` : ''}`} style={{ '--d': depth } as CSSProperties}>
      {children}
    </g>
  );
}

function Moon({ scene, animate }: { scene: SceneId; animate: boolean }) {
  const u = useUrl();
  const [cx, cy, r] = MOON_POS[scene];
  return (
    <Layer depth={0.08}>
      {/* lumière volumétrique */}
      <g transform={`translate(${cx} ${cy})`} className="scape__rays">
        <g>
          {Array.from({ length: 14 }, (_, i) => (
            <path key={i} d="M-8 0 L8 0 L80 1100 L-80 1100 Z" transform={`rotate(${i * 25.7})`} fill={u('ray')} />
          ))}
          {animate && (
            <animateTransform
              attributeName="transform"
              type="rotate"
              from="0"
              to="360"
              dur="260s"
              repeatCount="indefinite"
            />
          )}
        </g>
      </g>
      <circle cx={cx} cy={cy} r={r * 5} fill={u('halo')} />
      <circle cx={cx} cy={cy} r={r * 1.6} fill={u('halo')} />
      <circle cx={cx} cy={cy} r={r} className="scape__moon" />
      <circle cx={cx - r * 0.3} cy={cy - r * 0.15} r={r * 0.18} className="scape__crater" />
      <circle cx={cx + r * 0.25} cy={cy + r * 0.3} r={r * 0.12} className="scape__crater" />
    </Layer>
  );
}

function MistBand({ y, h, depth, slow }: { y: number; h: number; depth: number; slow?: boolean }) {
  const u = useUrl();
  return (
    <Layer depth={depth}>
      <g className={slow ? 'scape__drift scape__drift--slow' : 'scape__drift'}>
        <rect x={-200} y={y} width={W + 400} height={h} fill={u('mist')} />
        <ellipse cx={400} cy={y + h * 0.5} rx={520} ry={h * 0.45} fill={u('mistBlob')} />
        <ellipse cx={1250} cy={y + h * 0.4} rx={600} ry={h * 0.5} fill={u('mistBlob')} />
      </g>
    </Layer>
  );
}

function SceneForeground({ scene }: { scene: SceneId }) {
  const u = useUrl();
  switch (scene) {
    case 'mountains':
      return (
        <>
          <Layer depth={0.15}>
            <path d={FUJI} className="fuji" />
            <path d={FUJI_SNOW} className="scape__snow" />
          </Layer>
          <MistBand y={600} h={160} depth={0.2} slow />
          <Layer depth={0.3}>
            <path d={MID.path} className="m2" />
            <path d={MID_PINES} className="m2" />
          </Layer>
          <MistBand y={720} h={140} depth={0.4} />
          <Layer depth={0.6}>
            <path d={NEAR.path} className="m3" />
            <path d={NEAR_PINES} className="m3" />
          </Layer>
        </>
      );
    case 'village':
      return (
        <>
          <MistBand y={600} h={150} depth={0.2} slow />
          <Layer depth={0.3}>
            <path d={MID.path} className="m2" />
            <path d={MID_PINES} className="m2" />
          </Layer>
          <Layer depth={0.45}>
            {HOUSES_BACK.map((h, i) => (
              <g key={i}>
                <path d={h.body} className="house house--back" />
                <path d={h.roof} className="roof roof--back" />
                {h.windows.map((w, j) => (
                  <rect key={j} x={w.x} y={w.y} width={w.w} height={w.h} className="lamp lamp--dim" />
                ))}
              </g>
            ))}
            <path d={PAGODA} className="roof roof--back" />
          </Layer>
          <MistBand y={760} h={110} depth={0.5} />
          <Layer depth={0.7}>
            {HOUSES_FRONT.map((h, i) => (
              <g key={i}>
                <path d={h.body} className="house" />
                <path d={h.roof} className="roof" />
                {h.windows.map((w, j) => (
                  <rect key={j} x={w.x} y={w.y} width={w.w} height={w.h} className="lamp" />
                ))}
              </g>
            ))}
            {/* guirlande de lanternes */}
            <path d="M0 740 Q400 800 800 745 T1600 760" className="scape__string" />
            {Array.from({ length: 16 }, (_, i) => {
              const x = 50 + i * 100;
              const y = 760 + Math.sin(i * 0.9) * 18;
              return (
                <g key={i}>
                  <circle cx={x} cy={y} r={22} fill={u('lampGlow')} />
                  <ellipse cx={x} cy={y} rx={7} ry={9} className="lantern" />
                </g>
              );
            })}
          </Layer>
        </>
      );
    case 'forest':
      return (
        <>
          <MistBand y={560} h={200} depth={0.2} slow />
          <Layer depth={0.3}>
            {BAMBOO_BACK.map((s, i) => (
              <g key={i} className="bamboo bamboo--back">
                <path d={`M${s.x} ${H} Q${s.x + s.lean / 2} 400 ${s.x + s.lean} -40`} strokeWidth={s.w} />
                {s.nodes.map((y, j) => (
                  <line key={j} x1={s.x - s.w} x2={s.x + s.w} y1={y} y2={y} className="bamboo__node" />
                ))}
              </g>
            ))}
          </Layer>
          <MistBand y={680} h={180} depth={0.45} />
          <Layer depth={0.75}>
            {BAMBOO_FRONT.map((s, i) => (
              <g key={i} className="bamboo">
                <path d={`M${s.x} ${H + 20} Q${s.x + s.lean / 2} 400 ${s.x + s.lean} -60`} strokeWidth={s.w} />
                {s.nodes.map((y, j) => (
                  <line key={j} x1={s.x - s.w * 0.7} x2={s.x + s.w * 0.7} y1={y} y2={y} className="bamboo__node" />
                ))}
              </g>
            ))}
          </Layer>
        </>
      );
    case 'shrine':
      return (
        <>
          <MistBand y={580} h={170} depth={0.2} slow />
          <Layer depth={0.3}>
            <path d={MID.path} className="m2" />
          </Layer>
          <Layer depth={0.5}>
            <path d={SHRINE_HILL.path} className="m3" />
            <path d={TORII} className="torii" />
          </Layer>
          <MistBand y={770} h={120} depth={0.6} />
        </>
      );
    case 'lake':
      return (
        <>
          <Layer depth={0.25}>
            <path d={MID.path} className="m2" transform="translate(0 -40)" />
          </Layer>
          <Layer depth={0.35}>
            <rect x={0} y={640} width={W} height={H - 640} fill={u('water')} />
            {Array.from({ length: 9 }, (_, i) => (
              <rect
                key={i}
                x={MOON_POS.lake[0] - 70 + (i % 3) * 14 - i * 4}
                y={660 + i * 24}
                width={140 - i * 9}
                height={3}
                rx={1.5}
                className="scape__reflect"
                style={{ animationDelay: `${i * 0.35}s` }}
              />
            ))}
          </Layer>
          <MistBand y={600} h={110} depth={0.4} slow />
          <Layer depth={0.7}>
            <path d={NEAR.path} className="m3" transform="translate(0 70)" />
          </Layer>
        </>
      );
  }
}

interface LandscapeProps {
  theme: ThemeId;
  scene: SceneId;
  /** 'full' : arrière-plan de la fenêtre ; 'card' : illustration dans une carte */
  mode?: 'full' | 'card';
  className?: string;
}

/**
 * Décor illustré : ciel, étoiles, lune et lumière volumétrique, montagnes,
 * brume et scène propre à la page, avec parallaxe à la souris.
 * Les couleurs proviennent du thème et se transforment en douceur.
 */
export function Landscape({ theme, scene, mode = 'full', className }: LandscapeProps) {
  const ref = useRef<HTMLDivElement>(null);
  const { settings, motion } = useSettings();
  const full = mode === 'full';
  const parallax = full && settings.parallax && motion !== 'off';

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

  const particleCount = !full || !settings.particles || motion === 'off' ? 0 : motion === 'low' ? 18 : 42;
  const uid = mode === 'full' ? 'f' : `c${scene}${theme}`;

  return (
    <div
      ref={ref}
      className={`scape scape--${mode}${className ? ` ${className}` : ''}`}
      style={themeVars(theme)}
      aria-hidden="true"
    >
      <div className="scape__sky" />
      <svg className="scape__svg" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMax slice">
        <defs>
          <radialGradient id={`${uid}halo`}>
            <stop offset="0" className="stop-moon" stopOpacity=".55" />
            <stop offset=".35" className="stop-accent2" stopOpacity=".16" />
            <stop offset="1" className="stop-accent2" stopOpacity="0" />
          </radialGradient>
          <linearGradient id={`${uid}ray`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" className="stop-moon" stopOpacity=".12" />
            <stop offset="1" className="stop-moon" stopOpacity="0" />
          </linearGradient>
          <linearGradient id={`${uid}mist`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" className="stop-mist" stopOpacity="0" />
            <stop offset=".5" className="stop-mist" stopOpacity="1" />
            <stop offset="1" className="stop-mist" stopOpacity="0" />
          </linearGradient>
          <radialGradient id={`${uid}mistBlob`}>
            <stop offset="0" className="stop-mist" stopOpacity=".9" />
            <stop offset="1" className="stop-mist" stopOpacity="0" />
          </radialGradient>
          <radialGradient id={`${uid}lampGlow`}>
            <stop offset="0" className="stop-lamp" stopOpacity=".55" />
            <stop offset="1" className="stop-lamp" stopOpacity="0" />
          </radialGradient>
          <linearGradient id={`${uid}water`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" className="stop-sky3" stopOpacity=".55" />
            <stop offset="1" className="stop-shade" stopOpacity="1" />
          </linearGradient>
        </defs>
        <UidContext.Provider value={uid}>
          <Layer depth={0.03}>
            {STARS.map((s, i) => (
              <circle
                key={i}
                cx={s.x}
                cy={s.y}
                r={s.r}
                className={s.twinkle ? 'star star--twinkle' : 'star'}
                style={s.twinkle ? { animationDelay: `${s.delay}s` } : undefined}
              />
            ))}
          </Layer>
          <Moon scene={scene} animate={full && motion === 'high'} />
          <Layer depth={0.1}>
            <path d={FAR.path} className="m1" />
          </Layer>
          <g className="scape__scene" key={scene}>
            <SceneForeground scene={scene} />
          </g>
        </UidContext.Provider>
      </svg>
      {particleCount > 0 && <Particles kind={THEMES[theme].particle} colors={THEMES[theme].particleColors} count={particleCount} />}
      <div className="scape__veil" />
      {full && <div className="scape__grain" />}
    </div>
  );
}
