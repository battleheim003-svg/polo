# Save Schema

Save file: `user://chogan_save.json`

Current schema: `1`

Top-level fields:

- `audio`: master volume and mute state.
- `match_speed`: match playback speed.
- `persian_digits`: display preference.
- `last_seed`: last used seed.
- `last_lineup`: reserved lineup persistence field.
- `run`: serialized `RunState`.
- `meta`: completed runs, best coins, and tutorial flag.

Invalid or mismatched schemas are ignored and defaults are restored.
