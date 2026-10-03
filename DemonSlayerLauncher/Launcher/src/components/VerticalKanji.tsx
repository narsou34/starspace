/**
 * Kanji empilés verticalement. On n'utilise pas `writing-mode: vertical-rl`,
 * dont le rendu dépend des métriques verticales de la police installée.
 */
export function VerticalKanji({ text, className }: { text: string; className?: string }) {
  return (
    <p className={`vkanji${className ? ` ${className}` : ''}`} aria-hidden="true">
      {Array.from(text).map((char, i) => (
        <span key={i}>{char}</span>
      ))}
    </p>
  );
}
