# Match UI Redesign

## Rejected Current Elements

- Current text header.
- Broken or unreadable Persian text.
- Rectangular Strike button.
- Rectangular Switch button.
- Oversized current joystick.
- Oversized current aim pad.
- Debug-like visual language.
- Identity-less panels.
- Empty composition where rider and ball are not dominant.

## Target HUD

- Large, clear score centered at the top.
- Small readable timer and chukker near score.
- Active rider portrait or compact crest.
- Visual stamina meter.
- Visual focus meter.
- Small pause icon.
- Thin translucent joystick.
- Aim controlled by right-thumb drag, not a rectangular button.
- Change Rider as a small icon, secondary to movement/aim.
- Minimal permanent text.
- Correct Persian for toasts and key state.
- Coherent Iranian palette: lapis, turquoise, parchment, gold, burgundy, warm sand, dark ink.

## Wireframe 1: Match Normal

```text
+--------------------------------------------------------------------------------+
|                       [ C1  01:35 ]     1 - 0        [pause]                  |
| [portrait]  stamina bar  focus bar                                               |
|                                                                                |
|                                                                                |
|                   camera follows rider + ball                                   |
|                                                                                |
|             horse/rider large enough to read       ball readable                |
|                                                                                |
|                                                                                |
|  (thin dynamic movement ring)                                      (small swap)  |
|       left thumb zone                                               right zone   |
+--------------------------------------------------------------------------------+
```

## Wireframe 2: Aim / Charge

```text
+--------------------------------------------------------------------------------+
|                       [ C1  01:28 ]     1 - 0        [pause]                  |
| [portrait]  stamina bar  focus bar                                               |
|                                                                                |
|                                                                                |
|            rider keeps moving                                                   |
|                 ball near mallet                                                |
|                    ===== segmented aim path =====>                              |
|                           charge glow grows                                     |
|                                                                                |
|  movement thumb held                                      aim thumb drag/hold    |
|  movement ring active                                   no rectangular strike   |
+--------------------------------------------------------------------------------+
```

## Wireframe 3: Goal State

```text
+--------------------------------------------------------------------------------+
|                            2 - 0                                                |
|                   large Persian banner: گل!                                     |
|                                                                                |
|                         camera holds goal mouth                                 |
|                                                                                |
|              ball trail + net/post flash + small gold particles                 |
|                                                                                |
|                     rider short celebration/recovery                            |
|                                                                                |
|         controls dim briefly; then camera zooms out and resets                  |
+--------------------------------------------------------------------------------+
```

## Option A: Fixed Joystick + Drag Aim

- Pros: predictable thumb location; easiest onboarding; stable for repeated movement.
- Cons: less comfortable on varied phone sizes; left thumb must reach fixed point.
- Complexity: medium.
- Fit for Chogan: good, because continuous horse movement benefits from stable steering.
- Multi-touch risk: low if finger ownership is implemented.
- Reference similarity: moderate; common mobile sports/action layout.

## Option B: Dynamic Joystick + Drag Aim

- Pros: most ergonomic; movement starts wherever left thumb lands; less visual clutter.
- Cons: requires excellent ownership/reset logic; needs clear subtle visual feedback.
- Complexity: medium-high.
- Fit for Chogan: best, because horse control is continuous and players need to keep eyes on rider/ball.
- Multi-touch risk: low-medium if ownership is strict.
- Reference similarity: high for modern mobile action controls.

## Option C: Touch-to-Move + Swipe-to-Strike

- Pros: minimal UI; visually clean; simple one-finger movement target selection.
- Cons: weaker direct horse feel; less suited for continuous mounted control; harder to combine aim and movement.
- Complexity: high for good feel.
- Fit for Chogan: weak-medium, because Chogan needs weighted steering and timed strike while moving.
- Multi-touch risk: medium-high.
- Reference similarity: lower for direct-control sports action.

## Recommendation

Choose Option B: Dynamic joystick + drag aim.

It best matches the requested ownership model, preserves continuous horse control, supports simultaneous movement and strike preparation, and can be made visually subtle without hiding the rider and ball. It also avoids the rejected rectangular Strike button because strike becomes the release of the aim finger.

## Files To Replace

- Touch/UI portions of `scenes/interactive_match/interactive_match.gd`.
- Current touch visuals created in `_build_touch()`.
- Current input collection in `_collect_input()`.
- Current HUD composition in `_build_hud()`.

## Files To Preserve

- `domain/interactive/interactive_match_engine.gd` unless input payload shape changes are explicitly approved.
- Gate A harness scene.
- Existing data repository and match data.
- Current camera/readability improvements, unless redesigned UI requires repositioning.
