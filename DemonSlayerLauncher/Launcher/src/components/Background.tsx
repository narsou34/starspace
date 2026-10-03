import hero from '../assets/hero.jpg';
import { Particles } from './Particles';

/** Fond immersif : illustration, brume, braises, motif seigaiha et grain. */
export function Background({ variant }: { variant: 'auth' | 'app' | 'boot' }) {
  return (
    <div className={`bg bg--${variant}`} aria-hidden="true">
      <div className="bg__base" />
      <img className="bg__blur" src={hero} alt="" draggable={false} />
      <div className="bg__glow" />
      <img className="bg__hero" src={hero} alt="" draggable={false} />
      <div className="bg__mist bg__mist--1" />
      <div className="bg__mist bg__mist--2" />
      <div className="bg__mist bg__mist--3" />
      <Particles count={variant === 'app' ? 28 : 40} />
      <div className="bg__pattern" />
      <div className="bg__vignette" />
      <div className="bg__grain" />
    </div>
  );
}
