import { Emblem } from '../components/Emblem';

export function BootView({ message }: { message: string }) {
  return (
    <div className="boot">
      <div className="boot__emblem">
        <Emblem size={104} />
      </div>
      <p className="boot__title">
        <span>NDR</span> Demon Slayer
      </p>
      <p className="boot__message">{message}</p>
      <div className="boot__bar">
        <span />
      </div>
    </div>
  );
}
