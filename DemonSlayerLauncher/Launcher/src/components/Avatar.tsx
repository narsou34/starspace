import type { User } from '../models/types';

/** Avatar : image du compte si disponible, sinon initiale stylisée. */
export function Avatar({ user, size = 40 }: { user: Pick<User, 'username' | 'avatarUrl'>; size?: number }) {
  return (
    <span className="avatar" style={{ width: size, height: size, fontSize: size * 0.42 }}>
      {user.avatarUrl ? (
        <img src={user.avatarUrl} alt="" referrerPolicy="no-referrer" />
      ) : (
        <span>{user.username.charAt(0).toUpperCase()}</span>
      )}
    </span>
  );
}
