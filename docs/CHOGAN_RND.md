# Chogan R&D Notes

The original research document was not present in the project at the start of this iteration.

This reference records the stabilizing decisions made during iteration 1:

- Keep the deterministic 2D auto-battler core and Godot scene flow.
- Make preparation a real lineup decision surface with four role slots.
- Move selected lineup into `MatchState` instead of using a display-only team.
- Use role fit, line ownership, fouls, synergies, skills, and coach commands as real mechanical factors.
- Keep all mechanics deterministic from seed plus command stream.
- Keep Android signing secrets out of commit-ready files; configure signing through local editor settings or external credentials.
- Do not add external runtime dependencies or final art in this prototype stabilization pass.

Open item: replace this file with the owner-approved full historical R&D brief when available.
