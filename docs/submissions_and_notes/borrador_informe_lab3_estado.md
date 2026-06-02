# Checklist de entrega - Laboratorio 3 Control

Sugerencia para cumplir la extensión de 6 páginas: agrupar las gráficas de cada bloque en figuras con subfiguras `(a)`, `(b)` y `(c)`, y dejar los diagramas de bloques como figuras compactas. No usar capturas de pantalla; exportar las figuras directamente desde MATLAB/Simulink.

## Práctica 3.1 - Simulación

- [ ] Incluir las ecuaciones linealizadas del sistema en el punto de operación.
- [ ] Reportar las matrices `A`, `B`, `C` y `D` del sistema linealizado.
- [ ] Analizar la estabilidad a partir de los polos del sistema.
- [ ] Mostrar la matriz de controlabilidad, la matriz de observabilidad y concluir si el sistema es controlable y observable.
- [ ] Mostrar el polinomio característico de orden 4 que satisface `zeta = 0.7`, `wn = 4`, con polos adicionales en `-30` y `-40`.
- [ ] Reportar el vector `K` del controlador.
- [ ] Incluir el diagrama de bloques donde se implementa la realimentación de estados.
- [ ] Incluir una gráfica nítida de simulación con referencia y salida de `x1`.
- [ ] Incluir una gráfica nítida de simulación con referencia y salida de `x2`.
- [ ] Incluir una gráfica nítida de la señal de control.

## Práctica 3.1 - Experimental

- [ ] Incluir una gráfica experimental nítida con referencia y salida de `x1`.
- [ ] Incluir una gráfica experimental nítida con referencia y salida de `x2`.
- [ ] Incluir una gráfica experimental nítida de la señal de control.
- [ ] Comparar explícitamente simulación vs experimento.
- [ ] Responder: `¿Qué implicaciones tienen la controlabilidad y la observabilidad a la hora de diseñar un controlador de realimentación de estados?`
- [ ] Responder: `¿Qué pasaría si la situación inicial del sistema estuviera lejos del punto de equilibrio?`

## Práctica 3.2 - Simulación

- [ ] Incluir las ecuaciones linealizadas del MagLev en el punto de operación.
- [ ] Reportar las matrices `A`, `B` y `C`.
- [ ] Demostrar controlabilidad y observabilidad.
- [ ] Mostrar el polinomio característico `(s + 100)(s^2 + 28s + 400)`.
- [ ] Reportar el vector `K` del controlador.
- [ ] Incluir el diagrama de bloques del controlador en espacio de estados.
- [ ] Incluir el diagrama de bloques del controlador con ganancia `Kg`.
- [ ] Incluir el diagrama de bloques del controlador integral.
- [ ] Incluir la gráfica de la salida con referencia para el controlador sin `Kg`.
- [ ] Incluir la gráfica de la salida con referencia para el controlador con `Kg = -705`.
- [ ] Incluir la gráfica de la salida con referencia para el controlador integral con `Ke = -4000`.

## Práctica 3.2 - Experimental

- [ ] Incluir la gráfica experimental de la salida con la referencia.
- [ ] Analizar el comportamiento mostrado por la gráfica experimental.
- [ ] Comparar explícitamente la respuesta experimental con la respuesta simulada.
- [ ] Responder: `¿Qué ventajas tiene la representación de estados para la implementación de un controlador?`

---

# Borrador del informe

## Introducción

En este laboratorio se estudió el diseño de controladores en representación de estados para dos sistemas no lineales de referencia en control: el péndulo invertido rotatorio Quanser SRV02 ROTPEN y el levitador magnético MagLev. En ambos casos, el punto de partida fue la linealización del modelo dinámico alrededor de un punto de operación, con el fin de obtener una representación de estado útil para analizar estabilidad, controlabilidad, observabilidad y para diseñar leyes de control por realimentación de estados.

