# Object pooling

`autoload/pool.gd` (autoload **`Pool`**) reuses projectiles and blasts instead of freeing them. They live for a fraction of a second and are spawned many times a fight; instantiating a scene each time costs allocations and can stall the first shot of a fight while the scene loads.

## How it works

1. A spawner calls `Pool.prewarm(scene, count)` in its `_ready()`. The pool makes sure at least `count` instances of that scene are parked, so the first shots don't stall. Calls add up only to the largest `count`, not the sum: three musketeers in a room still park two balls.
2. To fire, the spawner calls `Pool.take(scene)` instead of `scene.instantiate()`. It gets a parked instance, or a new one when none is free (the pool grows as needed, it has no cap). The node is out of the tree; the spawner sets it up (`launch()`) and adds it with `add_child()` as before.
3. When a used node is taken again, the pool calls its `_on_pool_reuse()` first, because `_ready()` only ever runs once. `Hitbox` defines it: damage back to the scene's value (spawners scale it), `attacker_stats` cleared, `executes` and `critical` off, and the hitbox switched back to `active_on_start`.
4. Where the projectile used to `queue_free()`, it calls `Pool.release(self)`: on a hit, a wall, a shield, its lifetime ending, or a room change. The node is marked free at once and leaves the tree deferred, because an area can't leave the tree in the middle of a physics callback.
5. Parked nodes are freed only when the game quits.

`release()` is safe to call more than once. Parked nodes stay connected to `Events.room_change_requested`, so they hear room changes while parked; the second release is ignored. A node that wasn't made by `take()` (placed by hand in a scene) is simply freed.

Code that holds on to a projectile checks `Pool.in_use(node)`, not `is_instance_valid()`: a parked node is still a valid object. The ranged bolt uses this to allow one bolt at a time.

## What is pooled

| Scene | Script | Spawned by | Prewarmed |
|---|---|---|---|
| `musket_ball.tscn` | `EnemyProjectile` | `MusketShot` | 2 |
| `turret_bolt.tscn` | `EnemyProjectile` | `Turret` | 2 |
| `otaman/pistol_ball.tscn` | `EnemyProjectile` | the Otaman's `PistolVolley` | `shots` |
| `otaman/shockwave.tscn` | `EnemyProjectile` | the Otaman's `LeapSlam` | 2 |
| `ranged_bolt.tscn` | `PlayerProjectile` | `PlayerRangedAttack` | 1 |
| `charged_wave.tscn` | `PlayerProjectile` | `PlayerChargedAttack` | 1 |
| `duma_shot.tscn` | `PlayerProjectile` | `VolleyEffect` | none (an item effect is a resource) |
| `bolt_burst.tscn`, `dive_shockwave.tscn`, duma blasts (`fire_pillar`, `thunder_beam`, `stun_burst`) | `PlayerBlast` | `PlayerBlast.spawn()` (returning bolt, dive, `BlastRowEffect`) | 1 for the bolt burst and the dive |

Not pooled: rooms, the death mark, executions, summons and the sabre ring. They are spawned rarely or live for a long time.

## Files

| File | Role |
|---|---|
| `autoload/pool.gd` | The pool: `take()`, `release()`, `in_use()`, `prewarm()` |
| `components/combat/hitbox.gd` | `_on_pool_reuse()`: resets the hitbox state every pooled attack shares |
| `actors/enemies/attacks/enemy_projectile.gd` | Releases itself instead of freeing |
| `actors/player/attacks/player_projectile.gd` | Releases itself; `launch()` resets the flight |
| `actors/player/attacks/player_blast.gd` | `spawn()` takes from the pool and sets it off (`_go_off()`); releases itself |

## Extending

To pool a new short-lived scene:

1. Spawn it with `Pool.take(scene)` and prewarm it in the spawner's `_ready()`.
2. Replace its `queue_free()` calls with `Pool.release(self)`.
3. Put everything that `_ready()` or the node's life changes back: in `launch()` or a similar setup call, or in `_on_pool_reuse()` (call `super()` when the parent class defines it, as `Hitbox` does).
4. Don't connect signals or emit one-time effects in `_ready()` if they must happen on every spawn; `_ready()` runs once. `PlayerBlast` shakes the camera in `_go_off()` for this reason.

## Known limitations

- Pools never shrink. Fine for a handful of small scenes; a scene spawned in the hundreds would keep them all.
- No visual effects are pooled yet, because there are none (hit sparks, dust and the like are on the [roadmap](/roadmap)). They should use the same pool when added.
