# Currency

The player earns currency by killing enemies. It will pay for shops and paid cleanse points later (see [Roadmap](/roadmap)). Death marks lower how much each kill gives, see [Death penalty](/systems/death-penalty).

## How it works

1. An enemy dies. `EnemyDamage._on_died()` sends `Events.currency_earned(currency_reward)`.
2. `PlayerWallet` (`actors/player/abilities/wallet.gd`) multiplies it by `gain_factor`, rounds it and adds it. `DeathPenalty` sets `gain_factor` from the number of death marks.
3. Every change goes out as `Events.player_currency_changed(amount)`. `CurrencyCounter` in the HUD shows the number and flashes on a gain.

An enemy that is laid dead on room load (killed earlier, see [Enemies](/systems/enemies)) gives no reward a second time. Enemies that fall into pits still pay out.

`PlayerWallet.add()` adds an amount as is, without `gain_factor`.

The wallet is a global save system (`wallet`, see [Save system](/systems/save-system)), written when the player rests or dies.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/wallet.gd` | `PlayerWallet`: the currency the player carries, gain factor, saved |
| `actors/enemies/enemy_damage.gd` | Sends `currency_earned` on death |
| `ui/hud/currency_counter.gd` | HUD number, flashes on gain |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `EnemyDamage.currency_reward` | 10 | Currency for killing this enemy, before `gain_factor` |
| `CurrencyCounter.flash_time` | 0.3 | Seconds the number flashes after a gain |
| `CurrencyCounter.normal_color` | `#d89a3a` | Number colour |
| `CurrencyCounter.flash_color` | `#fff2c8` | Number colour while flashing |

The gain factor per number of death marks is tuned on `DeathPenalty`, see [Death penalty](/systems/death-penalty#tuning).

## Extending

- **Spending (shops, paid cleanse):** add `spend(value) -> bool` to `PlayerWallet`.
- **Other income** (chests, quest rewards): emit `Events.currency_earned`, or call `wallet.add()` for an amount that ignores death marks.

## Known limitations

- Nothing to spend currency on yet.
- The HUD number is the default font, with no icon.
