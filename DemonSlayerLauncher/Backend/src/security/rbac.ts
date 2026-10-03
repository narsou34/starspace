/**
 * Contrôle d'accès basé sur les rôles (RBAC).
 * Les rôles sont TOUJOURS relus en base à chaque requête : le contenu
 * du token n'est jamais considéré comme une source de vérité.
 */
export const ROLES = ['player', 'helper', 'moderator', 'admin', 'superadmin'] as const;
export type Role = (typeof ROLES)[number];

export const PERMISSIONS = [
  'admin.access',
  'users.read',
  'users.manage',
  'whitelist.review',
  'tickets.manage',
  'sanctions.read',
  'sanctions.manage',
  'characters.edit',
  'characters.delete',
  'news.publish',
  'logs.read',
] as const;
export type Permission = (typeof PERMISSIONS)[number];

const ROLE_PERMISSIONS: Record<Role, readonly Permission[]> = {
  player: [],
  helper: ['admin.access', 'users.read', 'tickets.manage'],
  moderator: [
    'admin.access',
    'users.read',
    'whitelist.review',
    'tickets.manage',
    'sanctions.read',
    'sanctions.manage',
  ],
  admin: [
    'admin.access',
    'users.read',
    'users.manage',
    'whitelist.review',
    'tickets.manage',
    'sanctions.read',
    'sanctions.manage',
    'characters.edit',
    'news.publish',
    'logs.read',
  ],
  superadmin: PERMISSIONS,
};

export function isRole(value: string): value is Role {
  return (ROLES as readonly string[]).includes(value);
}

export function permissionsFor(role: Role): readonly Permission[] {
  return ROLE_PERMISSIONS[role];
}

export function hasPermission(role: Role, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role].includes(permission);
}
