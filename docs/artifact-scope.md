# Artifact Scope

## Included Files

| File | SHA-256 |
| --- | --- |
| `reports/activity_2_active_anti_vibration_platform.pdf` | `db6535610f5bc4f9b70252b301e632db03fb76bfc955005da46d229ca90e3a46` |
| `src/simulink/ModeloSistema.slx` | `80557369df12f5a24ea4fa43fcfcee0bd28dcdd65f371efdda4e687e2a8ee355` |

## Simulink Contents

The supplied `.slx` archive includes:

- a mechanical platform model;
- a Simscape Multibody subsystem;
- open-loop model paths;
- a filtered PID controller;
- setpoint and disturbance blocks;
- scopes for response inspection.

## Preserved PID Configurations

The report recommends `P = 50`, `I = 0.05`, `D = 0.2`, and `N = 10`. The
supplied `.slx` file stores `P = 50`, `I = 0.05`, `D = 0.2`, and `N = 100` in
its `PID Controller1` block.

The model also contains a block named `Autoting` with a separate stored
parameter set. These artifacts are preserved without modification.

## Explicit Exclusions

The repository intentionally excludes unrelated coursework, generated Python
analyses, synthetic figures, and unsupported claims. The two files listed above
are the canonical Activity 2 artifacts.
