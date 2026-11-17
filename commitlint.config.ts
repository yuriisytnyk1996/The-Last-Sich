// Conventional Commits: https://www.conventionalcommits.org
// Format: type(scope): summary   e.g. feat(player): add wall jump
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Known scopes. Unknown scopes only warn, so new systems can add their own.
    'scope-enum': [
      1,
      'always',
      [
        'player',
        'enemies',
        'bosses',
        'combat',
        'stats',
        'rooms',
        'environment',
        'traversal',
        'ui',
        'input',
        'rendering',
        'audio',
        'save',
        'currency',
        'skills',
        'inventory',
        'shops',
        'spirit',
        'death-penalty',
        'map',
        'travel',
        'state-machine',
        'events',
        'docs',
        'tooling',
        'release',
      ],
    ],
  },
}
