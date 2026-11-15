---
layout: home

hero:
  name: The Last Sich
  text: Developer documentation
  tagline: How the game is built, how each system works, and how to extend it.
  actions:
    - theme: brand
      text: Getting started
      link: /guide/getting-started
    - theme: alt
      text: Architecture
      link: /architecture/overview

features:
  - title: Architecture
    details: Autoloads, the Events signal bus and the reusable state machine that everything is built on.
    link: /architecture/overview
  - title: Player
    details: Movement states, jump math, coyote time, jump buffering, dash and every tuning value.
    link: /systems/player
  - title: Rooms
    details: How a level room is put together, camera bounds, kill zones and respawning.
    link: /systems/rooms
  - title: Rendering
    details: Renderer choice for desktop and mobile, and the settings that keep pixel art crisp.
    link: /systems/rendering
---
