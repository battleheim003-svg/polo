# Interactive Match Architecture

## Goal

Add a live 2D match layer while preserving the existing headless simulation, run, save, rewards, data, and tests.

## Field Units

- Logical field size: 1600 x 820 units.
- Goal mouths: centered vertically at x = 40 and x = 1560.
- Play bounds: x 80..1520, y 90..730.
- Screen transform: scene scales field to the viewport with a fixed landscape aspect.
- Camera: follows the ball and active rider blend, clamped to field bounds. Initial prototype uses full-field framing for mobile readability.

## Scene

`scenes/interactive_match/interactive_match.tscn`

Required children:

- `Field`
- `FieldMarkings`
- `GoalLeft`
- `GoalRight`
- `Riders`
- `Ball`
- `Effects`
- `Camera`
- `HUD`
- `TouchControls`
- `Audio`

## Domain Split

Existing `MatchEngine` remains the headless simulation engine for balance and run simulation.

New `InteractiveMatchEngine` owns:

- continuous rider positions
- velocity and facing
- stamina/focus action costs
- ball position/velocity/ownership
- collision/action windows
- AI support and defense movement
- score/chukker clock
- visible events for UI/audio

Shared data:

- Rider stats
- Horse stats
- Team definitions
- Role fit
- Tactics
- Synergies
- Skills
- Foul modifiers

## Input

- Desktop: WASD/arrow movement, mouse aim, Space strike, Q pass/switch, E hook, R ride-off, Esc pause.
- Android: left virtual stick for movement, right drag for aim/strike, buttons for pass/switch, hook, ride-off, pause.
- Input replay: ordered frames with movement vector, aim vector, action flags, and delta.

## Actor State

Rider states:

- `support`
- `controlled`
- `chase_ball`
- `carry_ball`
- `defend_goal`
- `contest`
- `recover`

Movement model:

- acceleration
- max speed from horse stamina/coordination
- turn smoothing
- field bounds clamp
- stamina drain while sprinting/actions

## Ball

- Can be carried when close and recovered.
- Strike applies velocity along aim.
- Pass targets a teammate and may be intercepted.
- Speed decays over time.
- Goal detection triggers score, reset, and visible feedback.

## Actions

- Strike/shot: valid near ball or while carrying.
- Pass: transfers or kicks toward teammate.
- Hook: short cone against nearby opponent with ball/strike intent.
- Ride-off: side contact contest based on ride stat, angle, and stamina.
- Foul/free hit: dangerous crossing or bad ride-off can award free hit.

## Run Integration

Preparation starts the interactive scene. When the interactive match ends, it fills a `MatchState`-compatible result for `GameSession.finish_run_match()` and the existing result/reward flow.

## Delivery Gates

Gate A: control, movement, ball strike, pass, goal, readable camera.  
Gate B: eight riders, AI, hook, ride-off, foul/free hit, two chukkers, result.  
Gate C: cohesive placeholder visual style.  
Gate D: run/save/reward integration.  
Gate E: Android install, touch, full match, performance.
