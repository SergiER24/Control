# Explicacion Super Detallada

Este documento no esta escrito como informe de entrega, sino como una guia para que **entiendas de verdad** el proyecto. La idea es que, si manana te preguntan algo, no respondas solo de memoria sino con criterio.

## 1. Que sistema estamos modelando

Estamos modelando una **plataforma antivibratoria activa**.

Piensa en una mesa pequena donde se apoya un equipo delicado: un sensor, una aguja de medicion, un componente optico o un instrumento de laboratorio. Esa mesa no esta fija sobre el suelo, sino conectada a una base que vibra.

Entonces tenemos dos partes:

- una **base** que vibra porque recibe una perturbacion externa;
- una **plataforma superior** donde esta el equipo sensible.

Entre ambas hay:

- un resorte;
- un amortiguador;
- y un actuador que puede empujar o halar la plataforma.

El objetivo del control no es mover la base, sino hacer que la plataforma superior:

- siga una referencia de posicion cuando se le pida;
- y, sobre todo, se mueva lo menos posible cuando la base vibra.

## 2. Por que esta idea sirve para la actividad

La actividad pide un sistema:

- real o inspirado en una aplicacion real;
- `SISO`;
- de al menos `tercer orden`;
- con modelo realista;
- con modelo matematico aproximado;
- con controlador diseñado usando el modelo aproximado.

Este proyecto cumple todo eso.

### Es SISO

Porque escogimos:

- **entrada**: la senal de control del actuador `u(t)`;
- **salida**: la posicion de la plataforma `x(t)`.

Solo hay una entrada y una salida.

### Es de tercer orden minimo

La dinamica mecanica de la plataforma aporta dos estados:

- posicion;
- velocidad.

Y la dinamica del actuador aporta un estado adicional:

- la fuerza del actuador no aparece instantaneamente, sino con una constante de tiempo.

Entonces:

`2 estados mecanicos + 1 estado del actuador = 3 estados`

## 3. Cual es la idea fisica detras de las ecuaciones

La plataforma es una masa `m`.

Sobre esa masa actuan varias fuerzas:

- la fuerza del actuador `Fa`;
- la fuerza del resorte;
- la fuerza del amortiguador;
- una fuerza no lineal adicional por rigidez cubica;
- friccion seca suavizada;
- y, si se sale demasiado, la fuerza del tope mecanico.

La segunda ley de Newton dice:

```math
\sum F = m\ddot{x}
```

Si definimos:

- `x(t)` como la posicion de la plataforma,
- `z(t)` como la posicion de la base,

entonces el resorte y el amortiguador no dependen de `x` sola, sino del **movimiento relativo** entre la plataforma y la base:

- deformacion del resorte: `x - z`
- velocidad relativa: `xdot - zdot`

Eso es lo fisicamente correcto, porque si la base y la plataforma se mueven igual, la suspension no “siente” deformacion relativa.

## 4. Modelo realista

La fuerza total de la suspension se definio como:

```math
F_{susp}=k(x-z)+c(\dot{x}-\dot{z})+k_3(x-z)^3+F_c\tanh\left(\frac{\dot{x}-\dot{z}}{v_\varepsilon}\right)
```

Vamos termino por termino.

### `k(x-z)`

Es la fuerza lineal del resorte.

- Si la plataforma sube mas que la base, el resorte se deforma.
- Esa deformacion genera una fuerza restauradora.

### `c(xdot-zdot)`

Es el amortiguamiento viscoso.

- Si la plataforma se mueve mas rapido que la base, el amortiguador se opone.
- Entre mayor sea la velocidad relativa, mayor la fuerza.

### `k3(x-z)^3`

Es una rigidez no lineal.

Esto significa que el sistema se endurece cuando la deformacion es grande. Es una forma simple y muy usada de representar que el resorte ya no es perfectamente lineal para desplazamientos altos.

### `Fc*tanh((xdot-zdot)/v_eps)`

Representa friccion seca suavizada.

La friccion seca ideal usa la funcion signo, pero esa funcion puede ser numericamente dura para simulacion. Por eso se usa `tanh`, que se comporta parecido pero es suave.

## 5. El actuador

El actuador no genera fuerza instantanea. Por eso se modela como:

```math
\tau_a \dot{F}_a + F_a = K_a u
```

Eso dice:

- si aplicas una senal `u`, la fuerza `Fa` no salta de inmediato;
- se acerca gradualmente al valor `Ka*u`;
- y la rapidez de ese acercamiento la decide `tau_a`.

