# Documento Detallado

## 1. Idea general del proyecto

El sistema propuesto es una **plataforma antivibratoria activa**. La idea fisica es sencilla: sobre una base inferior que vibra se monta una plataforma superior que soporta un equipo sensible. La base recibe una perturbacion externa, mientras que un actuador aplica una fuerza para reducir el movimiento de la plataforma y hacer que esta siga una referencia deseada.

Este tipo de problema es totalmente valido para la actividad porque permite:

- construir un **modelo realista** con no linealidades;
- obtener un **modelo matematico aproximado** a partir de principios fisicos;
- comparar ambos modelos en **lazo abierto**;
- disenar un controlador con una metodologia del curso;
- evaluar **seguimiento de referencia** y **rechazo a perturbaciones**.

## 2. Por que si cumple con el enunciado

### Sistema SISO

- **Entrada de control**: senal de mando al actuador, `u(t)`.
- **Salida**: posicion vertical de la plataforma, `x(t)`.

### Orden minimo de tercer orden

La planta aproximada se modela con:

- dinamica mecanica de la plataforma: posicion y velocidad;
- dinamica del actuador: una constante de tiempo de primer orden.

Por tanto, el orden minimo es:

`2 estados mecanicos + 1 estado del actuador = 3 estados`

La funcion de transferencia lineal queda:

```math
G(s)=\frac{X(s)}{U(s)}=
\frac{K_a}{(\tau_a s + 1)(m s^2 + c s + k)}
```

que es claramente de **tercer orden**.

## 3. Descripcion fisica del sistema

La plataforma se idealiza como una masa `m` unida a la base mediante:

- un resorte lineal de rigidez `k`,
- un amortiguador viscoso `c`,
- un actuador que produce una fuerza `F_a`,
- y, en el modelo realista, no linealidades adicionales.

Las variables son:

- `x(t)`: posicion absoluta de la plataforma.
- `z(t)`: posicion de la base vibrante.
- `u(t)`: senal aplicada al actuador.
- `F_a(t)`: fuerza producida por el actuador.

## 4. Modelo realista

El modelo realista incluye estos efectos:

- resorte lineal;
- amortiguamiento viscoso;
- **rigidez cubica** `k_3(x-z)^3`, para capturar rigidez no lineal;
- **friccion tipo Coulomb suavizada** con `tanh`;
- **saturacion del actuador**;
- **topes mecanicos** en `x = +- x_lim`.

La ecuacion mecanica es:

```math
m\ddot{x}=F_a-F_{susp}-F_{stop}
```

donde

```math
F_{susp}=k(x-z)+c(\dot{x}-\dot{z})+k_3(x-z)^3+F_c\tanh\left(\frac{\dot{x}-\dot{z}}{v_\varepsilon}\right)
```

y la dinamica del actuador es:

```math
\tau_a \dot{F}_a + F_a = K_a \, \mathrm{sat}(u)
```

Los topes mecanicos se modelan como una fuerza activa solo cuando la plataforma supera el desplazamiento permitido:

```math
F_{stop}=
\begin{cases}
k_{stop}(x-x_{lim})+c_{stop}\max(\dot{x},0), & x>x_{lim} \\
k_{stop}(x+x_{lim})+c_{stop}\min(\dot{x},0), & x<-x_{lim} \\
0, & |x|\le x_{lim}
\end{cases}
```

## 5. Modelo matematico aproximado

Para disenar el controlador se usa un modelo lineal simplificado. Se eliminan:

- la rigidez cubica;
- la friccion no lineal;
- los topes mecanicos;
- la saturacion del actuador para el analisis nominal.

Alrededor del punto de operacion:

```math
x^\star = 0, \quad \dot{x}^\star = 0, \quad z^\star = 0, \quad F_a^\star = 0, \quad u^\star = 0
```

la ecuacion resultante es:

```math
m\ddot{x} + c\dot{x} + kx = F_a + c\dot{z} + kz
```

Si primero analizamos la planta respecto a la entrada de control y fijamos la perturbacion en cero, queda:

```math
m\ddot{x} + c\dot{x} + kx = F_a
```

y con la dinamica del actuador:

```math
\tau_a \dot{F}_a + F_a = K_a u
```

Aplicando Laplace con condiciones iniciales nulas:

```math
(m s^2 + c s + k)X(s)=F_a(s)
```

```math
(\tau_a s + 1)F_a(s)=K_a U(s)
```

