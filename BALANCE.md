# Balance Notes

## Dominance Formula

```text
Dominance = RelevantStat * RoleFit * HorseCondition
          + ZoneBonus
          + TacticBonus
          + LineOwnerBonus
          + SynergyBonus
          - FatiguePenalty
          - PressurePenalty
          + LimitedVariance
```

Core coefficients live in `domain/match/balance_config.gd`.

## Current Coefficients

- Exact role fit: 1.00
- Adjacent role fit: 0.90
- Mismatch role fit: 0.78
- Zone bonus: 6
- Tactic bonus: 7
- Shot threshold: 56
- Line owner bonus: 1.5
- Synergy cap: 8
- Fatigue weight: 18
- Pressure weight: 8
- Limited variance: +/-5
- Chukkers: 2
- Chukker length: 150 seconds
- Tick length: 5 seconds
- Extra-time guard: 40 ticks

## Simulator Result

Latest 1000-match run on Godot 4.7.1:

- Player win rate: 50.8%
- Enemy win rate: 49.2%
- Draw rate: 0.0%
- Average goals: 2.106
- Average logical length: 398.6 seconds
- Extra-time rate: 49.3%
- Fouls per match: 7.609
- Hooks: 9221
- Ride-offs: 8985
- Passes: 11881
- Strikes: 26679
- Recoveries: 13313
- Shots: 9641
- Skill activations per match: 12.39

Draw rate, average goals, and win-rate gap are inside the target band. Extra-time rate remains high and should be tuned during Vertical Slice pacing work.