Este detalle es importante porque es precisamente lo que nos da el **tercer orden**.

## 6. Topes mecanicos

En el mundo real, la plataforma no puede desplazarse infinito.

Por eso se definio un limite:

- `x_lim = 0.015 m`

Si la masa se pasa de ese limite, aparece una fuerza de contacto:

- parecida a un resorte muy duro;
- mas una disipacion adicional.

Eso evita que el modelo realista sea fisicamente absurdo.

## 7. Por que el modelo aproximado es mas simple

El controlador no se diseña sobre el modelo mas complicado, porque seria mucho mas dificil y poco practico para el curso.

Entonces el modelo aproximado elimina:

- el resorte cubico,
- la friccion seca,
- la saturacion,
- los topes.

Y ademas, para obtener la planta respecto a la entrada de control, primero se fija la perturbacion de base en cero.

Entonces queda:

```math
m\ddot{x}+c\dot{x}+kx=F_a
```

y

```math
\tau_a \dot{F}_a+F_a=K_a u
```

Con eso ya puedes obtener la funcion de transferencia.

## 8. Como sale la funcion de transferencia

Aplicando Laplace con condiciones iniciales nulas:

```math
(m s^2 + c s + k)X(s)=F_a(s)
```

```math
(\tau_a s+1)F_a(s)=K_a U(s)
```

Si reemplazas `F_a(s)` y despejas `X(s)/U(s)`, llegas a:

```math
G(s)=\frac{K_a}{(\tau_a s+1)(m s^2+c s+k)}
```

Eso ya te muestra muy claramente el orden:

- un factor de primer orden por el actuador;
- un factor de segundo orden por la parte mecanica.

## 9. Que significa cada polo

Cuando calculas polos de la planta aproximada, salen:

- un polo real rapido del actuador;
- un par complejo conjugado de la parte masa-resorte-amortiguador.

Interpretacion:

- el actuador mete una dinamica adicional;
- la parte mecanica tiene comportamiento oscilatorio amortiguado.

Como todos los polos estan en el semiplano izquierdo, la planta aproximada es estable.

## 10. Por que comparamos dos modelos

Esta es la esencia de la actividad.

No basta con tener una planta “bonita” en Laplace. Lo que quiere mostrar el proyecto es:

- que el modelo lineal sirve para diseñar;
- pero que el modelo realista muestra limitaciones y diferencias.

Entonces:

- el modelo aproximado sirve para analisis y diseño;
- el modelo realista sirve para ver que pasa cuando metes no linealidades y restricciones.

## 11. Que significa comparar en lazo abierto

Comparar en lazo abierto significa:

- tomar ambos modelos;
- aplicarles la misma entrada;
- sin controlador en realimentacion;
- y mirar si responden parecido.

Eso permite discutir:

- si la linealizacion es buena cerca del punto de operacion;
- en que rango deja de ser buena;
- como afectan las no linealidades al sobrepico o al valor final.

## 12. Por que elegimos IMC

Se escogio `IMC` por tres razones:

### 1. Es parte natural del curso

El enunciado permite metodologias vistas hasta IMC, asi que esta totalmente alineado.

### 2. La planta es invertible

No tiene tiempo muerto ni ceros raros en el semiplano derecho. Entonces IMC cae muy bien.

### 3. El filtro permite imponer una forma de lazo cerrado muy clara

Con:

```math
F(s)=\frac{1}{(\lambda s+1)^3}
```

fijas directamente la dinamica nominal deseada.

## 13. Que hace lambda

`lambda` es el parametro mas importante del diseño IMC.

Si `lambda` es muy pequeno:

- la respuesta es muy rapida;
- el controlador se vuelve agresivo;
- se puede notar mas la diferencia con el modelo realista.

Si `lambda` es muy grande:

- la respuesta es mas lenta;
- el control es mas suave;
- el sistema suele ser mas robusto.

En este proyecto se dejo:

- `lambda = 0.10 s`

porque da una respuesta razonablemente rapida sin disparar demasiado la senal de control.

## 14. Que significa que la respuesta nominal sea

```math
T(s)=\frac{1}{(\lambda s+1)^3}
```

Significa que, para el modelo aproximado ideal, el comportamiento de lazo cerrado queda completamente gobernado por tres polos iguales en `-1/lambda`.

Eso trae dos ventajas:

- la respuesta es monotona o casi monotona;
- se puede justificar facil en el informe.