La práctica 3.1 se enfocó en el péndulo invertido rotatorio, un sistema inherentemente inestable cuyo objetivo es mantener el péndulo cerca de la posición vertical mientras el brazo sigue una referencia cuadrada en `x1 = theta`. La práctica 3.2 se centró en el MagLev, donde se diseñó un controlador en espacio de estados para regular la posición de la esfera y se comparó el desempeño del sistema con y sin ganancia de referencia `Kg`, además de una implementación con acción integral. En conjunto, ambas prácticas permiten evaluar la utilidad de la representación de estados para modelar, estabilizar y comparar el desempeño entre simulación y montaje experimental.

## Análisis

### Práctica 3.1 - Péndulo invertido rotatorio

La linealización alrededor del punto de operación `alpha = 0`, `theta = 0`, `alpha_dot = 0` y `theta_dot = 0` conduce al sistema de estados

```text
x1 = theta
x2 = alpha
x3 = theta_dot
x4 = alpha_dot
u  = Vm
```

y a las ecuaciones linealizadas

```text
x1_dot = x3
x2_dot = x4
x3_dot = 81.2304 x2 - 28.8469 x3 - 0.9318 x4 + 51.8559 u
x4_dot = 121.6276 x2 - 27.7325 x3 - 1.3952 x4 + 49.8525 u
```

En forma matricial, las matrices obtenidas fueron

```text
A = [ 0        0        1        0
      0        0        0        1
      0   81.2304 -28.8469  -0.9318
      0  121.6276 -27.7325  -1.3952 ]

B = [ 0
      0
     51.8559
     49.8525 ]

C = [ 0 1 0 0
      1 0 0 0 ]

D = [ 0
      0 ]
```

Para el análisis de estabilidad en lazo abierto se calcularon los polos del sistema y se obtuvo

```text
p = {0, -32.3563, 7.3762, -5.2620}
```

Este resultado muestra que el sistema no es asintóticamente estable en lazo abierto, porque presenta un polo positivo en `7.3762` y además un polo en el origen. En términos físicos, esto significa que pequeñas perturbaciones alrededor de la posición de equilibrio no desaparecen por sí solas y, por el contrario, pueden crecer con el tiempo. Esta observación es consistente con la naturaleza del péndulo invertido, cuya posición vertical es una configuración inestable si no se aplica control.

El análisis estructural mostró que la matriz de controlabilidad y la matriz de observabilidad tienen rango completo:

```text
rank(Co) = 4
rank(Ob) = 4
```

Por lo tanto, el sistema es completamente controlable y observable. Esto es fundamental para el diseño del controlador, porque garantiza que es posible mover los polos del sistema mediante la entrada `u`, y que la información contenida en la salida es suficiente para reconstruir el comportamiento dinámico relevante del sistema.

Usando las especificaciones de diseño `zeta = 0.7` y `wn = 4`, los polos dominantes deseados del segundo orden son

```text
p1,2 = -2.8 +- j 2.8566
```

Al añadir los polos rápidos en `-30` y `-40`, el polinomio característico deseado de orden cuatro queda

```text
p_d(s) = (s + 30)(s + 40)(s^2 + 5.6 s + 16)
       = s^4 + 75.6 s^3 + 1608 s^2 + 7840 s + 19200
```

Con este polinomio se obtuvo el vector de ganancias del controlador

```text
K = [-8.5047   45.3961   -4.1266   5.2023]
```

En la simulación del sistema lineal con referencia cuadrada de amplitud `20 grados` y frecuencia `0.1 Hz`, el estado `x1 = theta` siguió la referencia con un sobreimpulso apreciable, alcanzando picos aproximados de `+-28.64 grados`. El estado `x2 = alpha` permaneció acotado dentro de `+-8.72 grados`, lo que indica que la realimentación de estados logra mantener al péndulo cerca de la vertical durante los cambios de consigna. La señal de control se mantuvo aproximadamente entre `-5.42 V` y `5.42 V`, por lo que el controlador estabiliza el sistema con un esfuerzo moderado en el entorno del modelo lineal.

