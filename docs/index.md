# Active Anti-Vibration Platform

This GitHub Pages-ready site documents the featured project from the Control
course at Universidad de los Andes.

## Engineering Workflow

```mermaid
flowchart LR
    A[Physical platform] --> B[Lumped-parameter model]
    B --> C[Transfer function]
    C --> D[State-space realization]
    C --> E[IMC controller design]
    D --> F[Stability and frequency analysis]
    E --> G[Closed-loop simulation]
    H[Nonlinear effects] --> G
    G --> I[Performance metrics]
```

## Documentation Map

- [Mathematical formulation](mathematical-formulation.md)
- [Reproducibility guide](reproducibility.md)
- [Portfolio evaluation](portfolio-evaluation.md)

## Generated Evidence

![Closed-loop tracking](assets/closed_loop_tracking.png)

![Bode response](assets/bode_response.png)
