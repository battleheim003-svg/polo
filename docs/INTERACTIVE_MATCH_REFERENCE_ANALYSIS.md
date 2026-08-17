# Interactive Match Reference Analysis

Reference: `F:\polo\references\visual-gameplay-reference.mp4`  
Frame extraction: OpenCV, not ffmpeg. `ffmpeg` and `ffprobe` were unavailable on PATH.

## Video Facts

- Resolution: 1280x720
- FPS: 24
- Duration: 10 seconds
- Sample frames: `reports/interactive-match/reference_frames/`

## Preparation Reading

The preparation view uses a three-part composition:

- Left side: large readable rider slots.
- Center: live team preview with mounted units.
- Right side: field or tactical preview.
- Bottom: compact selectable roster.

Useful lesson for Chogan: lineup decisions should update a live mounted preview immediately. The screen should communicate team shape, role fit, and horse identity visually before listing dense stats.

## Match Reading

The match view uses:

- A continuous field rather than separate boxes.
- Top-down but slightly staged tactical readability.
- Clear team colors.
- A large visible ball.
- Left movement stick and right action/aim area.
- Minimal HUD at the top.
- Short feedback labels near action contact.

Useful lesson for Chogan: the player must always know controlled rider, ball ownership, attack direction, and strike aim without reading a long log.

## What To Adopt

- Continuous field layout.
- Eight readable mounted units.
- Left movement input, right aim/action input.
- Small high-contrast ball.
- Compact scoreboard and chukker HUD.
- Toast feedback for hook, foul, free hit, blocked pass, and goal.
- Preparation preview that mirrors the selected lineup.

## What Not To Copy

- Do not copy characters, animation poses, field art, colors, UI layout proportions, icons, or exact composition.
- Do not use extracted frames as assets.
- Do not reproduce the reference game's timing, economy, or branded visual identity.

## Chogan Direction

Chogan should use a modern Persian miniature-inspired style: lapis/turquoise for the player, burgundy/ochre for rivals, parchment and warm sand for the field environment, and restrained gold for important feedback.
