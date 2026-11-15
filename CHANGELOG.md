# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [0.0.4](https://github.com/yuriisytnyk1996/The-Last-Sich/compare/v0.0.3...v0.0.4) (2026-11-15)

### Features

* **save:** save the last rest point to disk and load it on start ([843072b](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/843072b13cf079695c4aaa6b493f28029eda36db))

## [0.0.3](https://github.com/yuriisytnyk1996/The-Last-Sich/compare/v0.0.2...v0.0.3) (2026-11-15)

### Features

* **combat:** add hit-stop, camera shake, hit flash and hit reactions ([87802d6](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/87802d6bcccb0027efe9bf2228c9a9302b3568e1))
* **enemies:** add enemy base and the raider, a patrolling melee grunt ([595ef84](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/595ef842dd2e4d23db0bb6516acd6e7ec94c4407))
* **enemies:** add poise so enemies strike back after repeated staggers ([17b8f68](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/17b8f6865a1c0683abd563c1b3fac6e14b86ce2a))
* **player:** add a hard landing after long falls ([c23e73d](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/c23e73d1e3d3018f1e7984060581aedb45b056a9))
* **player:** add health, hurt state with knockback, invincibility and death ([d4df6f0](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/d4df6f006be007434a7dd529d3ed975868f5f447))
* **player:** add ladders with climbing across rooms ([87de396](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/87de39624887fbd356fe3fe0a918144c0bd8e15b))
* **player:** drop through one-way platforms with down + jump ([fff6228](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/fff622889fd28184e60d01ac0ed20d85dd4ce6f9))
* **rooms:** add doors entered by pressing up ([b15dcab](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/b15dcabfe491accd1380ce4ea8857707567f20f2))
* **rooms:** add rest points that heal and set the respawn ([6d84da8](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/6d84da8479eab5c2b46621f21a9586fc48570805))
* **rooms:** add room transitions through edge exits with a screen fade ([402cc48](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/402cc48f1a18acda90581838a64172b01b2467aa))
* **rooms:** add TileMapLayer terrain and rebuild the test room on the tile grid ([9050432](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/9050432c5adc4a3256358a75808e7e417257f7ea))
* **rooms:** add vertical exits through floor holes and ceiling openings ([c8d81fa](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/c8d81fad6082378f8d35a6626d0e97a938b32814))
* **rooms:** make bottomless pits an instant death through the Dead state ([3e7beef](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/3e7beef1ded86db8739db8e0955aaf296858f924))
* **ui:** add HUD health bar with trailing loss segment ([310df93](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/310df93b1b8125886d2bd55b93ddb6d572c6645b))

### Bug Fixes

* **player:** jump off ladders with up held and freeze the body in pits ([f754f71](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/f754f717cbdd5e1e46f33d21f00a3759f87d639e))
* **player:** make dash a ground-only move ([1605659](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/160565979ce27876abd5597a16d89753aac187ee))

### Refactoring

* **player:** move drop-through into an ability node ([8244b88](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/8244b88561a36a8fe5797e38a77dac6215825744))

## [0.0.2](https://github.com/yuriisytnyk1996/The-Last-Sich/compare/v0.0.1...v0.0.2) (2026-11-15)

### Features

* **combat:** add hitbox, hurtbox and health components and player attack ([31f3939](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/31f393955113883dbd03e4e48ffe224c79cb4ebe))
* **combat:** add up and crouch attacks with planted ground swings ([72093e5](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/72093e5690ab11736c6785809fd540ab13d02ae8))
* **rendering:** add display settings with scaling mode and fullscreen ([a0cad89](https://github.com/yuriisytnyk1996/The-Last-Sich/commit/a0cad89ff87c764989e0cbae4abf6a5f891467fb))

## 0.0.1 (2026-11-15)

### Features

* **rendering:** pixel-art project settings (640×360, integer scaling, nearest filtering, pixel snapping), Forward+ on desktop and Mobile renderer on phones with 2D HDR
* **input:** input map for keyboard and gamepad
* **events:** `Events` autoload signal bus
* **state-machine:** reusable `StateMachine` and `State` components
* **player:** Idle, Run, Jump, Fall and Dash states with coyote time, jump buffering, variable jump height and air dash
* **rooms:** `Room` base script and test room with camera bounds, kill zone and respawn
* **ui:** debug state label and version label
* **docs:** VitePress documentation site, code organization rules and file size check
* **tooling:** Conventional Commits with commitlint and lefthook, automated versioning and changelog with commit-and-tag-version
