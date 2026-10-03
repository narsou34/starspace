export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'INVALID_CREDENTIALS'
  | 'ACCOUNT_LOCKED'
  | 'ACCOUNT_SUSPENDED'
  | 'USERNAME_TAKEN'
  | 'EMAIL_TAKEN'
  | 'REGISTRATION_DISABLED'
  | 'UNAUTHORIZED'
  | 'SESSION_EXPIRED'
  | 'FORBIDDEN'
  | 'INVALID_RESET_CODE'
  | 'NOT_FOUND'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';

/** Erreur métier renvoyée au client sous la forme { error: { code, message } }. */
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const Errors = {
  unauthorized: () => new AppError(401, 'UNAUTHORIZED', 'Authentification requise.'),
  sessionExpired: () =>
    new AppError(401, 'SESSION_EXPIRED', 'Votre session a expiré. Veuillez vous reconnecter.'),
  forbidden: () => new AppError(403, 'FORBIDDEN', "Vous n'avez pas la permission d'effectuer cette action."),
  notFound: (what = 'Ressource') => new AppError(404, 'NOT_FOUND', `${what} introuvable.`),
  invalidCredentials: () =>
    new AppError(401, 'INVALID_CREDENTIALS', 'Identifiant ou mot de passe incorrect.'),
  suspended: (status: string) =>
    new AppError(
      403,
      'ACCOUNT_SUSPENDED',
      status === 'banned' ? 'Ce compte a été banni.' : 'Ce compte est suspendu.',
      { status },
    ),
  locked: (retryAfterSeconds: number) =>
    new AppError(
      429,
      'ACCOUNT_LOCKED',
      `Trop de tentatives échouées. Réessayez dans ${Math.max(1, Math.ceil(retryAfterSeconds / 60))} min.`,
      { retryAfterSeconds },
    ),
};
