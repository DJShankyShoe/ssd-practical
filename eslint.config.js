// Flat config. Runs eslint-plugin-security over the browser-side code so the
// pipeline fails on insecure JavaScript patterns (unsafe regex, eval, dynamic
// object injection, and similar).
const security = require("eslint-plugin-security");

module.exports = [
  {
    files: ["app/static/js/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script",
      globals: {
        document: "readonly",
        window: "readonly",
      },
    },
    plugins: { security },
    rules: {
      ...security.configs.recommended.rules,
      // Plain correctness checks worth failing on too.
      "no-eval": "error",
      "no-implied-eval": "error",
      "no-unused-vars": "error",
      "no-undef": "error",
      // Modern-syntax rules, matching what SonarQube reports.
      "no-var": "error",
      "prefer-const": "error",
    },
  },
];
