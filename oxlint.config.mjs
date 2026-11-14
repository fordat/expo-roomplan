import { defineConfig } from 'oxlint';
import base from 'expo-module-scripts/oxlint.config.base.js';

export default defineConfig({
  extends: [base],
  // oxlint doesn't inherit ignorePatterns through `extends`.
  ignorePatterns: [...base.ignorePatterns, 'example/**'],
});
