%% Modelado y control del nivel de agua en una camara de esclusa
% Este archivo cumple el mismo papel que el script principal del proyecto 2.
% La idea es leerlo de arriba hacia abajo y seguir:
% 1) el planteamiento fisico,
% 2) el modelo lineal de tercer orden,
% 3) el modelo no lineal realista,
% 4) el diseno del controlador IMC,
% 5) la comparacion entre ambos modelos.

clear;
clc;
close all;

show_figures = usejava('desktop');
p = parametros_esclusa();

fprintf('=== PARAMETROS DEL PROYECTO ===\n');
fprintf('Area de camara Ac          = %.4f m^2\n', p.Ac);
fprintf('Nivel nominal h0           = %.4f m\n', p.h0);
fprintf('Inercia hidraulica Lh      = %.4f\n', p.Lh);
fprintf('Perdida lineal Rh          = %.4f\n', p.Rh);
fprintf('Rigidez hidraulica Kh      = %.4f\n', p.Kh);
fprintf('Ganancia de valvula Kv     = %.4f\n', p.Kv);
fprintf('Constante de tiempo valvula= %.4f s\n', p.tau_v);
fprintf('Saturacion de mando        = +/-%.4f\n\n', p.u_sat);

%% Modelo fisico
% Estados:
% h(t)   : desviacion del nivel de agua respecto al punto de operacion [m]
% q(t)   : caudal neto en el conducto de llenado/vaciado [m^3/s]
% xv(t)  : apertura efectiva de la valvula [-]
% u(t)   : mando normalizado al actuador de la valvula [-]
%
% Modelo no lineal:
% Ac * dh/dt = q
% Lh * dq/dt = Kv*xv - Rh*q - Rt*q|q| - Kh_nl( sqrt(h0+h) - sqrt(h0) ) + d(t)
% tau_v * dxv/dt + xv = sat(u)
%
% El termino q|q| representa perdidas turbulentas y el termino con raiz
% modela la dependencia de la carga hidraulica con el nivel de agua.

%% Modelo lineal aproximado
% Al linealizar alrededor del punto de operacion:
% h = 0, q = 0, xv = 0, d = 0
% se obtiene:
%
% Ac * dh/dt = q
% Lh * dq/dt = Kv*xv - Rh*q - Kh*h
% tau_v * dxv/dt + xv = u
%
% De ahi:
%
% G(s) = H(s)/U(s) = Kv / ((tau_v s + 1)(Ac Lh s^2 + Ac Rh s + Kh))

fprintf('=== MODELO LINEAL APROXIMADO ===\n');
disp(p.G);

fprintf('Polos del modelo aproximado:\n');
disp(pole(p.G).');
fprintf('Ceros del modelo aproximado:\n');
disp(zero(p.G).');
fprintf('Ganancia DC = %.6f m/unidad de mando\n', dcgain(p.G));
fprintf('wn hidraulica = %.6f rad/s\n', p.wn);
fprintf('zeta hidraulica = %.6f\n\n', p.zeta);

%% Diseno del controlador
% Se emplea IMC con filtro:
%
% F(s) = 1 / (lambda s + 1)^3
%
% con lambda = 5 s.

fprintf('=== CONTROLADOR IMC ===\n');
disp(p.Gc);
fprintf('Transferencia nominal deseada T(s):\n');
disp(p.Tnom);

%% Analisis numerico y comparaciones
[resultados, p] = analisis_nivel_esclusa(true); %#ok<ASGLU>

fprintf('=== RESULTADOS EN LAZO ABIERTO ===\n');
fprintf('Lineal  : yss = %.6f m | Mp = %.2f %% | tss = %.2f s\n', ...
    resultados.metricas_ol_lineal.yss, ...
    resultados.metricas_ol_lineal.Mp, ...
    resultados.metricas_ol_lineal.tss);
fprintf('Realista: yss = %.6f m | Mp = %.2f %% | tss = %.2f s\n\n', ...
    resultados.metricas_ol_realista.yss, ...
    resultados.metricas_ol_realista.Mp, ...
    resultados.metricas_ol_realista.tss);

fprintf('=== RESULTADOS EN LAZO CERRADO ===\n');
fprintf('Lineal  : Mp = %.2f %% | tss = %.2f s | ess = %.6e m\n', ...
    resultados.metricas_cl_lineal.Mp, ...
    resultados.metricas_cl_lineal.tss, ...
    resultados.metricas_cl_lineal.ess);
fprintf('Realista: Mp = %.2f %% | tss = %.2f s | ess = %.6e m\n', ...
    resultados.metricas_cl_realista.Mp, ...
    resultados.metricas_cl_realista.tss, ...
    resultados.metricas_cl_realista.ess);
fprintf('RMS error durante perturbacion (lineal)  = %.6e m\n', ...
    resultados.metricas_dist_lineal.rms);
fprintf('RMS error durante perturbacion (realista)= %.6e m\n\n', ...
    resultados.metricas_dist_realista.rms);

%% Modelos Simulink
% Para crear los .slx automaticamente, ejecute:
%
% generar_modelos_simulink_esclusa

if show_figures
    fprintf('Las figuras se guardan en la carpeta figuras/.\n');
end