Eliminando `F_a(s)`:

```math
\frac{X(s)}{U(s)}=
\frac{K_a}{(\tau_a s+1)(m s^2 + c s + k)}
```

## 6. Parametros seleccionados

Los valores usados en la solucion son:

- `m = 12 kg`
- `k = 1800 N/m`
- `c = 95 N*s/m`
- `k3 = 6e4 N/m^3`
- `Fc = 1 N`
- `Ka = 220 N/V`
- `tau_a = 0.04 s`
- `u_sat = 1.5 V`
- `x_lim = 0.015 m`

Con estos valores:

- la parte mecanica tiene frecuencia natural `wn = sqrt(k/m) ≈ 12.247 rad/s`;
- el amortiguamiento equivalente es `zeta ≈ 0.323`.

## 7. Analisis de estabilidad del modelo aproximado

El denominador de la planta es:

```math
(\tau_a s + 1)(m s^2 + c s + k)
```

Al expandirlo con los parametros escogidos:

```math
0.48 s^3 + 15.8 s^2 + 167 s + 1800
```

Los polos nominales son:

- `s1 = -25`
- `s2,3 = -3.958 +- j11.590`

Como todos tienen parte real negativa, la planta aproximada es **estable en lazo abierto**.

## 8. Comparacion entre modelo realista y aproximado en lazo abierto

La comparacion se hace con un escalon de `0.05 V` aplicado al actuador.

### Que se espera observar

- el modelo lineal y el realista presentan respuestas parecidas para desplazamientos pequenos;
- el modelo realista tiene diferencias por friccion y rigidez no lineal;
- el overshoot del modelo realista suele ser menor por el efecto disipativo adicional.

### Resultados nominales de referencia

Al correr la version analitica dejada en `analisis_plataforma_antivibratoria.m`, se esperan valores cercanos a:

- lazo abierto lineal:
  - `y_ss ≈ 6.11 mm`
  - `Mp ≈ 29.96 %`
- lazo abierto realista:
  - `y_ss ≈ 6.10 mm`
  - `Mp ≈ 18.07 %`

La lectura fisica es clara: el modelo realista disipa mas energia y suaviza el pico de la respuesta.

## 9. Diseno del controlador

Se adopto una metodologia de **Control por Modelo Interno (IMC)**, porque:

- esta dentro del alcance del curso;
- permite usar directamente la planta aproximada de tercer orden;
- produce una forma cerrada elegante y facil de justificar en el informe.

### 9.1 Planta nominal

```math
\tilde{G}_p(s) = \frac{K_a}{(\tau_a s+1)(m s^2 + c s + k)}
```

La planta es totalmente invertible en el sentido IMC porque:

- no tiene tiempo muerto,
- no tiene ceros en el semiplano derecho,
- y es estable.

### 9.2 Filtro IMC

Se escoge:

```math
F(s)=\frac{1}{(\lambda s + 1)^3}
```

con `lambda = 0.10 s`.

Se usa orden 3 en el filtro para que el controlador resultante sea propio, ya que la inversa de la planta tiene grado relativo `-3`.

### 9.3 Controlador IMC interno

```math
Q(s)=\tilde{G}_p^{-1}(s)F(s)
=
\frac{(\tau_a s+1)(m s^2 + c s + k)}{K_a(\lambda s + 1)^3}
```

### 9.4 Controlador equivalente en realimentacion

Usando la relacion clasica:

```math
G_c(s)=\frac{Q(s)}{1-\tilde{G}_p(s)Q(s)}
```

y como `\tilde{G}_p(s)Q(s)=1/(\lambda s+1)^3`, se obtiene:

```math
G_c(s)=
\frac{(\tau_a s+1)(m s^2 + c s + k)}
{K_a \lambda s(\lambda^2 s^2 + 3\lambda s + 3)}
```

Este es el controlador implementado en los scripts.

### 9.5 Ventaja de esta eleccion

Para la planta nominal, la transferencia de lazo cerrado queda exactamente:

```math
T(s)=\frac{1}{(\lambda s + 1)^3}
```

Eso significa:

- respuesta monotona;
- sin overshoot nominal;
- rapidez gobernada por `lambda`.

## 10. Evaluacion del desempeno

La evaluacion se plantea en dos pruebas, exactamente como pide la actividad.

### Seguimiento de referencia

Se usa una referencia variable por tramos:

