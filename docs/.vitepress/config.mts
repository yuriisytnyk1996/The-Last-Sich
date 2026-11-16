import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'The Last Sich',
  description: 'Developer documentation for The Last Sich',
  cleanUrls: true,
  lastUpdated: true,

  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Architecture', link: '/architecture/overview' },
      { text: 'Systems', link: '/systems/player' },
      { text: 'Roadmap', link: '/roadmap' },
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Project structure', link: '/guide/project-structure' },
          { text: 'Code organization', link: '/guide/code-organization' },
          { text: 'Conventions', link: '/guide/conventions' },
          { text: 'Writing docs', link: '/guide/writing-docs' },
          { text: 'Versioning & releases', link: '/guide/versioning' },
        ],
      },
      {
        text: 'Architecture',
        items: [
          { text: 'Overview', link: '/architecture/overview' },
          { text: 'Events (signal bus)', link: '/architecture/events' },
          { text: 'State machine', link: '/architecture/state-machine' },
        ],
      },
      {
        text: 'Systems',
        items: [
          { text: 'Player', link: '/systems/player' },
          { text: 'Combat', link: '/systems/combat' },
          { text: 'Enemies', link: '/systems/enemies' },
          { text: 'Game feel', link: '/systems/game-feel' },
          { text: 'HUD', link: '/systems/hud' },
          { text: 'Rooms', link: '/systems/rooms' },
          { text: 'Environment', link: '/systems/environment' },
          { text: 'Rest points', link: '/systems/rest-points' },
          { text: 'Map', link: '/systems/map' },
          { text: 'Spirit', link: '/systems/spirit' },
          { text: 'Currency', link: '/systems/currency' },
          { text: 'Skills', link: '/systems/skills' },
          { text: 'Death penalty', link: '/systems/death-penalty' },
          { text: 'Save system', link: '/systems/save-system' },
          { text: 'Input', link: '/systems/input' },
          { text: 'Menus', link: '/systems/menus' },
          { text: 'Options', link: '/systems/options' },
          { text: 'Rendering & pixel art', link: '/systems/rendering' },
        ],
      },
      {
        text: 'Project',
        items: [
          { text: 'Roadmap', link: '/roadmap' },
          { text: 'Changelog', link: '/changelog' },
        ],
      },
    ],

    search: { provider: 'local' },
    outline: [2, 3],
  },
})
