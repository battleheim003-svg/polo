# Local Telemetry

No online telemetry is included.

Local audit data is produced only by developer tools:

- `tools/balance_simulator.gd`: match balance summary.
- `tools/run_simulator.gd`: three strategy run batches.
- Godot log files in `reports/audit/*.log`.

Generated telemetry/log outputs are excluded from release source archives unless explicitly listed in audit reports.
