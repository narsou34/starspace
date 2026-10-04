import { Icon, type IconName } from './Icons';

/** Pastille d'icône colorée (couleur = variable CSS --accent héritée). */
export function IconTile({ name, size = 'md' }: { name: IconName; size?: 'sm' | 'md' | 'lg' }) {
  const px = size === 'lg' ? 22 : size === 'md' ? 18 : 16;
  return (
    <span className={`itile itile--${size}`}>
      <Icon name={name} size={px} />
    </span>
  );
}