[Insertar Figura 1 aquí: diagrama de bloques de la realimentación de estados de la práctica 3.1.]



[Insertar Figura 2 aquí: resultados de simulación de la práctica 3.1 agrupados en tres subfiguras: (a) referencia y salida de `x1`, (b) referencia y salida de `x2`, (c) señal de control.]



Tomando como base las figuras guardadas en la carpeta `Lab 3 control`, la respuesta medida/obtenida del sistema muestra un comportamiento menos ideal que el modelo lineal. En el archivo `Lab3-theta.fig`, la referencia de `x1` oscila entre `-20 grados` y `20 grados`, mientras que la salida presenta excursiones mayores, aproximadamente entre `-185.27 grados` y `83.32 grados`. Esto sugiere la presencia de efectos no modelados, saturación del actuador, ruido y posiblemente diferencias en la convención angular o en el desenvolvimiento de fase del sensor. En `lab3_alpha.fig`, la señal de `x2` se mueve entre `-180 grados` y `179.82 grados`, lo que indica que la lectura angular probablemente está envuelta en el intervalo `[-180, 180] grados`; por ello, en el pie de figura conviene aclarar que la cercanía al equilibrio vertical puede verse tanto alrededor de `0 grados` como de `+-180 grados`, según la referencia del sensor. Finalmente, en `Lab3-señal_control.fig` la señal de control permanece aproximadamente entre `-7.03 V` y `7.80 V`, es decir, con un esfuerzo mayor que el estimado en simulación.

[Insertar Figura 3 aquí: resultados experimentales de la práctica 3.1 agrupados en tres subfiguras usando `Lab3-theta.fig`, `lab3_alpha.fig` y `Lab3-señal_control.fig`.]



La comparación entre simulación y experimento muestra que el modelo linealizado captura la estructura principal del sistema y permite diseñar un controlador estabilizante, pero no reproduce exactamente la respuesta del montaje real. En simulación, el seguimiento de `x1` es más limpio, la desviación de `x2` es menor y el esfuerzo de control es más contenido. En la implementación medida, en cambio, aparecen excursiones angulares más grandes, señales con ruido y un esfuerzo de control superior. Estas diferencias son esperables porque la simulación lineal ignora efectos como fricción, saturación, cuantización de sensores, retardos de adquisición y errores de calibración. En particular, la linealización solo es válida cerca del punto de equilibrio, mientras que en el sistema real pueden aparecer desviaciones más amplias durante los cambios bruscos de referencia.

Respecto a la pregunta sobre las implicaciones de la controlabilidad y la observabilidad, la controlabilidad garantiza que los modos dinámicos del sistema pueden desplazarse mediante la entrada y, por tanto, que sí es posible ubicar los polos cerrados en posiciones deseadas para estabilizar el péndulo y ajustar su rapidez de respuesta. La observabilidad, por su parte, asegura que la dinámica interna puede inferirse a partir de las salidas medidas; esto es clave cuando en una implementación futura no se midan todos los estados directamente y sea necesario diseñar un observador. Si alguna de estas propiedades faltara, el diseño por realimentación de estados sería incompleto: habría modos imposibles de estabilizar o modos internos imposibles de reconstruir.

Frente a la pregunta sobre qué ocurriría si la condición inicial estuviera lejos del equilibrio, la respuesta es que el modelo lineal perdería validez y el controlador diseñado alrededor de ese punto podría dejar de estabilizar el sistema adecuadamente. En un péndulo invertido esto puede traducirse en oscilaciones grandes, saturación de la señal de control, trayectorias no previstas por el modelo linealizado e incluso la caída del péndulo. En otras palabras, la realimentación de estados obtenida aquí funciona bien cerca del punto de operación, pero no garantiza el mismo desempeño ante perturbaciones o condiciones iniciales muy alejadas de la vertical.

### Práctica 3.2 - Levitador magnético MagLev

