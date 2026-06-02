# Active Anti-Vibration Platform for an Ultrasonic Sensor

This page documents the selected Activity 2 project from the Universidad de los
Andes Control course. The public repository intentionally preserves only the
final report and the editable Simulink model supplied for this activity.

## Application

The platform is intended to reduce ultrasonic-sensor motion caused by table or
base vibrations during laboratory tests related to potato pest detection. The
primary control objective is disturbance rejection around a fixed equilibrium,
not trajectory tracking.

## Canonical Artifacts

- [Final Activity 2 report](https://github.com/SergiER24/Control/blob/main/reports/activity_2_active_anti_vibration_platform.pdf)
- [Editable Simulink and Simscape model](https://github.com/SergiER24/Control/blob/main/src/simulink/ModeloSistema.slx)

## Technical Summary

- Third-order electromechanical nominal model
- State-space formulation
- Routh-Hurwitz stability condition
- Reduced second-order model for IMC-based PID tuning
- Filtered PID implementation in Simulink
- Regulation and step-reference evaluation scenarios

## Documentation

- [Mathematical formulation](model-formulation.md)
- [Artifact scope](artifact-scope.md)
