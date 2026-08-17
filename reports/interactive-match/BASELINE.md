# Interactive Match Baseline

Date: 2026-08-13  
Branch: `feature/interactive-match`  
Starting commit: `d8221f4`

## Git

- Source branch before work: `main`
- New branch: `feature/interactive-match`
- Working tree at start: no tracked source changes; ignored build/log/device artifacts present.
- Untracked reference input: `references/visual-gameplay-reference.mp4`

## Reference Video

- Path: `F:\polo\references\visual-gameplay-reference.mp4`
- Metadata source: OpenCV, because `ffmpeg` and `ffprobe` were not available on PATH.
- Resolution: 1280x720
- FPS: 24
- Duration: 10.0 seconds
- Extracted frames: `reports/interactive-match/reference_frames/`

## Baseline Tests

- `tests/test_runner.gd`: PASS, 20 checks.
- `tests/run_test_runner.gd`: PASS, 18 checks.
- `tests/smoke_scene_runner.gd`: PASS.

Known warning: Godot headless emitted a Windows root certificate warning; it did not fail tests.

## Current Product Gap

The vertical slice domain, run, save, preparation, reward, and Android packaging are acceptable for prototype handoff. The match itself is still primarily a zone/event simulation with text and statistics. This branch will preserve the headless simulation path while adding an interactive visual match path.
