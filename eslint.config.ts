// Lints the JS/TS tooling code (release scripts, configs, docs site config).
// Style rules: docs/guide/conventions.md
import js from '@eslint/js'
import { defineConfig } from 'eslint/config'
import stylistic from '@stylistic/eslint-plugin'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default defineConfig(
  {
    ignores: ['node_modules/', '.godot/', 'docs/.vitepress/cache/', 'docs/.vitepress/dist/'],
  },

  js.configs.recommended,
  tseslint.configs.recommended,

  stylistic.configs.customize({
    indent: 2,
    quotes: 'single',
    semi: false,
    commaDangle: 'always-multiline',
    braceStyle: '1tbs',
  }),

  {
    languageOptions: {
      globals: globals.node,
    },
    rules: {
      // Arrow functions use a block body with an explicit return.
      'arrow-body-style': ['error', 'always'],

      // Every if/else/loop body is wrapped in braces, never on one line.
      'curly': ['error', 'all'],

      // Arrow parameters always in parentheses: (value) => { ... }
      '@stylistic/arrow-parens': ['error', 'always'],

      // Blank lines between logical blocks inside a function.
      '@stylistic/padding-line-between-statements': [
        'error',
        { blankLine: 'always', prev: '*', next: ['return', 'throw'] },
        { blankLine: 'always', prev: ['const', 'let', 'var'], next: '*' },
        { blankLine: 'any', prev: ['const', 'let', 'var'], next: ['const', 'let', 'var'] },
        { blankLine: 'always', prev: '*', next: ['block-like', 'multiline-expression'] },
        { blankLine: 'always', prev: ['block-like', 'multiline-expression'], next: '*' },
      ],
    },
  },
)
