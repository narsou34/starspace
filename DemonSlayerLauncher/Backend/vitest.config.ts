import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    // Les tests partagent une base PostgreSQL : exécution séquentielle.
    fileParallelism: false,
    testTimeout: 20000,
    hookTimeout: 30000,
  },
});