- `0 mm` hasta `t = 1 s`
- `4.0 mm` entre `1 s` y `9 s`
- `-2.5 mm` entre `9 s` y `16 s`
- `3.0 mm` desde `16 s` hasta el final

### Rechazo a perturbaciones

La base vibra asi:

- sin perturbacion hasta `t = 6 s`;
- seno de amplitud `1.5 mm` y frecuencia `1.2 Hz` entre `6 s` y `14 s`;
- combinacion de dos senos pequenos despues de `14 s`.

### Resultados nominales de referencia

Con la parametrizacion actual, se esperan valores cercanos a:

- lazo cerrado lineal:
  - `Mp ≈ 0 %`
  - `tss ≈ 0.90 s`
- lazo cerrado realista:
  - `Mp ≈ 5.9 %`
  - `tss ≈ 2.95 s`

Para el tramo de perturbacion:

- error RMS lineal `≈ 2.10 mm`
- error RMS realista `≈ 1.74 mm`

El valor exacto puede variar ligeramente al ejecutar en MATLAB por detalles numericos del solver.

## 11. Que hace cada archivo MATLAB

### `parametros_plataforma.m`

Define:

- parametros fisicos;
- no linealidades;
- referencias;
- perturbaciones;
- planta lineal `G(s)`;
- controlador `Gc(s)`.

### `analisis_plataforma_antivibratoria.m`

Hace todo el flujo matematico:

- imprime el modelo aproximado;
- calcula polos y ceros;
- evalua estabilidad;
- disena el controlador IMC;
- simula lazo abierto lineal y realista;
- simula lazo cerrado lineal y realista;
- calcula metricas;
- guarda figuras y un `.mat` de resultados.

### `generar_modelos_simulink.m`

Genera cuatro modelos:

- `modelo_aproximado_lineal_abierto.slx`
- `modelo_realista_no_lineal_abierto.slx`
- `lazo_cerrado_lineal_imc.slx`
- `lazo_cerrado_no_lineal_imc.slx`

El modelo realista se deja en **bloques estandar de Simulink**, lo cual sigue siendo valido segun el enunciado.

## 12. Como migrarlo a Simscape

Aunque el modelo realista ya cumple con bloques estandar, si quieren una version Simscape, la estructura recomendada es:

### Bloques fisicos

- `Mass`
- `Translational Spring`
- `Translational Damper`
- `Translational Friction`
- `Ideal Force Source`
- `Ideal Translational Motion Sensor`
- `Mechanical Translational Reference`
- `Solver Configuration`

### Interfaz con Simulink

- `Simulink-PS Converter`
- `PS-Simulink Converter`

### Conexion conceptual

1. La base vibrante se impone con una fuente de movimiento o con una velocidad prescrita equivalente.
2. El resorte y el amortiguador se conectan entre la base y la masa de la plataforma.
3. El actuador se modela como una fuerza controlada aplicada a la masa.
4. El sensor mide posicion y velocidad de la plataforma.
5. El controlador IMC queda en el dominio Simulink y entrega la fuerza deseada.

### Que no cambia al pasar a Simscape

- las ecuaciones del informe;
- el modelo aproximado para diseno;
- la logica del controlador;
- la forma de evaluar seguimiento y perturbacion.

## 13. Que deben decir manana al presentar la idea

Texto sugerido:

> Se propone modelar una plataforma antivibratoria activa para aislar un equipo sensible frente a vibraciones de base. El sistema se representara mediante un modelo realista con no linealidades fisicas y un modelo lineal aproximado de tercer orden para disenar un controlador por IMC y comparar el desempeno de ambos frente a cambios de referencia y perturbaciones.

## 14. Que les falta antes de la entrega final

- Reemplazar nombres de integrantes.
- Ejecutar los scripts en MATLAB 2025a.
- Revisar visualmente los `.slx`.
- Exportar las figuras definitivas.
- Ajustar el informe final a maximo 8 paginas.

## 15. Resumen final

La solucion ya deja hecho el esqueleto tecnico completo del proyecto:

- idea aprobable;
- modelo realista;
- modelo lineal de tercer orden;
- analisis de estabilidad;
- controlador IMC;
- simulaciones de seguimiento y perturbacion;
- base de informe y archivos para MATLAB.

Lo unico que no se pudo validar localmente fue la ejecucion real en MATLAB/Simulink, porque ese software no estaba instalado en este entorno. Por eso el siguiente paso natural es abrir esta carpeta en MATLAB 2025a y correr `run_all`.
