# Mathematical Formulation

## Mechanical and Actuator Dynamics

The nominal platform displacement `x(t)` and actuator force `F_a(t)` satisfy

```math
m\ddot{x}+c\dot{x}+kx=F_a
```

```math
\tau_a\dot{F}_a+F_a=K_a u
```

which yields

```math
G(s)=\frac{X(s)}{U(s)}
=\frac{K_a}{(\tau_a s+1)(m s^2+c s+k)}.
```

## State-Space Model

With `\mathbf{x}=[x,\dot{x},F_a]^T`,

```math
\dot{\mathbf{x}}=
\begin{bmatrix}
0 & 1 & 0\\
-k/m & -c/m & 1/m\\
0 & 0 & -1/\tau_a
\end{bmatrix}\mathbf{x}
+
\begin{bmatrix}
0\\0\\K_a/\tau_a
\end{bmatrix}u,
\qquad
y=
\begin{bmatrix}
1 & 0 & 0
\end{bmatrix}\mathbf{x}.
```

## Nonlinear Validation Model

The realistic suspension force is

```math
F_s(\Delta x,\Delta \dot{x})=
k\Delta x+c\Delta\dot{x}+k_3\Delta x^3+
F_c\tanh\left(\frac{\Delta\dot{x}}{v_\epsilon}\right).
```

The actuator voltage is saturated and mechanical stops are activated when
`|x| > x_{lim}`.

## IMC Controller

The model-inversion design uses

```math
F(s)=\frac{1}{(\lambda s+1)^3}
```

and the equivalent controller

```math
G_c(s)=
\frac{(\tau_a s+1)(m s^2+c s+k)}
{K_a \lambda s(\lambda^2s^2+3\lambda s+3)}.
```

The filter parameter `\lambda` controls the performance-versus-robustness
tradeoff. Smaller values accelerate the nominal response but demand greater
actuator effort and increase sensitivity to neglected dynamics.

## Stability and Frequency-Domain Analysis

The portable workflow exports:

- open-loop poles and state-space matrices;
- a root-locus diagram of the nominal plant;
- Bode plots for the plant and compensated loop;
- nominal and nonlinear time-domain comparisons;
- disturbance-window RMS error and maximum control voltage.
