# Actividad 2 Resuelta

Proyecto base para la Actividad 2 de Análisis de Sistemas de Control.

## Tema del proyecto

Plataforma antivibratoria activa para aislar un equipo sensible montado sobre una base con vibración.

## Qué contiene esta carpeta

- `registro_proyecto.txt`: texto corto para registrar el proyecto en Bloque Neón.
- `Modelado_Plataforma_Antivibratoria.m`: guion principal del proyecto, organizado por secciones al estilo del ejemplo entregado.
- `parametros_plataforma.m`: parámetros físicos, señales de prueba y modelos lineales del sistema.
- `analisis_plataforma_antivibratoria.m`: modelado, linealización, análisis de estabilidad, diseño IMC, simulaciones y métricas.
- `generar_modelos_simulink.m`: genera modelos `.slx` en Simulink para la planta lineal, la planta no lineal y ambos lazos cerrados.
- `construir_modelos_estilo_ejemplo.m`: organiza salidas y nombres de archivo siguiendo la estructura del ejemplo de la actividad.
- `generarBaseVibratoria.m`: genera la perturbación de base, análoga al papel que juega `generarCarretera.m` en el ejemplo del vehículo.
- `fuerza_no_lineal_suspension.m` y `fuerza_tope.m`: funciones auxiliares usadas por los bloques no lineales generados en Simulink.
- `run_all.m`: punto de entrada para ejecutar todo.
- `documento_detallado.md`: explicación completa del proyecto y de cada decisión de modelado.
- `explicacion_super_detallada.md`: versión más pedagógica, pensada para estudio y sustentación.
- `documento_unificado_depurado.tex`: versión principal recomendada; reúne el modelo completo con la notación final, elimina lo innecesario y deja una sola narrativa coherente.
- `modelado_mecanico_linealizacion_rigurosa.tex`: derivación más rigurosa del proyecto, separando leyes físicas, relaciones constitutivas, linealización por Jacobianos y obtención del modelo simplificado.
- `glosario_variables_plataforma.tex`: glosario completo de variables, parámetros, matrices y símbolos usados en las ecuaciones.
- `texto_corto_presentacion_contexto_laboratorio.txt`: párrafo corto listo para presentar el proyecto con el contexto del sensor ultrasónico y rechazo de perturbaciones.
- `guia_armado_simscape.md`: guía paso a paso para llevar el modelo físico a Simscape.
- `informe_ieee_actividad2.tex`: borrador del informe final en formato IEEE.
- `figuras/`: carpeta reservada para gráficas y resultados exportados.

## Cómo ejecutarlo en MATLAB 2025a

1. Abra MATLAB.
2. Cambie el directorio actual a esta carpeta.
3. Ejecute:

```matlab
run_all
```

Eso hará lo siguiente:

- cargará parámetros;
- ejecutará el análisis matemático;
- correrá simulaciones lineales y no lineales;
- guardará un archivo `resultados_actividad2.mat`;
- generará archivos `.slx` en esta misma carpeta;
- dejará nombres de archivo alineados con el ejemplo del curso.

## Archivos `.slx` que se generan

- `modelo_aproximado_lineal_abierto.slx`
- `modelo_realista_no_lineal_abierto.slx`
- `lazo_cerrado_lineal_imc.slx`
- `lazo_cerrado_no_lineal_imc.slx`
- `comparacion_modelos.slx`
- `comparacion_controladores.slx`
- `sistema_real.slx`

## Alcance y limitación importante

Esta solución está preparada para MATLAB 2025a, pero en este entorno no había una instalación local de MATLAB ni Simulink para validar la ejecución real de los `.slx`. Por eso dejé:

- scripts MATLAB completos y coherentes;
- el modelo no lineal planteado con bloques estándar de Simulink, que sí cumple el enunciado;
- una guía detallada en `documento_detallado.md` para migrar el modelo realista a Simscape si el profesor o el grupo desean esa versión;
- una guía específica en `guia_armado_simscape.md` para montar la versión física con la lógica del ejemplo.

## Qué documento usar para estudiar o sustentar

- Si quiere una explicación general del proyecto: `documento_detallado.md`.
- Si quiere una versión más pedagógica y narrativa: `explicacion_super_detallada.md`.
- Si quiere un único documento limpio, con el modelo final depurado y sin términos innecesarios: `documento_unificado_depurado.tex`.
- Si quiere la versión más rigurosa para justificar leyes físicas, equilibrio, linealización y simplificaciones: `modelado_mecanico_linealizacion_rigurosa.tex`.
- Si quiere solo el diccionario de símbolos y variables para pegar en el informe: `glosario_variables_plataforma.tex`.

## Qué deben editar ustedes antes de entregar

- Reemplazar los nombres de los integrantes en `registro_proyecto.txt`.
- Completar nombres, correos y grupo en `informe_ieee_actividad2.tex`.
- Ejecutar `run_all` en MATLAB 2025a y exportar las figuras definitivas.
- Revisar y ajustar cualquier detalle visual de los modelos `.slx`.
