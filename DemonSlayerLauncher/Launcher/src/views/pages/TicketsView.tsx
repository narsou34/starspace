import { useState, type CSSProperties, type FormEvent } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { Avatar } from '../../components/Avatar';
import { Button, Field } from '../../components/Form';
import { Icon } from '../../components/Icons';
import { useToast } from '../../components/Toasts';
import { Chip, Modal, Panel, PreviewTag } from '../../components/ui';
import { PREVIEW_TICKETS, TICKET_CATEGORIES, type TicketStatus } from '../../models/preview';

const STATUS_CLASS: Record<TicketStatus, string> = {
  OUVERT: 'open',
  'EN COURS': 'progress',
  RÉPONDU: 'answered',
  FERMÉ: 'closed',
};

type Filter = 'all' | 'open' | 'closed';

export function TicketsView() {
  const { user } = useAuth();
  const toast = useToast();
  const [filter, setFilter] = useState<Filter>('all');
  const [selected, setSelected] = useState(PREVIEW_TICKETS[0]!.id);
  const [composerOpen, setComposerOpen] = useState(false);
  const [draft, setDraft] = useState('');
  const [category, setCategory] = useState('support');

  const list = PREVIEW_TICKETS.filter((t) =>
    filter === 'all' ? true : filter === 'closed' ? t.status === 'FERMÉ' : t.status !== 'FERMÉ',
  );
  const ticket = PREVIEW_TICKETS.find((t) => t.id === selected)!;
  const cat = (id: string) => TICKET_CATEGORIES.find((c) => c.id === id)!;

  const send = (e: FormEvent) => {
    e.preventDefault();
    if (!draft.trim()) return;
    toast.show('info', 'Bientôt disponible', 'L’envoi de messages au staff sera activé en phase 3.');
  };

  return (
    <div className="tickets">
      <aside className="tickets__list reveal" style={{ '--i': 0 } as CSSProperties}>
        <header className="tickets__head">
          <div>
            <p className="kicker">Support · 相談</p>
            <h1 className="page-title page-title--sm">Mes tickets</h1>
          </div>
          <button type="button" className="iconbtn iconbtn--accent" aria-label="Nouveau ticket" onClick={() => setComposerOpen(true)}>
            <Icon name="plus" />
          </button>
        </header>
        <div className="filters">
          {(['all', 'open', 'closed'] as Filter[]).map((f) => (
            <button key={f} type="button" className={filter === f ? 'is-active' : ''} onClick={() => setFilter(f)}>
              {f === 'all' ? 'Tous' : f === 'open' ? 'Ouverts' : 'Fermés'}
            </button>
          ))}
          <PreviewTag phase={3} />
        </div>
        <ul>
          {list.map((t) => {
            const c = cat(t.category);
            return (
              <li key={t.id}>
                <button type="button" className={`tcard${t.id === selected ? ' is-active' : ''}`} onClick={() => setSelected(t.id)}>
                  <span className="tcard__top">
                    <Chip theme={c.theme}>{c.label}</Chip>
                    <span className={`tstatus tstatus--${STATUS_CLASS[t.status]}`}>{t.status}</span>
                  </span>
                  <strong>
                    #{t.id} · {t.title}
                  </strong>
                  <span className="tcard__meta">
                    <span className={`prio prio--${t.priority.toLowerCase()}`}>● {t.priority}</span>
                    <span>{t.updated}</span>
                    {t.unread > 0 && <span className="tcard__unread">{t.unread}</span>}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      </aside>

      <Panel className="convo reveal" style={{ '--i': 1 } as CSSProperties}>
        <header className="convo__head">
          <div>
            <strong>
              #{ticket.id} · {ticket.title}
            </strong>
            <span className="convo__meta">
              <Chip theme={cat(ticket.category).theme}>{cat(ticket.category).label}</Chip>
              <span className={`prio prio--${ticket.priority.toLowerCase()}`}>● Priorité {ticket.priority.toLowerCase()}</span>
              <span className={`tstatus tstatus--${STATUS_CLASS[ticket.status]}`}>{ticket.status}</span>
            </span>
          </div>
        </header>
        <div className="convo__body">
          {ticket.messages.map((m, i) => (
            <div key={i} className={`msg msg--${m.from}`} style={{ '--i': i } as CSSProperties}>
              {m.from === 'staff' ? (
                <span className="msg__avatar msg__avatar--staff">{m.name.charAt(0)}</span>
              ) : (
                user && <Avatar user={user} size={36} />
              )}
              <div className="msg__bubble">
                <header>
                  <strong>{m.name}</strong>
                  {'role' in m && m.role && <span className="msg__role">{m.role}</span>}
                  <time>{m.time}</time>
                </header>
                <p>{m.text}</p>
              </div>
            </div>
          ))}
        </div>
        <form className="composer" onSubmit={send}>
          <button type="button" className="iconbtn" aria-label="Joindre une capture" onClick={() => toast.show('info', 'Pièces jointes', 'Les captures d’écran pourront être jointes en phase 3.')}>
            <Icon name="clip" />
          </button>
          <input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Écrire une réponse…" maxLength={2000} />
          <button type="submit" className="iconbtn iconbtn--accent" aria-label="Envoyer">
            <Icon name="send" />
          </button>
        </form>
      </Panel>

      <Modal open={composerOpen} onClose={() => setComposerOpen(false)} theme="moon">
        <p className="kicker">Nouveau ticket</p>
        <h2 className="modal__title">Comment pouvons-nous aider ?</h2>
        <div className="catgrid">
          {TICKET_CATEGORIES.map((c) => (
            <button key={c.id} type="button" className={category === c.id ? 'is-active' : ''} onClick={() => setCategory(c.id)}>
              <Chip theme={c.theme}>{c.label}</Chip>
            </button>
          ))}
        </div>
        <Field label="Titre" placeholder="Problème avec mon personnage" maxLength={120} />
        <label className="area">
          <span>Message</span>
          <textarea rows={5} maxLength={4000} placeholder="Décrivez votre demande…" />
        </label>
        <Button
          className="btn--wide"
          onClick={() => {
            setComposerOpen(false);
            toast.show('info', 'Bientôt disponible', 'La création de tickets sera activée en phase 3.');
          }}
        >
          Ouvrir le ticket
        </Button>
      </Modal>
    </div>
  );
}
