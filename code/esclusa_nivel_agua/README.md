# Proyecto 2 - Nivel de agua en una camara de esclusa

Proyecto base para el caso:

> Modelado y control del nivel de agua en una camara de esclusa utilizada en canales de navegacion.

## Idea general del sistema

La entrada del sistema es la apertura de una valvula de llenado/vaciado `u(t)` y la salida es la desviacion del nivel de agua `h(t)` respecto a un punto de operacion `h_0`.

El proyecto incluye dos modelos:

- Un modelo lineal aproximado de tercer orden, usado para analisis y diseno del controlador.
- Un modelo no lineal realista, que incluye:
  - perdida turbulenta proporcional a `q|q|`;
  - dependencia de la carga hidraulica con `sqrt(h_0 + h)`;
  - saturacion del actuador de la valvula.

## Archivos principales

- `Modelado_Nivel_Esclusa.m`: guion principal, pensado para leerse y ejecutarse por secciones.
- `parametros_esclusa.m`: parametros fisicos, senales de prueba y modelos lineales.
- `analisis_nivel_esclusa.m`: analisis completo, simulaciones, metricas y figuras.
- `hidraulica_no_lineal_esclusa.m`: funcion auxiliar del modelo realista y de Simulink.
- `generar_modelos_simulink_esclusa.m`: genera los modelos `.slx` automaticamente.
- `run_all.m`: ejecuta todo el paquete.
- `informe_ieee_proyecto2_esclusa.tex`: borrador del informe en formato IEEE.
- `registro_proyecto.txt`: texto corto para registrar el tema del proyecto.

## Modelo lineal aproximado

El modelo lineal usado para el diseno es:

```math
G(s)=\\frac{H(s)}{U(s)}=
\\frac{K_v}{(\\tau_v s+1)(A_c L_h s^2 + A_c R_h s + K_h)}
```

Con los parametros incluidos en el archivo de configuracion:

- `A_c = 40`
- `L_h = 3`
- `R_h = 0.65`
- `K_h = 1`
- `K_v = 0.70`
- `tau_v = 2`

La planta aproximada queda:

```math
G(s)=\\frac{0.70}{240s^3 + 172s^2 + 28s + 1}
```

Sus polos son:

- `-0.5`
- `-0.1667`
- `-0.05`

Por tanto, la planta lineal es estable en lazo abierto.

## Controlador

Se usa control por modelo interno (IMC) con:

```math
F(s)=\\frac{1}{(\\lambda s+1)^3}, \\qquad \\lambda = 5~s
```

El controlador equivalente en realimentacion es:

```math
G_c(s)=
\\frac{(\\tau_v s+1)(A_c L_h s^2 + A_c R_h s + K_h)}
{K_v \\lambda s (\\lambda^2 s^2 + 3\\lambda s + 3)}
```

## Como ejecutarlo en MATLAB

1. Abra MATLAB.
2. Cambie el directorio actual a esta carpeta.
3. Ejecute:

```matlab
run_all
```

Eso hace lo siguiente:

- carga parametros;
- ejecuta el analisis matematico;
- corre simulaciones lineales y no lineales;
- guarda `resultados_proyecto2_esclusa.mat`;
- guarda `metricas_resumen.csv`;
- genera figuras en `figuras/`;
- genera modelos `.slx`.

## Modelos Simulink que se generan

- `modelo_lineal_abierto_esclusa.slx`
- `modelo_realista_abierto_esclusa.slx`
- `lazo_cerrado_lineal_imc_esclusa.slx`
- `lazo_cerrado_no_lineal_imc_esclusa.slx`

## Nota importante

Desde este entorno no pude ejecutar MATLAB/Simulink directamente, asi que la validacion aqui fue estructural y numerica sobre el modelo equivalente, no una corrida real de `.slx` en MATLAB. Cuando abras la carpeta en MATLAB, el primer paso recomendado es correr `run_all` y revisar las figuras generadas.
