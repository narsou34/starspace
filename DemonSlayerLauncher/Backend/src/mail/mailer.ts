import type { FastifyBaseLogger } from 'fastify';
import nodemailer from 'nodemailer';
import type { Env } from '../config/env.js';

export interface Mailer {
  sendPasswordReset(to: string, username: string, code: string, expiresInMinutes: number): Promise<void>;
}

function resetText(username: string, code: string, minutes: number): string {
  return [
    `Bonjour ${username},`,
    '',
    'Une demande de réinitialisation de mot de passe a été effectuée pour votre compte NDR | Demon Slayer.',
    '',
    `Votre code : ${code}`,
    '',
    `Saisissez-le dans le launcher. Il expire dans ${minutes} minutes.`,
    "Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.",
  ].join('\n');
}

class SmtpMailer implements Mailer {
  private readonly transport;
  constructor(
    smtpUrl: string,
    private readonly from: string,
  ) {
    this.transport = nodemailer.createTransport(smtpUrl);
  }
  async sendPasswordReset(to: string, username: string, code: string, minutes: number): Promise<void> {
    await this.transport.sendMail({
      from: this.from,
      to,
      subject: 'NDR | Demon Slayer — Réinitialisation du mot de passe',
      text: resetText(username, code, minutes),
    });
  }
}

/** Développement uniquement : le code est écrit dans la console. */
class ConsoleMailer implements Mailer {
  constructor(
    private readonly log: FastifyBaseLogger,
    private readonly revealCodes: boolean,
  ) {}
  async sendPasswordReset(to: string, username: string, code: string): Promise<void> {
    if (this.revealCodes) {
      this.log.warn({ to, username, code }, '[DEV] Code de réinitialisation (aucun SMTP configuré)');
    } else {
      this.log.error({ to }, 'SMTP_URL non configuré : impossible d’envoyer l’e-mail de réinitialisation');
    }
  }
}

export function createMailer(env: Env, log: FastifyBaseLogger): Mailer {
  if (env.SMTP_URL) return new SmtpMailer(env.SMTP_URL, env.MAIL_FROM);
  return new ConsoleMailer(log, env.NODE_ENV !== 'production');
}
