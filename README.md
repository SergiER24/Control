# Active Anti-Vibration Platform for an Ultrasonic Sensor

Selected Activity 2 project from the Control course at Universidad de los
Andes. The repository intentionally contains only the final report and the
Simulink model provided for this activity.

The report was prepared by Sergio Emmanuel Ropero and Juan Felipe Ortiz.

## Canonical Artifacts

| Artifact | Purpose |
| --- | --- |
| [`reports/activity_2_active_anti_vibration_platform.pdf`](reports/activity_2_active_anti_vibration_platform.pdf) | Final Activity 2 report |
| [`src/simulink/ModeloSistema.slx`](src/simulink/ModeloSistema.slx) | Editable Simulink and Simscape model |

## Project Abstract

The project studies an active anti-vibration platform for an ultrasonic sensor
used in laboratory tests related to potato pest detection. Vibrations from the
table or mounting base can change the sensor position and degrade distance
measurements. The main control objective is therefore local regulation:
maintaining the platform position close to its equilibrium while rejecting
external disturbances.

## Physical Model

The report defines the relative displacement

```math
q(t)=x(t)-z(t),
```

where `x(t)` is the absolute platform position and `z(t)` is the base position.
The mechanical and electrical equations are

```math
m\ddot{q}+c\dot{q}+kq=K_f i-m\ddot{z},
```

```math
L\dot{i}+Ri+K_e\dot{q}=u.
```

For nominal analysis, the base disturbance is temporarily set to zero. The
resulting third-order transfer function is

```math
G(s)=\frac{Q(s)}{U(s)}
=\frac{K_f}
{Lm s^3+(Lc+Rm)s^2+(Lk+Rc+K_fK_e)s+Rk}.
```

The report also derives the corresponding state-space representation and the
Routh-Hurwitz stability condition:

```math
(Lc+Rm)(Lk+Rc+K_fK_e)>LmRk.
```

## Controller Design

For controller tuning, the report introduces the reduced mechanical model

```math
G_r(s)=\frac{1}{s^2+5s+100}.
```

Using the IMC-based derivation documented in the report and preserving
`P = 50`, the ideal PID controller is

```math
C(s)=50\left(1+\frac{1}{0.05s}+0.2s\right).
```

The final report recommends the following parameters for the filtered PID
block:

| Parameter | Value |
| --- | ---: |
| `P` | `50` |
| `I` | `0.05` |
| `D` | `0.2` |
| `N` | `10` |

## Report and Model Difference

The supplied `.slx` file preserves a `PID Controller1` block with:

| Parameter | Report value | Supplied `.slx` value |
| --- | ---: | ---: |
| `P` | `50` | `50` |
| `I` | `0.05` | `0.05` |
| `D` | `0.2` | `0.2` |
| `N` | `10` | `100` |

The model also contains a block named `Autoting` with a separate stored
parameter set. This repository preserves the submitted files without modifying
either implementation choice.

## Evaluation Scope

The report distinguishes two scenarios:

1. **Disturbance rejection:** the primary application, with a fixed setpoint
   `r(t) = 0`.
2. **Step-reference tracking:** a complementary test requested for controller
   evaluation.

The report concludes that the controller is more appropriate for local
regulation than for reference tracking. The submitted PDF preserves the
simulation figures, discussion, and reported performance table.

## Simulink Model

The `.slx` file contains the editable implementation, including the mechanical
platform model, a Simscape Multibody subsystem, open-loop paths, a filtered PID
controller, setpoint and perturbation blocks, and scopes for response
inspection.

## Repository Structure

```text
docs/           GitHub Pages-ready project summary
reports/        Final submitted report
src/simulink/   Editable Simulink and Simscape model
```

## How to Review

1. Read the [final report](reports/activity_2_active_anti_vibration_platform.pdf).
2. Open [`ModeloSistema.slx`](src/simulink/ModeloSistema.slx) in MATLAB Simulink
   with the required Simscape products.
3. Inspect the regulation and tracking configurations documented in the report.

## Scope Note

This repository does not add generated Python analyses, additional control
plots, or numerical claims beyond the submitted Activity 2 artifacts.
