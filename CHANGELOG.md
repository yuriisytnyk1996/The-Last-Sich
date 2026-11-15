# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

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
