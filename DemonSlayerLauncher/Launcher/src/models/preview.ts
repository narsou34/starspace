/**
 * DONNÉES D'EXEMPLE (aperçu du design).
 *
 * Ces sections seront reliées à l'API dans les phases suivantes :
 * personnages & whitelist (phase 2), tickets & actualités (phase 3),
 * statut serveur en direct (phase 4). Chaque écran qui les affiche
 * porte une étiquette « Aperçu ».
 */
import type { ThemeId } from '../theme/themes';
import type { SceneId } from '../scenery/Landscape';
import type { ReviewStatus } from '../components/ui';

export const PREVIEW_SERVER = {
  online: true,
  players: 42,
  maxPlayers: 100,
  version: '1.2.0',
  map: 'Demon Slayer World',
  uptime: '18 h 42 min',
  nextRestart: '04:00',
  peakToday: 77,
  /** Joueurs connectés sur les 12 dernières heures (graphique). */
  history: [18, 22, 15, 11, 9, 14, 23, 31, 38, 47, 51, 42],
};

export const PREVIEW_CHARACTER = {
  name: 'Akira Narsou',
  faction: 'Pourfendeur',
  grade: 'Kanoe',
  gradeRank: 6,
  gradeTotal: 10,
  breath: "Souffle de l'Eau",
  breathTheme: 'water' as ThemeId,
  level: 24,
  xp: 68,
  playtime: '82 h',
  status: 'Actif',
  stats: [
    { label: 'Maîtrise', value: 82 },
    { label: 'Combat', value: 67 },
    { label: 'Endurance', value: 74 },
    { label: 'Agilité', value: 59 },
  ],
  techniques: [
    { form: 'Première forme', name: 'Taille de la surface de l’eau', unlocked: true },
    { form: 'Deuxième forme', name: 'Roue à eau', unlocked: true },
    { form: 'Quatrième forme', name: 'Vague frappante', unlocked: true },
    { form: 'Dixième forme', name: 'Dragon de la métamorphose', unlocked: false },
  ],
};

export const PREVIEW_PROFILE = {
  whitelist: 'accepted' as ReviewStatus,
  playtime: '127 h',
  level: 24,
  xp: 68,
  stats: [
    { label: 'Démons vaincus', value: '312' },
    { label: 'Missions', value: '87' },
    { label: 'Événements', value: '14' },
    { label: 'Rang du serveur', value: '#23' },
  ],
  achievements: [
    { name: 'Premier souffle', desc: 'Maîtriser une première forme', theme: 'water' as ThemeId, done: true },
    { name: 'Nuit blanche', desc: 'Survivre jusqu’à l’aube', theme: 'moon' as ThemeId, done: true },
    { name: 'Lame écarlate', desc: 'Vaincre une Lune inférieure', theme: 'flame' as ThemeId, done: true },
    { name: 'Pilier', desc: 'Atteindre le rang de Pilier', theme: 'sun' as ThemeId, done: false },
  ],
  history: [
    { date: 'Aujourd’hui', text: 'Mission « Forêt de Natagumo » terminée' },
    { date: 'Hier', text: 'Promotion au grade Kanoe' },
    { date: '28 sept.', text: 'Forme de l’eau débloquée : Vague frappante' },
  ],
};

export interface NewsItem {
  id: number;
  category: 'Mise à jour' | 'Événement' | 'Maintenance' | 'Annonce';
  theme: ThemeId;
  scene: SceneId;
  title: string;
  excerpt: string;
  body: string[];
  date: string;
  author: string;
}

export const PREVIEW_NEWS: NewsItem[] = [
  {
    id: 1,
    category: 'Mise à jour',
    theme: 'water',
    scene: 'lake',
    title: 'Le Souffle de l’Eau reçoit un nouveau système de techniques',
    excerpt: 'Dix formes revues, enchaînements fluides et nouvelles animations de lame.',
    body: [
      'Les dix formes du Souffle de l’Eau ont été entièrement revues : chaque technique possède désormais sa propre fenêtre d’enchaînement.',
      'Les pourfendeurs peuvent combiner deux formes consécutives pour déclencher une variante plus puissante.',
    ],
    date: '3 octobre 2026',
    author: 'Équipe NDR',
  },
  {
    id: 2,
    category: 'Événement',
    theme: 'sun',
    scene: 'village',
    title: 'Festival des lanternes',
    excerpt: 'Le village s’illumine ce week-end : missions spéciales et récompenses.',
    body: ['Du vendredi au dimanche, des missions spéciales sont disponibles au village.'],
    date: '1er octobre 2026',
    author: 'Équipe événements',
  },
  {
    id: 3,
    category: 'Maintenance',
    theme: 'moon',
    scene: 'mountains',
    title: 'Maintenance programmée à 22h00',
    excerpt: 'Optimisation de la base de données et du réseau, durée estimée 30 minutes.',
    body: ['Le serveur sera indisponible environ 30 minutes.'],
    date: '29 septembre 2026',
    author: 'Équipe technique',
  },
  {
    id: 4,
    category: 'Annonce',
    theme: 'mist',
    scene: 'forest',
    title: 'Ouverture des candidatures Piliers',
    excerpt: 'Les joueurs les plus expérimentés peuvent postuler au rang de Pilier.',
    body: ['Les candidatures sont ouvertes jusqu’à la fin du mois.'],
    date: '25 septembre 2026',
    author: 'Administration',
  },
];

