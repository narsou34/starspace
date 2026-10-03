/** Emblème Demon Slayer RP : lune pourpre et lame (création originale). */
export function Emblem({ size = 40, className }: { size?: number; className?: string }) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 1024 1024" aria-hidden="true">
      <defs>
        <radialGradient id="em-moon" cx="42%" cy="38%" r="65%">
          <stop offset="0" stopColor="#ff4d5e" />
          <stop offset=".55" stopColor="#c4162a" />
          <stop offset="1" stopColor="#5c0610" />
        </radialGradient>
        <linearGradient id="em-blade" x1="0" y1="1" x2="1" y2="0">
          <stop offset="0" stopColor="#9aa3c7" />
          <stop offset=".5" stopColor="#ffffff" />
          <stop offset="1" stopColor="#cfd6f5" />
        </linearGradient>
      </defs>
      <circle cx="512" cy="500" r="290" fill="url(#em-moon)" />
      <circle cx="512" cy="500" r="330" fill="none" stroke="#d9b26a" strokeOpacity=".75" strokeWidth="16" />
      <path d="M232 820 L780 220 L806 246 L262 846 Z" fill="url(#em-blade)" />
      <rect x="262" y="700" width="140" height="34" rx="12" transform="rotate(-47.6 332 717)" fill="#d9b26a" />
      <path d="M200 862 L292 762 L318 786 L226 886 Z" fill="#1c1c28" stroke="#c4162a" strokeWidth="10" />
    </svg>
  );
}
