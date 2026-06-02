clear;
clc;
close all;

%% Configuracion del equipo
grupo = 22;       % Cambiar por su numero de grupo
phase_margin = 60;  % Valor conservador para MP < 15%

%% Modelo del Tower Copter
% 2.4712*dy/dt + y(t) = 0.32029*u(t)
s = tf('s');
G = 0.32029 / ((2.4712 * s + 1)* (0.24712*s+1));

%% Semana 9: funcion de transferencia y analisis
fprintf('SEMANA 9\n');
fprintf('Funcion de transferencia en lazo abierto:\n');

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
X = 16;
wc = 6 / X;

fprintf('\nSEMANA 10\n');
fprintf('Grupo: %d\n', grupo);
fprintf('Especificacion de establecimiento X = %.2f s\n', X);
fprintf('Frecuencia de cruce inicial usada para la sintonia: %.4f rad/s\n', wc);

[C, info_pid] = pidtune(G, 'PID', wc, ...
    pidtuneOptions('PhaseMargin', phase_margin));

L = minreal(C * G);
T = minreal(feedback(L, 1));

t_vec = linspace(0, 40, 2000);
[y_cl, ~] = step(T, t_vec);
e_cl = 1 - y_cl;
dt   = t_vec(2) - t_vec(1);
u_t  = C.Kp * e_cl ...
     + C.Ki * cumtrapz(t_vec, e_cl) ...
     + C.Kd * [0; diff(e_cl)/dt];



info_cl = stepinfo(T);
meets_mp = info_cl.Overshoot < 15;
meets_ts = info_cl.SettlingTime < X;

fprintf('Controlador obtenido:\n');

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
plot(t_vec, u_t);
grid on;
title('Semana 10: senal de control u(t)');

nexttile;
margin(L);
grid on;
title('Lazo abierto compensado C(s)G(s)');

fprintf('N (filtro derivativo) = %.4f\n', 1/C.Tf);