export const PREVIEW_EVENTS = [
  { title: 'Festival des lanternes', when: 'Samedi · 21h00', place: 'Village du Glycine', theme: 'sun' as ThemeId },
  { title: 'Chasse à la Lune inférieure', when: 'Dimanche · 20h30', place: 'Mont Natagumo', theme: 'demon' as ThemeId },
];

export const PREVIEW_CHANGELOG = [
  {
    version: '1.2.0',
    date: '3 octobre 2026',
    groups: [
      { kind: 'Nouveau', theme: 'wind' as ThemeId, items: ['Respiration de la Brume', 'Nouveau système de missions', 'Nouveau village'] },
      { kind: 'Amélioration', theme: 'water' as ThemeId, items: ['Optimisation du combat', 'Amélioration du HUD'] },
      { kind: 'Correction', theme: 'flame' as ThemeId, items: ['Bug de sauvegarde personnage', 'Bug de connexion'] },
    ],
  },
  {
    version: '1.1.0',
    date: '12 septembre 2026',
    groups: [
      { kind: 'Nouveau', theme: 'wind' as ThemeId, items: ['Système de grades', 'Forêt de Natagumo'] },
      { kind: 'Correction', theme: 'flame' as ThemeId, items: ['Désynchronisation des lames'] },
    ],
  },
];

export type TicketStatus = 'OUVERT' | 'EN COURS' | 'RÉPONDU' | 'FERMÉ';

export const TICKET_CATEGORIES: { id: string; label: string; theme: ThemeId }[] = [
  { id: 'support', label: 'Support', theme: 'water' },
  { id: 'tech', label: 'Problème technique', theme: 'moon' },
  { id: 'player', label: 'Joueur', theme: 'wind' },
  { id: 'staff', label: 'Staff', theme: 'mist' },
  { id: 'bug', label: 'Bug', theme: 'flame' },
  { id: 'donation', label: 'Donation', theme: 'sun' },
  { id: 'whitelist', label: 'Whitelist', theme: 'thunder' },
  { id: 'sanction', label: 'Sanction', theme: 'demon' },
  { id: 'other', label: 'Autre', theme: 'moon' },
];

export const PREVIEW_TICKETS = [
  {
    id: 124,
    title: 'Problème avec mon personnage',
    category: 'bug',
    priority: 'Haute',
    status: 'RÉPONDU' as TicketStatus,
    updated: 'il y a 12 min',
    unread: 1,
    messages: [
      { from: 'player', name: 'Narsou', time: '21:02', text: 'Bonjour, mon personnage a perdu sa forme débloquée après le redémarrage.' },
      { from: 'staff', name: 'Kagaya', role: 'Administrateur', time: '21:14', text: 'Bonjour Narsou, merci pour le signalement. Nous avons restauré la sauvegarde de 20h55, peux-tu vérifier en jeu ?' },
      { from: 'player', name: 'Narsou', time: '21:20', text: 'C’est bon, tout est revenu. Merci beaucoup !' },
      { from: 'staff', name: 'Kagaya', role: 'Administrateur', time: '21:22', text: 'Parfait ! Je laisse le ticket ouvert 24 h au cas où.' },
    ],
  },
  {
    id: 119,
    title: 'Question sur ma candidature',
    category: 'whitelist',
    priority: 'Normale',
    status: 'EN COURS' as TicketStatus,
    updated: 'hier',
    unread: 0,
    messages: [{ from: 'player', name: 'Narsou', time: '18:40', text: 'Combien de temps prend l’examen des candidatures ?' }],
  },
  {
    id: 102,
    title: 'Crash au lancement',
    category: 'tech',
    priority: 'Basse',
    status: 'FERMÉ' as TicketStatus,
    updated: '24 sept.',
    unread: 0,
    messages: [{ from: 'player', name: 'Narsou', time: '10:05', text: 'Le jeu crashait, résolu après mise à jour des pilotes.' }],
  },
];

export const PREVIEW_NOTIFICATIONS = [
  { icon: 'whitelist' as const, theme: 'thunder' as ThemeId, text: 'Votre candidature whitelist a été acceptée.', time: '2 h' },
  { icon: 'tickets' as const, theme: 'moon' as ThemeId, text: 'Votre ticket #124 a reçu une réponse.', time: '12 min' },
  { icon: 'refresh' as const, theme: 'wind' as ThemeId, text: 'Une nouvelle mise à jour est disponible.', time: '1 j' },
  { icon: 'clock' as const, theme: 'flame' as ThemeId, text: 'Le serveur sera en maintenance à 22h00.', time: '1 j' },
];

export const PREVIEW_SHOP = [
  { name: 'Haori de la Flamme', type: 'Tenue', rarity: 'Légendaire', theme: 'flame' as ThemeId, price: 1200 },
  { name: 'Garde de sabre — Vague', type: 'Accessoire', rarity: 'Épique', theme: 'water' as ThemeId, price: 650 },
  { name: 'Corbeau messager doré', type: 'Compagnon', rarity: 'Épique', theme: 'sun' as ThemeId, price: 800 },
  { name: 'Masque de renard', type: 'Accessoire', rarity: 'Rare', theme: 'mist' as ThemeId, price: 300 },
  { name: 'Lame de glycine', type: 'Apparence', rarity: 'Légendaire', theme: 'demon' as ThemeId, price: 1500 },
  { name: 'Lanterne spirituelle', type: 'Effet', rarity: 'Rare', theme: 'thunder' as ThemeId, price: 400 },
];
