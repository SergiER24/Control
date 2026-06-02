# Project 2: Water Level in a Navigation Lock Chamber

Base project for modeling and controlling the water level in a navigation lock
chamber. The input is the filling or draining valve opening `u(t)`, and the
output is the water-level deviation `h(t)` from an operating point `h_0`.

## Models

- Approximate third-order linear model for analysis and controller design.
- Nonlinear model with turbulent losses, hydraulic-head dependence, and valve
  actuator saturation.

## Main Files

- `Modelado_Nivel_Esclusa.m`: main MATLAB script, organized into sections.
- `parametros_esclusa.m`: physical parameters, test signals, and linear models.
- `analisis_nivel_esclusa.m`: analysis, simulations, metrics, and figures.
- `hidraulica_no_lineal_esclusa.m`: nonlinear model helper function.
- `generar_modelos_simulink_esclusa.m`: generates the Simulink models.
- `run_all.m`: runs the complete package.
- `informe_ieee_proyecto2_esclusa.tex`: IEEE-format report draft.

## Running the Project

Open MATLAB in this directory and run:

```matlab
run_all
```

MATLAB and Simulink were not available in the preparation environment, so the
checked-in files were validated structurally rather than through a full
Simulink execution.
