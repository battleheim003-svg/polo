# Architecture

## Layers

`domain/match` contains the pure match model and simulation engine. It has no dependency on scenes, UI, AnimationPlayer, or SceneTree.

`data` contains JSON prototype content for riders, horses, teams, and tactics.

`autoload` contains session, save, and audio services used by scenes.

`scenes` contains Boot, Menu, Preparation, Match, and Results screens. Scene scripts display state and consume match events; they do not own core match rules.

`tests` and `tools` run the domain layer headlessly.

## Data Flow

`DataRepository` loads JSON into typed definitions. `GameSession` creates `MatchEngine`, starts a seeded `MatchState`, and exposes `tick(command)`.

The Match scene calls `GameSession.tick`, receives a batch of `MatchEvent` objects, queues them for display, and animates the ball between five logical zones with Tween. Display speed changes only event playback timing, not match results.

## Event Structure

Every important engine change is emitted as `MatchEvent` with:

- `type`
- `message`
- `payload`

Implemented event types include chukker start/end, possession, line owner changes through ride-off, strike, pass, hook, recovery, shot, goal, focus, stamina, skill activation, coach command, foul, free hit, substitution, and match end.

## Seed System

`DeterministicRng` is a small linear congruential generator stored inside `MatchState.rng_state`. The same seed and command stream produce the same final snapshot.

## Extending Content

Add a rider in `data/riders/riders.json`, then reference an existing horse id. Add a horse in `data/horses/horses.json` with speed, stamina, calmness, coordination, and trait. Add a tactic in `data/tactics/tactics.json`; wire its mechanical effect in `MatchEngine._tactic_bonus`. Add AI behavior in `RuleAi.choose_command`.
