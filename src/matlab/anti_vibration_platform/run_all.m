clear;
clc;
close all;

fprintf('Actividad 2 - Plataforma antivibratoria activa\n');
fprintf('Directorio de trabajo: %s\n', fileparts(mfilename('fullpath')));

p = parametros_plataforma();
[resultados, p] = analisis_plataforma_antivibratoria(true); %#ok<ASGLU>
generar_modelos_simulink();
construir_modelos_estilo_ejemplo();

fprintf('\nProceso finalizado.\n');
fprintf('Revise los archivos .slx, el archivo resultados_actividad2.mat y el script Modelado_Plataforma_Antivibratoria.m.\n');