## 15. Como se prueban seguimiento y perturbacion

La actividad no solo pide un paso unitario.

Pide:

- seguimiento de una referencia escalon variable;
- rechazo a perturbaciones.

Por eso se armó la referencia por tramos:

- `0 mm`
- `4 mm`
- `-2.5 mm`
- `3 mm`

y la base vibratoria tambien por tramos:

- sin perturbacion al inicio;
- vibracion principal senoidal;
- vibracion mixta despues.

Eso permite contar una historia completa:

- primero el controlador lleva la plataforma al setpoint;
- luego aparece una base que vibra;
- y se observa que tanto logra desacoplar la plataforma de esa perturbacion.

## 16. Que miden las metricas

### Overshoot

Cuanto se pasa la salida del valor final deseado.

### Tiempo de establecimiento

Cuanto tarda en entrar y quedarse cerca del valor final.

### Error en estado estacionario

Que tan lejos queda la salida del valor de referencia al final.

### RMS del error durante perturbacion

No es una de las cuatro clasicas del enunciado, pero aqui es muy util porque resume que tan bien se rechaza la vibracion durante un intervalo.

## 17. Que archivo hace cada cosa

### `Modelado_Plataforma_Antivibratoria.m`

Es el archivo principal tipo guion del proyecto. Sirve para estudiar el sistema paso a paso.

### `parametros_plataforma.m`

Define todos los parametros fisicos y de simulacion.

### `analisis_plataforma_antivibratoria.m`

Hace el trabajo numerico fuerte:

- simula;
- calcula metricas;
- genera figuras;
- guarda resultados.

### `generarBaseVibratoria.m`

Es el equivalente conceptual de `generarCarretera.m` del ejemplo. Aqui no genera una carretera, sino el perfil temporal de la base.

### `construir_modelos_estilo_ejemplo.m`

Organiza los modelos con nombres parecidos a los del ejemplo:

- `comparacion_modelos.slx`
- `comparacion_controladores.slx`
- `sistema_real.slx`

### `guia_armado_simscape.md`

Te explica como llevar el modelo fisico a Simscape de forma ordenada.

## 18. Que parte es mas importante que entiendas para sustentar

Si en la sustentacion te preguntan y solo puedes dominar tres ideas, deben ser estas:

### Idea 1

El sistema realista usa movimiento relativo entre plataforma y base. Esa es la clave fisica correcta.

### Idea 2

El modelo aproximado es de tercer orden porque incluye la dinamica del actuador mas la parte mecanica de segundo orden.

### Idea 3

El controlador se diseña con el modelo aproximado, pero se valida sobre el modelo realista. Esa comparacion es el corazon de toda la actividad.

## 19. Que debes decir si te preguntan por que no todo se hace en el modelo lineal

Porque el modelo lineal se usa para diseño y analisis, pero no captura:

- saturacion;
- friccion seca;
- rigidez no lineal;
- topes mecanicos.

Y precisamente la actividad quiere que se vea la diferencia entre ambos niveles de modelado.

## 20. Si te preguntan por que esta aplicacion es realista

Porque un sistema de aislamiento vibratorio activo es una aplicacion real:

- mesas opticas,
- aislamiento de sensores,
- proteccion de instrumentos de precision,
- plataformas antivibracion industriales.

No es un ejemplo inventado sin contexto. Es una aplicacion completamente defendible.

## 21. Si te preguntan por que no usamos “prediccion de terremotos”

Porque eso era una formulacion debil para el curso. Lo correcto tecnicamente es hablar de:

- medicion de vibraciones;
- aislamiento vibratorio;
- rechazo de perturbaciones tipo sismico.

Eso es mucho mas preciso y mucho mas defendible.

## 22. Que esta realmente terminado y que no

### Ya esta terminado

- el planteamiento del proyecto;
- el modelo realista matematico;
- el modelo aproximado de tercer orden;
- el controlador IMC;
- las señales de prueba;
- la base del informe;
- la explicacion detallada.

### Todavia requiere validacion en tu MATLAB

- correr y revisar todos los `.slx`;
- ajustar visualmente el diagrama final;
- cerrar una version Simscape completamente validada si quieren esa ruta.

## 23. Resumen en una frase

Este proyecto estudia como controlar una plataforma activa para que un equipo sensible se mueva lo menos posible cuando la base vibra, comparando un modelo lineal de diseño con un modelo realista no lineal.
