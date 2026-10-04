import type { CSSProperties } from 'react';
import { Icon } from '../../components/Icons';
import { useToast } from '../../components/Toasts';
import { Panel, PreviewTag } from '../../components/ui';
import { PREVIEW_SHOP } from '../../models/preview';
import { THEMES, themeVars } from '../../theme/themes';

export function ShopView() {
  const toast = useToast();
  return (
    <div className="shop">
      <header className="shop__head reveal" style={{ '--i': 0 } as CSSProperties}>
        <div>
          <p className="kicker">商店 · Cosmétiques</p>
          <h1 className="page-title">Boutique</h1>
          <p className="lead">Tenues, gardes de sabre et compagnons. Purement esthétiques : aucun avantage en jeu.</p>
        </div>
        <div className="shop__balance">
          <PreviewTag />
          <Panel className="balance">
            <Icon name="star" size={18} />
            <span>
              <small>Solde</small>
              <strong>— pièces</strong>
            </span>
          </Panel>
        </div>
      </header>

      <div className="shop__grid">
        {PREVIEW_SHOP.map((item, i) => (
          <article key={item.name} className="item reveal" style={{ ...themeVars(item.theme), '--i': i + 1 } as CSSProperties}>
            <div className="item__art">
              <span className="item__kanji">{THEMES[item.theme].kanji}</span>
              <span className="item__ring" />
            </div>
            <span className={`item__rarity item__rarity--${item.rarity === 'Légendaire' ? 'legend' : item.rarity === 'Épique' ? 'epic' : 'rare'}`}>
              {item.rarity}
            </span>
            <strong>{item.name}</strong>
            <small>{item.type}</small>
            <button
              type="button"
              className="item__buy"
              onClick={() => toast.show('info', 'Boutique bientôt ouverte', 'La boutique sera disponible dans une prochaine mise à jour.')}
            >
              <Icon name="star" size={14} /> {item.price}
            </button>
          </article>
        ))}
      </div>
    </div>
  );
}
