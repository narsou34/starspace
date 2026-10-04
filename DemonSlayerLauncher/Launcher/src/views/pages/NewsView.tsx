import { useState, type CSSProperties } from 'react';
import { Icon } from '../../components/Icons';
import { Chip, Modal, Panel, PreviewTag, Tabs } from '../../components/ui';
import { PREVIEW_CHANGELOG, PREVIEW_NEWS, type NewsItem } from '../../models/preview';
import { Landscape } from '../../scenery/Landscape';

const CATS = ['Tout', 'Mise à jour', 'Événement', 'Maintenance', 'Annonce'] as const;

function NewsCard({ item, featured, onOpen, i }: { item: NewsItem; featured?: boolean; onOpen: () => void; i: number }) {
  return (
    <button type="button" className={`ncard${featured ? ' ncard--featured' : ''} reveal`} style={{ '--i': i } as CSSProperties} onClick={onOpen}>
      <Landscape theme={item.theme} scene={item.scene} mode="card" />
      <div className="ncard__body">
        <span className="ncard__meta">
          <Chip theme={item.theme}>{item.category}</Chip>
          <small>{item.date}</small>
        </span>
        <strong>{item.title}</strong>
        {featured && <p>{item.excerpt}</p>}
        <span className="ncard__read">
          Lire l’article <Icon name="arrow" size={15} />
        </span>
      </div>
    </button>
  );
}

export function NewsView() {
  const [tab, setTab] = useState<'news' | 'changelog'>('news');
  const [cat, setCat] = useState<(typeof CATS)[number]>('Tout');
  const [open, setOpen] = useState<NewsItem | null>(null);
  const items = PREVIEW_NEWS.filter((n) => cat === 'Tout' || n.category === cat);
  const [first, ...rest] = items;

  return (
    <div className="news">
      <header className="news__head reveal" style={{ '--i': 0 } as CSSProperties}>
        <div>
          <p className="kicker">瓦版 · Le journal du Corps</p>
          <h1 className="page-title">Actualités</h1>
        </div>
        <div className="news__tools">
          <Tabs
            value={tab}
            onChange={setTab}
            items={[
              { id: 'news', label: 'Actualités', icon: 'news' },
              { id: 'changelog', label: 'Changelog', icon: 'changelog' },
            ]}
          />
          <PreviewTag phase={3} />
        </div>
      </header>

      {tab === 'news' ? (
        <>
          <div className="filters reveal" style={{ '--i': 1 } as CSSProperties}>
            {CATS.map((c) => (
              <button key={c} type="button" className={cat === c ? 'is-active' : ''} onClick={() => setCat(c)}>
                {c}
              </button>
            ))}
          </div>
          {first ? (
            <div className="news__grid">
              <NewsCard item={first} featured onOpen={() => setOpen(first)} i={2} />
              {rest.map((n, idx) => (
                <NewsCard key={n.id} item={n} onOpen={() => setOpen(n)} i={3 + idx} />
              ))}
            </div>
          ) : (
            <Panel className="empty">Aucune actualité dans cette catégorie.</Panel>
          )}
        </>
      ) : (
        <div className="changelog">
          {PREVIEW_CHANGELOG.map((v, i) => (
            <Panel key={v.version} className="release reveal" style={{ '--i': i + 1 } as CSSProperties}>
              <header>
                <strong>Version {v.version}</strong>
                <small>{v.date}</small>
              </header>
              <div className="release__groups">
                {v.groups.map((g) => (
                  <div key={g.kind} className="release__group">
                    <Chip theme={g.theme}>{g.kind}</Chip>
                    <ul>
                      {g.items.map((it) => (
                        <li key={it}>{it}</li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            </Panel>
          ))}
        </div>
      )}

      <Modal open={open !== null} onClose={() => setOpen(null)} theme={open?.theme}>
        {open && (
          <article className="reader">
            <div className="reader__art">
              <Landscape theme={open.theme} scene={open.scene} mode="card" />
            </div>
            <span className="ncard__meta">
              <Chip theme={open.theme}>{open.category}</Chip>
              <small>
                {open.date} · {open.author}
              </small>
            </span>
            <h2 className="modal__title">{open.title}</h2>
            {open.body.map((p, i) => (
              <p key={i}>{p}</p>
            ))}
          </article>
        )}
      </Modal>
    </div>
  );
}
