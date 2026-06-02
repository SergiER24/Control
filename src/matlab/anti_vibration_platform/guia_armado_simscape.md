# Guia de Armado en Simscape

Esta guia te dice **como llevar el modelo realista a Simscape** siguiendo el espiritu del ejemplo del vehiculo. La idea no es solo que corra, sino que entiendas por que se conecta cada bloque.

## 1. Objetivo del modelo en Simscape

Queremos un modelo fisico del sistema donde la plataforma sea una masa real dentro de una red mecánica translacional. El controlador sigue estando en Simulink, y Simscape se encarga de la dinámica física de la planta.

## 2. Que bloques necesitas

Desde `Simscape / Utilities`:

- `Solver Configuration`
- `Simulink-PS Converter`
- `PS-Simulink Converter`

Desde `Simscape / Foundation Library / Mechanical / Translational Elements`:

- `Mass`
- `Translational Spring`
- `Translational Damper`
- `Mechanical Translational Reference`

Desde `Simscape / Foundation Library / Mechanical / Mechanical Sources`:

- `Ideal Force Source`

Desde `Simscape / Foundation Library / Mechanical / Mechanical Sensors`:

- `Ideal Translational Motion Sensor`

Desde Simulink:

- `From Workspace`
- `Transfer Fcn`
- `Sum`
- `Scope`
- `Saturation`
- `Mux`
- `Interpreted MATLAB Fcn`

## 3. Idea fisica de la red

En la version mas clara para este proyecto, la plataforma se modela como una masa conectada a tierra por un resorte y un amortiguador lineales. La perturbacion de base se mete como **fuerza equivalente** en lugar de desplazar explicitamente el punto de anclaje.

Eso da una implementacion mucho mas estable para armar y depurar:

- rama 1: masa;
- rama 2: resorte lineal;
- rama 3: amortiguador lineal;
- rama 4: fuente de fuerza del actuador;
- rama 5: fuente de fuerza equivalente que mete no linealidades y perturbaciones.

Todo eso conectado entre el nodo de la plataforma y la referencia mecánica.

## 4. Por que usar fuerza equivalente para la base

La ecuacion real es:

```math
m\ddot{x}=F_a-k(x-z)-c(\dot{x}-\dot{z})-k_3(x-z)^3-F_c\tanh\left(\frac{\dot{x}-\dot{z}}{v_\varepsilon}\right)-F_{stop}
```

Si separas la parte lineal respecto a tierra:

```math
m\ddot{x}=F_a-kx-c\dot{x}+\underbrace{kz+c\dot{z}-k_3(x-z)^3-F_c\tanh\left(\frac{\dot{x}-\dot{z}}{v_\varepsilon}\right)-F_{stop}}_{F_{eq}}
```

Entonces puedes dejar en Simscape:

- el resorte lineal `k`,
- el amortiguador lineal `c`,
- la masa `m`,

y calcular en Simulink:

```math
F_{eq}=kz+c\dot{z}-k_3(x-z)^3-F_c\tanh\left(\frac{\dot{x}-\dot{z}}{v_\varepsilon}\right)-F_{stop}
```

Esa fuerza equivalente se aplica con una segunda `Ideal Force Source`.

## 5. Conexion conceptual

Nodo central:

- `Mass`
- `Translational Spring`
- `Translational Damper`
- `Ideal Force Source` del actuador
- `Ideal Force Source` de perturbacion/no linealidad
- `Ideal Translational Motion Sensor`

Nodo de referencia:

- `Mechanical Translational Reference`
- `Solver Configuration`

## 6. Parametros que debes poner

Usa los mismos del script:

- `m = 12`
- `k = 1800`
- `c = 95`
- `k3 = 6e4`
- `Fc = 1`
- `tau_a = 0.04`
- `Ka = 220`
- `u_sat = 1.5`
- `x_lim = 0.015`

## 7. Flujo de senales

### Actuador

`u(t)` -> `Saturation` -> `Transfer Fcn` con `Ka/(tau_a s + 1)` -> `Simulink-PS Converter` -> `Ideal Force Source`

### Sensor

`Ideal Translational Motion Sensor` -> `PS-Simulink Converter` para posicion -> `x(t)`

`Ideal Translational Motion Sensor` -> `PS-Simulink Converter` para velocidad -> `v(t)`

### Fuerza no lineal equivalente

Entradas:

- `x(t)`
- `v(t)`
- `z(t)`
- `zd(t)`

Bloque `Interpreted MATLAB Fcn`:

```matlab
k*z + c*zd - k3*(x-z)^3 - Fc*tanh((v-zd)/v_eps) - fuerza_tope([x;v],x_lim,k_stop,c_stop)
```

Salida:

- `Simulink-PS Converter`
- `Ideal Force Source` de perturbacion equivalente

## 8. Como compararlo con el modelo lineal

Haz exactamente lo que hace el ejemplo:

- una rama con `Transfer Fcn` del modelo aproximado;
- otra rama con la planta fisica en Simscape;
- misma entrada en lazo abierto;
- mismas referencias y perturbaciones en lazo cerrado;
- superponer curvas en un mismo `Scope`.

## 9. Archivos con los que se conecta esta guia

- [Modelado_Plataforma_Antivibratoria.m](Modelado_Plataforma_Antivibratoria.m)
- [parametros_plataforma.m](parametros_plataforma.m)
- [fuerza_tope.m](fuerza_tope.m)
- [fuerza_no_lineal_suspension.m](fuerza_no_lineal_suspension.m)

## 10. Lo honesto aqui

En esta sesion yo no tuve MATLAB/Simscape instalado para validar visualmente ese armado bloque por bloque dentro del `.slx`. Por eso deje:

- el modelo matematico cerrado;
- las funciones auxiliares listas;
- los parametros cerrados;
- y esta guia de armado siguiendo la misma logica del ejemplo.

Si quieres, en el siguiente paso puedo ayudarte a **cerrar la version Simscape de verdad** a partir de una captura del diagrama que armes o del siguiente error que arroje MATLAB.
