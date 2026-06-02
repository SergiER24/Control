clear;
clc;
close all;

fprintf('Proyecto 2 - Control de nivel de agua en una camara de esclusa\n');
fprintf('Directorio de trabajo: %s\n', fileparts(mfilename('fullpath')));

p = parametros_esclusa(); %#ok<NASGU>
[resultados, p] = analisis_nivel_esclusa(true); %#ok<ASGLU,NASGU>
generar_modelos_simulink_esclusa();

fprintf('\nProceso finalizado.\n');
fprintf(['Revise los archivos .slx, el archivo resultados_proyecto2_esclusa.mat ', ...
    'y el script Modelado_Nivel_Esclusa.m.\n']);
