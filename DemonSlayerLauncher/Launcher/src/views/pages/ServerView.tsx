import type { CSSProperties } from 'react';
import { Icon, type IconName } from '../../components/Icons';
import { Panel, PreviewTag, Ring } from '../../components/ui';
import { PREVIEW_SERVER } from '../../models/preview';
import { useLauncher } from '../LauncherContext';

function Tile({ icon, label, value, live, i }: { icon: IconName; label: string; value: string; live?: boolean; i: number }) {
  return (
    <Panel className="tile reveal" style={{ '--i': i } as CSSProperties}>
      <span className="tile__icon">
        <Icon name={icon} size={18} />
      </span>
      <small>{label}</small>
      <strong>{value}</strong>
      {live && <span className="tile__live">en direct</span>}
    </Panel>
  );
}

/** Courbe de fréquentation (SVG). */
function PlayersChart({ data, max }: { data: number[]; max: number }) {
  const w = 600;
  const h = 150;
  const pts = data.map((v, i) => [(i / (data.length - 1)) * w, h - (v / max) * h * 0.9] as const);
  const line = pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' ');
  return (
    <svg className="chart" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" aria-label="Joueurs connectés sur 12 heures">
      <defs>
        <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" className="stop-accent" stopOpacity=".45" />
          <stop offset="1" className="stop-accent" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={`${line} L${w} ${h} L0 ${h} Z`} fill="url(#chartFill)" />
      <path d={line} className="chart__line" />
      {pts.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r={i === pts.length - 1 ? 5 : 2.5} className="chart__dot" />
      ))}
    </svg>
  );
}

export function ServerView() {
  const { ping, info } = useLauncher();
  const s = PREVIEW_SERVER;

  return (
    <div className="server">
      <section className="server__hero">
        <div className="reveal" style={{ '--i': 0 } as CSSProperties}>
          <p className="kicker">Statut du serveur · 里</p>
          <h1 className="brandtitle brandtitle--md">
            <span className="brandtitle__ndr">NDR</span>
            <span className="brandtitle__name">Demon Slayer</span>
          </h1>
          <div className="server__badges">
            <span className="pill pill--online">
              <span className="live-dot" /> Serveur en ligne
            </span>
            <PreviewTag phase={4} />
          </div>
          <p className="server__lead">
            Village du Glycine · {s.map}. Le statut en direct (joueurs, version, maintenance) sera relié au serveur
            nanos world en phase 4.
          </p>
        </div>

        <Ring value={s.players} max={s.maxPlayers} size={180}>
          <strong>{s.players}</strong>
          <small>/ {s.maxPlayers} joueurs</small>
        </Ring>
      </section>

      <section className="server__tiles">
        <Tile
          i={1}
          icon="signal"
          label="Latence API"
          value={ping?.online ? `${ping.latencyMs} ms` : ping ? 'Hors ligne' : '…'}
          live
        />
        <Tile i={2} icon="refresh" label="Version" value={s.version} />
        <Tile i={3} icon="map" label="Carte" value={s.map} />
        <Tile i={4} icon="clock" label="En ligne depuis" value={s.uptime} />
        <Tile i={5} icon="users" label="Pic du jour" value={`${s.peakToday} joueurs`} />
        <Tile i={6} icon="hourglass" label="Prochain redémarrage" value={s.nextRestart} />
      </section>

      <Panel className="server__chart reveal" style={{ '--i': 7 } as CSSProperties}>
        <header className="panel__head">
          <strong>Fréquentation — 12 dernières heures</strong>
          <PreviewTag phase={4} />
        </header>
        <PlayersChart data={s.history} max={s.maxPlayers} />
        <footer className="server__foot">
          <span>
            <Icon name="globe" size={14} /> API : {info?.apiBaseUrl ?? '—'}
          </span>
          <span>Aucune maintenance programmée</span>
        </footer>
      </Panel>
    </div>
  );
}
