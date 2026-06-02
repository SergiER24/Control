%% Modelado de una Plataforma Antivibratoria Activa
% Este archivo esta pensado para jugar el mismo papel que el
% Modelado_Vehiculo.mlx del ejemplo entregado con la actividad.
%
% La idea es que puedas leerlo de arriba hacia abajo y entender:
% 1) cual es el sistema fisico,
% 2) como se obtiene el modelo matematico,
% 3) como se diseña el controlador,
% 4) como se comparan el modelo aproximado y el modelo realista.

clear;
clc;
close all;

show_figures = usejava('desktop');
p = parametros_plataforma();
s = tf('s');

%% Modelado fisico del sistema
% En este proyecto se modela una plataforma antivibratoria activa.
% La plataforma superior carga un equipo sensible y esta soportada
% por una suspension mecanica. La base inferior representa la fuente
% de perturbacion externa.
%
% Variables:
% x   : desplazamiento absoluto de la plataforma [m]
% z   : desplazamiento de la base vibrante [m]
% u   : senal de control aplicada al actuador [V]
% Fa  : fuerza generada por el actuador [N]
%
% Parametros:
% m   : masa de la plataforma [kg]
% k   : rigidez lineal [N/m]
% c   : amortiguamiento viscoso [N*s/m]
% k3  : rigidez cubica [N/m^3]
% Fc  : nivel de friccion tipo Coulomb [N]
% Ka  : ganancia del actuador [N/V]
% tau_a : constante de tiempo del actuador [s]

fprintf('=== PARAMETROS FISICOS ===\n');
fprintf('m     = %.4f kg\n', p.m);
fprintf('k     = %.4f N/m\n', p.k);
fprintf('c     = %.4f N*s/m\n', p.c);
fprintf('k3    = %.4f N/m^3\n', p.k3);
fprintf('Fc    = %.4f N\n', p.Fc);
fprintf('Ka    = %.4f N/V\n', p.Ka);
fprintf('tau_a = %.4f s\n\n', p.tau_a);

%% Ecuaciones del modelo realista
% Modelo mecanico:
%
%   m*x¨ = Fa - Fsusp - Fstop
%
% con
%
%   Fsusp = k(x-z) + c(xdot-zdot) + k3(x-z)^3 + Fc*tanh((xdot-zdot)/v_eps)
%
% y el actuador:
%
%   tau_a*Fadot + Fa = Ka*sat(u)
%
% El termino Fstop representa topes mecanicos bilaterales que
% restringen el desplazamiento de la plataforma.

%% Perfil de perturbacion de base
% Igual que en el ejemplo del vehiculo se genera una carretera,
% aqui se genera una base vibratoria. Primero sin perturbacion,
% luego con una vibracion principal y finalmente con una mezcla
% de dos senales senoidales pequenas.

[base_z, base_zd, tbase] = generarBaseVibratoria(p.tvec_cl, p); %#ok<ASGLU>

if show_figures
    figure('Color', 'w');
    subplot(2, 1, 1);
    plot(tbase, 1e3*base_z, 'LineWidth', 1.5);
    grid on;
    ylabel('z(t) [mm]');
    title('Perfil de la base vibratoria');

    subplot(2, 1, 2);
    plot(tbase, 1e3*base_zd, 'LineWidth', 1.5);
    grid on;
    ylabel('zdot(t) [mm/s]');
    xlabel('Tiempo [s]');
end

%% Modelo matematico aproximado
% Para disenar el controlador se desprecia:
% - la rigidez cubica,
% - la friccion no lineal,
% - la saturacion,
% - y los topes mecanicos.
%
% Si fijamos z = 0 para el analisis de la planta respecto a la entrada
% de control, queda:
%
%   m*x¨ + c*x˙ + k*x = Fa
%   tau_a*Fadot + Fa = Ka*u
%
% Luego la funcion de transferencia aproximada es:
%
%   G(s) = Ka / ((tau_a*s + 1)(m*s^2 + c*s + k))

Gp = p.G;

fprintf('=== MODELO APROXIMADO ===\n');
disp(Gp);

fprintf('Polos del modelo aproximado:\n');
disp(pole(Gp).');
fprintf('Ceros del modelo aproximado:\n');
disp(zero(Gp).');
fprintf('Ganancia DC = %.6f m/V\n', dcgain(Gp));
fprintf('wn = %.6f rad/s\n', p.wn);
fprintf('zeta = %.6f\n\n', p.zeta);

%% Comparacion en lazo abierto
% Se compara el modelo lineal aproximado con el modelo realista no lineal
% ante un escalon pequeno de control.

[resultados, p] = analisis_plataforma_antivibratoria(true); %#ok<ASGLU>

fprintf('=== RESULTADOS EN LAZO ABIERTO ===\n');
fprintf('Lineal  : yss = %.6e m, Mp = %.2f %%\n', ...
    resultados.metricas_ol_lineal.yss, ...
    resultados.metricas_ol_lineal.Mp);
fprintf('Realista: yss = %.6e m, Mp = %.2f %%\n\n', ...
    resultados.metricas_ol_realista.yss, ...
    resultados.metricas_ol_realista.Mp);

%% Diseno del controlador mediante IMC
% Se usa un filtro:
%
%   F(s) = 1 / (lambda*s + 1)^3
%
% para obtener una respuesta nominal de lazo cerrado:
%
%   T(s) = 1 / (lambda*s + 1)^3
%
% con lambda = 0.10 s.
%
% El controlador equivalente en realimentacion queda:
%
%   Gc(s) = ((tau_a*s+1)(m*s^2+c*s+k)) /
%           (Ka*lambda*s*(lambda^2*s^2+3*lambda*s+3))

fprintf('=== CONTROLADOR IMC ===\n');
disp(p.Gc);

%% Implementacion en Simulink
% Igual que en el ejemplo, se generan modelos para:
%
% - comparacion entre modelos
% - comparacion del comportamiento en lazo cerrado
% - sistema realista
%
% Los nombres de salida se alinean con el ejemplo:
% comparacion_modelos.slx
% comparacion_controladores.slx
% sistema_real.slx

construir_modelos_estilo_ejemplo();

%% Evaluacion en lazo cerrado
fprintf('=== RESULTADOS EN LAZO CERRADO ===\n');
fprintf('Lineal  : Mp = %.2f %% | tss = %.4f s | ess = %.6e m\n', ...
    resultados.metricas_cl_lineal.Mp, ...
    resultados.metricas_cl_lineal.tss, ...
    resultados.metricas_cl_lineal.ess);
fprintf('Realista: Mp = %.2f %% | tss = %.4f s | ess = %.6e m\n', ...
    resultados.metricas_cl_realista.Mp, ...
    resultados.metricas_cl_realista.tss, ...
    resultados.metricas_cl_realista.ess);
fprintf('Perturbacion lineal  : RMS = %.6e m\n', ...
    resultados.metricas_dist_lineal.rms);
fprintf('Perturbacion realista: RMS = %.6e m\n', ...
    resultados.metricas_dist_realista.rms);

%% Comentario final
% Este archivo funciona como guion tecnico del proyecto.
% Si lo quieres convertir a Live Script, abre este .m en MATLAB y usa:
% Save As > MATLAB Live Script (*.mlx)
