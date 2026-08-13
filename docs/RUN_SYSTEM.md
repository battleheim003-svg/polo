# Chogan Run System

The vertical slice run is a deterministic cup path driven by `domain/run/run_engine.gd` and serialized by `domain/run/run_state.gd`.

## Flow

`MATCH -> EVENT/CAMP -> MATCH/ELITE -> MARKET/CAMP -> BOSS`

Node types:

- `MATCH`: standard rival match.
- `EVENT`: choice node for coins, credit, or a stat drill.
- `CAMP`: recovery or focus training.
- `MARKET`: spend coins for an upgrade.
- `ELITE`: harder match with the same reward loop.
- `BOSS`: final Cup Guardians match.

The map changes by seed and remains stable for save/continue.

## Rewards

Rewards modify run-level upgrades such as strike, control, focus, stamina, and line play. The current match engine remains domain-owned; UI only selects nodes, lineups, and commands.
