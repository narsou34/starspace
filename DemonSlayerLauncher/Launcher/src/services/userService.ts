import { bridge } from '../api/bridge';
import type { AccountSession, Profile } from '../models/types';

export const userService = {
  profile: () => bridge.request<Profile>('GET', '/api/user/profile'),

  sessions: async () => (await bridge.request<{ sessions: AccountSession[] }>('GET', '/api/user/sessions')).sessions,

  revokeSession: (id: string) => bridge.request<void>('DELETE', `/api/user/sessions/${encodeURIComponent(id)}`),

  changePassword: (currentPassword: string, newPassword: string) =>
    bridge.request<{ message: string }>('POST', '/api/user/password', { currentPassword, newPassword }),
};
