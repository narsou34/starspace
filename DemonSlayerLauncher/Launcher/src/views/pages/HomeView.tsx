import type { CSSProperties } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { HeroFigure } from '../../components/HeroFigure';
import { Icon } from '../../components/Icons';
import { PlayButton } from '../../components/PlayButton';
import { Chip, Panel, PreviewTag } from '../../components/ui';
import { PREVIEW_EVENTS, PREVIEW_NEWS, PREVIEW_SERVER } from '../../models/preview';
import { Landscape } from '../../scenery/Landscape';
import { useLauncher } from '../LauncherContext';

export function HomeView() {
  const { user } = useAuth();
  const { ping, navigate } = useLauncher();
  const news = PREVIEW_NEWS[0]!;
  const s = PREVIEW_SERVER;

  return (
    <div className="home">
      <HeroFigure className="home__figure" />

      <section className="home__hero">
        <p className="kicker reveal" style={{ '--i': 0 } as CSSProperties}>
          Bienvenue, {user?.username} · 鬼殺隊
        </p>
        <h1 className="brandtitle reveal" style={{ '--i': 1 } as CSSProperties}>
          <span className="brandtitle__ndr">NDR</span>
          <span className="brandtitle__name">Demon Slayer</span>
        </h1>
        <p className="home__tagline reveal" style={{ '--i': 2 } as CSSProperties}>
          Entrez dans votre histoire.
        </p>
        <div className="reveal" style={{ '--i': 3 } as CSSProperties}>
          <PlayButton ping={ping} />
        </div>
      </section>

      <section className="home__dock">
        <Panel theme="wind" className="dock dock--server reveal" style={{ '--i': 4 } as CSSProperties}>
          <header className="dock__head">
            <span className="live-dot" />
            <strong>Serveur en ligne</strong>
            <PreviewTag />
          </header>
          <p className="dock__big">
            {s.players}
            <small> / {s.maxPlayers} joueurs</small>
          </p>
          <div className="meter">
            <span style={{ width: `${(s.players / s.maxPlayers) * 100}%` }} />
          </div>
          <button type="button" className="dock__link" onClick={() => navigate('server')}>
            Voir le serveur <Icon name="arrow" size={15} />
          </button>
        </Panel>

        <button type="button" className="dock dock--news reveal" style={{ '--i': 5 } as CSSProperties} onClick={() => navigate('news')}>
          <Landscape theme={news.theme} scene={news.scene} mode="card" />
          <div className="dock__overlay">
            <header className="dock__head">
              <Chip theme="flame" icon="news">
                {news.category}
              </Chip>
              <PreviewTag />
            </header>
            <strong className="dock__title">{news.title}</strong>
            <small>{news.date}</small>
          </div>
        </button>

        <Panel theme="sun" className="dock dock--events reveal" style={{ '--i': 6 } as CSSProperties}>
          <header className="dock__head">
            <Icon name="calendar" size={16} />
            <strong>Événements</strong>
            <PreviewTag />
          </header>
          {PREVIEW_EVENTS.map((e) => (
            <div key={e.title} className="event">
              <span className="event__bar" />
              <div>
                <strong>{e.title}</strong>
                <small>
                  {e.when} · {e.place}
                </small>
              </div>
            </div>
          ))}
        </Panel>
      </section>
    </div>
  );
}
