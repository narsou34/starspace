import { z } from 'zod';
import { AppError } from './errors.js';

/** Valide `data` avec `schema` ou lève une erreur 400 lisible. */
export function parse<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  const result = schema.safeParse(data ?? {});
  if (!result.success) {
    const fields: Record<string, string> = {};
    for (const issue of result.error.issues) {
      const key = issue.path.join('.') || '_';
      fields[key] ??= issue.message;
    }
    throw new AppError(400, 'VALIDATION_ERROR', 'Certaines informations sont invalides.', { fields });
  }
  return result.data;
}

// ── Règles partagées ──────────────────────────────────────────
export const usernameSchema = z
  .string({ error: 'Pseudo requis.' })
  .trim()
  .min(3, 'Le pseudo doit contenir au moins 3 caractères.')
  .max(20, 'Le pseudo ne peut pas dépasser 20 caractères.')
  .regex(/^[A-Za-z0-9_.-]+$/, 'Lettres, chiffres, « _ », « . » et « - » uniquement.');

export const emailSchema = z
  .string({ error: 'Adresse e-mail requise.' })
  .trim()
  .max(254)
  .pipe(z.email('Adresse e-mail invalide.'));

export const passwordSchema = z
  .string({ error: 'Mot de passe requis.' })
  .min(10, 'Le mot de passe doit contenir au moins 10 caractères.')
  .max(128, 'Le mot de passe ne peut pas dépasser 128 caractères.')
  .refine((p) => /[A-Za-z]/.test(p) && /[0-9]/.test(p), 'Utilisez au moins une lettre et un chiffre.');

export const deviceNameSchema = z
  .string()
  .trim()
  .max(100)
  .optional()
  // On retire les caractères de contrôle d'un champ purement informatif.
  .transform((v) => (v ? v.replace(/[\u0000-\u001f\u007f]/g, '') : undefined));
