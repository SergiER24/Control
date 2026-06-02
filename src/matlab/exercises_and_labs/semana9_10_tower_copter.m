clear;
clc;
close all;

%% Configuracion del equipo
grupo = 1;          % Cambiar por su numero de grupo
phase_margin = 60;  % Valor conservador para MP < 15%

%% Modelo del Tower Copter
% 2.4712*dy/dt + y(t) = 0.32029*u(t)
s = tf('s');
G = 0.32029 / (2.4712 * s + 1);

%% Semana 9: funcion de transferencia y analisis
fprintf('SEMANA 9\n');
fprintf('Funcion de transferencia en lazo abierto:\n');
G

z = zero(G);
p = pole(G);
k = dcgain(G);
tau = 2.4712;
tss_2 = 4 * tau;
tss_5 = 3 * tau;

fprintf('Ceros: ');
disp(z.');
fprintf('Polos: ');
disp(p.');
fprintf('Ganancia DC: %.4f\n', k);

if all(real(p) < 0)
    fprintf('Estabilidad: el sistema es estable en lazo abierto.\n');
else
    fprintf('Estabilidad: el sistema NO es estable en lazo abierto.\n');
end

fprintf(['Clasificacion: sistema de primer orden, aperiodico, ', ...
    'no oscilatorio y con respuesta monotona.\n']);
fprintf('Constante de tiempo tau = %.4f s\n', tau);
fprintf('Tiempo de establecimiento aproximado al 2%% = %.4f s\n', tss_2);
fprintf('Tiempo de establecimiento aproximado al 5%% = %.4f s\n', tss_5);

info_ol = stepinfo(G);
disp('Metricas de la respuesta al escalon en lazo abierto:');
disp(info_ol);

%% Semana 10: sintonizacion PID en frecuencia
X = settling_time_by_group(grupo);
wc = 6 / X;

fprintf('\nSEMANA 10\n');
fprintf('Grupo: %d\n', grupo);
fprintf('Especificacion de establecimiento X = %.2f s\n', X);
fprintf('Frecuencia de cruce inicial usada para la sintonia: %.4f rad/s\n', wc);

[C, info_pid] = pidtune(G, 'PID', wc, ...
    pidtuneOptions('PhaseMargin', phase_margin));

L = minreal(C * G);
T = minreal(feedback(L, 1));
U = minreal(feedback(C, G));

info_cl = stepinfo(T);
meets_mp = info_cl.Overshoot < 15;
meets_ts = info_cl.SettlingTime < X;

fprintf('Controlador obtenido:\n');
C

fprintf('Frecuencia de cruce lograda: %.4f rad/s\n', info_pid.CrossoverFrequency);
fprintf('Margen de fase logrado: %.2f grados\n', info_pid.PhaseMargin);

disp('Metricas del sistema en lazo cerrado:');
disp(info_cl);

fprintf('Cumple overshoot < 15%%: %s\n', string(meets_mp));
fprintf('Cumple tss < X: %s\n', string(meets_ts));

%% Tabla resumen para el informe
resumen = table(grupo, X, C.Kp, C.Ki, C.Kd, ...
    info_pid.CrossoverFrequency, info_pid.PhaseMargin, ...
    info_cl.SettlingTime, info_cl.Overshoot, ...
    'VariableNames', {'Grupo', 'X_seg', 'Kp', 'Ki', 'Kd', ...
    'wc_rad_s', 'PM_deg', 'tss_seg', 'MP_pct'});

disp('Tabla resumen:');
disp(resumen);

%% Graficas solicitadas
figure('Color', 'w', 'Position', [100 100 950 800]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
step(G);
grid on;
title('Semana 9: respuesta al escalon en lazo abierto');

nexttile;
step(T);
grid on;
title('Semana 10: respuesta al escalon en lazo cerrado');

nexttile;
step(U);
grid on;
title('Semana 10: senal de control u(t)');

nexttile;
margin(L);
grid on;
title('Lazo abierto compensado C(s)G(s)');

function X = settling_time_by_group(grupo)
    group_table = [
         1 17;  2 17;  3 17;  4 16;  5 15;  6 14;
         7 14;  8 13;  9 13; 10 19; 11 18; 12 16;
        13 19; 14 17; 15 20; 16 15; 17 16; 18 15;
        19 13; 20 14; 21 19; 22 16; 23 20; 24 17];

    idx = group_table(:, 1) == grupo;

    if ~any(idx)
        error('El grupo debe estar entre 1 y 24.');
    end

    X = group_table(idx, 2);
end
