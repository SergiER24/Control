# Activity 2: Active Anti-Vibration Platform

Control-system modeling project for isolating sensitive equipment mounted on a
vibrating base.

## Main Files

- `Modelado_Plataforma_Antivibratoria.m`: section-based main MATLAB script.
- `parametros_plataforma.m`: physical parameters, test signals, and models.
- `analisis_plataforma_antivibratoria.m`: modeling, linearization, stability
  analysis, IMC design, simulations, and metrics.
- `generar_modelos_simulink.m`: generates linear and nonlinear Simulink models.
- `construir_modelos_estilo_ejemplo.m`: aligns generated outputs with the
  activity structure.
- `generarBaseVibratoria.m`: generates the base disturbance.
- `run_all.m`: runs the complete package.
- `documento_unificado_depurado.tex`: consolidated report source.
- `informe_ieee_actividad2.tex`: IEEE-format report draft.
- `guia_armado_simscape.md`: step-by-step Simscape assembly guide.

## Running the Project

Open MATLAB 2025a in this directory and run:

```matlab
run_all
```

MATLAB and Simulink were not available in the preparation environment, so the
checked-in files were validated structurally rather than through a full
Simulink execution. Original supporting documents retain the language used
during the course.
