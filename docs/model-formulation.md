# Mathematical Formulation

## Relative Coordinate

The report uses the relative displacement

```math
q(t)=x(t)-z(t),
```

where `x(t)` is the platform position and `z(t)` is the base position.

## Electromechanical Model

```math
m\ddot{q}+c\dot{q}+kq=K_f i-m\ddot{z},
```

```math
L\dot{i}+Ri+K_e\dot{q}=u.
```

The states are

```math
x_1=q, \qquad x_2=\dot{q}, \qquad x_3=i.
```

For the nominal plant, the base disturbance is set to zero:

```math
A=
\begin{bmatrix}
0 & 1 & 0 \\
-k/m & -c/m & K_f/m \\
0 & -K_e/L & -R/L
\end{bmatrix},
\qquad
B=
\begin{bmatrix}
0 \\ 0 \\ 1/L
\end{bmatrix},
```

```math
C=
\begin{bmatrix}
1 & 0 & 0
\end{bmatrix},
\qquad
D=0.
```

## Nominal Transfer Function

```math
G(s)=\frac{K_f}
{Lm s^3+(Lc+Rm)s^2+(Lk+Rc+K_fK_e)s+Rk}.
```

The report applies the third-order Routh-Hurwitz criterion:

```math
(Lc+Rm)(Lk+Rc+K_fK_e)>LmRk.
```

## Reduced Design Model

For IMC-based PID tuning, the report uses

```math
G_r(s)=\frac{1}{s^2+5s+100}.
```

The resulting ideal controller and filtered PID parameters reported in the PDF
are

```math
C(s)=50\left(1+\frac{1}{0.05s}+0.2s\right),
```

```text
P = 50
I = 0.05
D = 0.2
N = 10
```

The supplied `.slx` file stores `N = 100` in its `PID Controller1` block. The
report and model are preserved as submitted so that reviewers can inspect this
difference directly.
