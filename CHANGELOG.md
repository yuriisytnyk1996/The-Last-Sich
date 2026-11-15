# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

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