Para el MagLev se linealizó el sistema alrededor del punto de operación `x0 = [0.006, 0, 0.86]^T`, donde `x1` es la posición de la esfera, `x2` su velocidad y `x3` la corriente de la bobina. Con los parámetros de la guía, las ecuaciones linealizadas en variables de desviación quedan

```text
dx1/dt = x2
dx2/dt = 3270 x1 - 22.9432 x3
dx3/dt = -26.6667 x3 + 2.4242 u
y = x1
```

Por tanto, la representación matricial es

```text
A = [   0        1        0
      3270       0   -22.9432
         0       0   -26.6667 ]

B = [ 0
      0
      2.4242 ]

C = [ 1 0 0 ]
```

El sistema linealizado en lazo abierto tiene un polo inestable, lo cual es coherente con la naturaleza del levitador magnético. Sin control, una pequeña perturbación en la posición de la esfera crece y la levitación no se sostiene por sí sola. Sin embargo, la matriz de controlabilidad y la de observabilidad tienen rango completo:

```text
rank(Co) = 3
rank(Ob) = 3
```

De este modo, el sistema es controlable y observable, y puede diseñarse un controlador por ubicación de polos.

El polinomio característico especificado por la guía es

```text
(s + 100)(s^2 + 28s + 400) = s^3 + 128 s^2 + 3200 s + 40000
```

Usando la misma formulación del archivo experimental `MagLev_StateFeedback.slx`, el vector de ganancias obtenido con `place(A,B,rootsPoly)` es

```text
K = [-8230.1618   -116.1816    41.8]
```

Además, la ganancia de precompensación calculada por ganancia DC resulta aproximadamente

```text
Kg ~= -704.785
```

valor consistente con el `Kg = -705` indicado en la guía. Para el controlador integral se empleó `Ke = -4000`.

[Insertar Figura 4 aquí: diagramas de bloques de la práctica 3.2 agrupados en subfiguras: (a) controlador en espacio de estados, (b) controlador con `Kg`, (c) controlador integral.]



En simulación, el caso sin `Kg` evidencia una limitación importante del controlador de realimentación pura: aunque estabiliza la dinámica, no asegura por sí solo el seguimiento correcto de la referencia. Ante un escalón de `0.006 m`, la salida final fue aproximadamente `-8.51e-6 m`, es decir, prácticamente cero, con un error estacionario cercano a la totalidad de la referencia. Esto muestra que la realimentación de estados regula el sistema, pero necesita una compensación adicional para seguir la consigna.

Cuando se agrega la ganancia `Kg = -705`, la respuesta mejora de manera decisiva. La salida final fue `0.0060018 m`, el sobreimpulso fue aproximadamente `4.25 %` y el tiempo de establecimiento al `2 %` fue cercano a `0.313 s`. En este caso, el sistema no solo permanece estable sino que además sigue con buena precisión la referencia de `6 mm`, cumpliendo satisfactoriamente la intención del diseño. El uso de `Kg` compensa la ganancia estática del sistema en lazo cerrado y elimina el error de régimen permanente sin modificar la estructura básica del realimentador de estados.

Con el controlador integral (`Ke = -4000`), la salida final fue `0.0060000 m`, el sobreimpulso fue aproximadamente `4.43 %` y el tiempo de establecimiento fue cercano a `0.525 s`. El resultado más importante de esta configuración es que el error estacionario queda prácticamente nulo, incluso ante pequeñas incertidumbres paramétricas, a costa de una respuesta algo más lenta que el caso con `Kg`. Por eso, desde el punto de vista de robustez, la acción integral resulta especialmente atractiva cuando se desea priorizar exactitud final sobre velocidad transitoria.

[Insertar Figura 5 aquí: resultados de simulación de la práctica 3.2 agrupados en tres subfiguras: (a) respuesta sin `Kg`, (b) respuesta con `Kg = -705`, (c) respuesta con control integral `Ke = -4000`.]



