import { VerticalKanji } from '../components/VerticalKanji';
import { BREATHS, accentStyle, type NavItem } from './navigation';

/** Section prévue dans une phase ultérieure : présentée clairement comme telle. */
export function ComingSoonView({ item }: { item: NavItem }) {
  return (
    <section className="soon" style={accentStyle(item.breath)}>
      <VerticalKanji text={item.kanji} className="soon__kanji" />
      <p className="soon__breath">
        {BREATHS[item.breath].title} · Phase {item.phase}
      </p>
      <h1 className="page-title">{item.label}</h1>
      <p className="soon__text">{item.description}</p>
      <div className="soon__seal">
        <span>近日</span>
        <small>Bientôt disponible</small>
      </div>
    </section>
  );
}