En la parte experimental debe insertarse la gráfica obtenida con `MagLev_StateFeedback.slx`, usando la misma matriz `C` y el mismo vector `K` empleados en simulación. El análisis de esa figura debe resaltar si la salida mantiene el seguimiento de la referencia, si aparecen oscilaciones de alta frecuencia, si el tiempo de establecimiento crece frente a la simulación y si existe o no error estacionario apreciable.

[Insertar Figura 6 aquí: gráfica experimental del MagLev con referencia y salida.]



La comparación entre simulación y experimento para el MagLev debe enfocarse en las diferencias entre el modelo lineal ideal y la planta real. En general, es razonable esperar que la curva experimental conserve la tendencia principal observada en simulación, pero con mayor ruido, mayor sensibilidad a perturbaciones y una respuesta algo más lenta por efectos no modelados. Si la gráfica experimental muestra pequeñas oscilaciones o un transitorio más largo, ello puede atribuirse a saturación del actuador, retardo de sensado, discretización, fricción eléctrica y diferencias entre el punto de operación real y el supuesto en la linealización. Si, por el contrario, el seguimiento experimental es muy cercano al simulado, esto refuerza la validez del modelo lineal en la vecindad de `x1 = 0.006 m`.

Respecto a la pregunta sobre las ventajas de la representación de estados para la implementación de un controlador, la principal es que permite trabajar directamente con las variables internas del sistema y no solo con una relación entrada-salida. Esto facilita analizar estabilidad interna, estudiar controlabilidad y observabilidad, ubicar polos en posiciones deseadas, incorporar precompensadores como `Kg`, añadir acción integral en forma sistemática y, si fuese necesario, diseñar observadores para estimar estados no medidos. En sistemas como el MagLev y el péndulo invertido, donde la dinámica es rápida, acoplada e inestable, la representación de estados ofrece una estructura mucho más potente y flexible que una aproximación exclusivamente basada en funciones de transferencia.

## Conclusiones

El desarrollo de las prácticas 3.1 y 3.2 mostró que la representación de estados es una herramienta adecuada para modelar y controlar sistemas no lineales alrededor de un punto de equilibrio. En el péndulo invertido rotatorio, el análisis de polos confirmó que la planta en lazo abierto es inestable, mientras que el estudio de controlabilidad y observabilidad verificó que la realimentación de estados sí puede estabilizar el sistema. El controlador diseñado con el polinomio de cuarto orden permitió que la simulación siguiera la referencia en `x1` manteniendo acotado el ángulo del péndulo, aunque la comparación con las curvas almacenadas en la carpeta de resultados mostró diferencias importantes debidas a efectos no modelados y a las limitaciones del montaje real.

En el MagLev, la linealización alrededor del punto de operación también condujo a un sistema inestable en lazo abierto pero completamente controlable y observable. El diseño del vector `K` por ubicación de polos estabilizó la dinámica, y además permitió evidenciar que la realimentación de estados sola no basta para un seguimiento exacto de referencia. La inclusión de una ganancia `Kg` o de una acción integral corrigió ese problema, logrando respuestas con error estacionario prácticamente nulo y buen desempeño transitorio. En conjunto, los resultados confirman que el modelado en espacio de estados no solo sirve para obtener una descripción compacta del sistema, sino también para estructurar de manera clara el análisis, el diseño y la comparación entre simulación y experimento.

Finalmente, la comparación entre los modelos linealizados y las respuestas reales reafirma una idea central del laboratorio: un controlador diseñado sobre un modelo ideal puede funcionar correctamente en la vecindad del punto de operación, pero su desempeño real siempre estará condicionado por ruido, saturaciones, incertidumbre paramétrica y no linealidades remanentes. Por eso, el valor de estas prácticas no está solo en calcular matrices y ganancias, sino en entender hasta dónde llega la validez del modelo y cómo interpretar las diferencias entre teoría e implementación.
