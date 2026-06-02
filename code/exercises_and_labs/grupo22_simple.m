clear;
clc;
close all;

show_figures = usejava('desktop');

%% Configuracion del equipo
grupo = 22;
X = 16;               % Para el grupo 22 la guia pide tss < 16 s
phase_margin = 60;    % Valor conservador para MP < 15%

%% Modelo base del Tower Copter
% 2.4712*dy/dt + y(t) = 0.32029*u(t)
K = 0.32029;
tau = 2.4712;
s = tf('s');

% Planta original de primer orden
G_original = K/(tau*s + 1);

% Ajuste pedido en monitoria:
% agregar un polo 10 veces mas a la izquierda que el polo original
tau_extra = tau/10;
G = G_original/(tau_extra*s + 1);

%% Semana 9: funcion de transferencia y analisis
fprintf('SEMANA 9\n');
fprintf('Funcion de transferencia en lazo abierto:\n');
disp(G);

z = zero(G);
p = pole(G);
k = dcgain(G);
tss_2 = 4*tau;
tss_5 = 3*tau;

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

fprintf(['Clasificacion: sistema de segundo orden con dos polos reales ', ...
    'negativos. Como el polo agregado esta 10 veces mas a la izquierda, ', ...
    'el comportamiento dominante sigue siendo parecido al de primer orden.\n']);
fprintf('Constante de tiempo dominante tau = %.4f s\n', tau);
fprintf('Tiempo de establecimiento aproximado al 2%% = %.4f s\n', tss_2);
fprintf('Tiempo de establecimiento aproximado al 5%% = %.4f s\n', tss_5);

info_ol = stepinfo(G);
disp('Metricas de la respuesta al escalon en lazo abierto:');
disp(info_ol);

% Respuesta en lazo abierto para graficar y reportar
t_ol = linspace(0, 20, 2000);
[y_ol, t_ol] = step(G, t_ol);

%% Semana 10: sintonizacion PID en frecuencia
wc = 6/X;

fprintf('\nSEMANA 10\n');
fprintf('Grupo: %d\n', grupo);
fprintf('Especificacion de establecimiento X = %.2f s\n', X);
fprintf('Frecuencia de cruce inicial usada para la sintonia: %.4f rad/s\n', wc);

[C, info_pid] = pidtune(G, 'PID', wc, ...
    pidtuneOptions('PhaseMargin', phase_margin));

L = minreal(C*G);
T = minreal(feedback(L, 1));

% Se reconstruye u(t) directamente a partir del error para mostrar
% por separado la contribucion proporcional, integral y derivativa.
t_vec = linspace(0, 40, 2000);
[y_cl, ~] = step(T, t_vec);
e_cl = 1 - y_cl;
dt = t_vec(2) - t_vec(1);
u_t = C.Kp*e_cl ...
    + C.Ki*cumtrapz(t_vec, e_cl) ...
    + C.Kd*[0; diff(e_cl)/dt];

info_cl = stepinfo(T);
meets_mp = info_cl.Overshoot < 15;
meets_ts = info_cl.SettlingTime < X;

fprintf('Controlador obtenido:\n');
disp(C);
fprintf('Frecuencia de cruce lograda: %.4f rad/s\n', info_pid.CrossoverFrequency);
fprintf('Margen de fase logrado: %.2f grados\n', info_pid.PhaseMargin);

disp('Metricas del sistema en lazo cerrado:');
disp(info_cl);

fprintf('\nResumen del controlador PID:\n');
fprintf('Kp = %.4f\n', C.Kp);
fprintf('Ki = %.4f\n', C.Ki);
fprintf('Kd = %.4f\n', C.Kd);

if isprop(C, 'Tf') && C.Tf > 0
    fprintf('N (filtro derivativo) = %.4f\n', 1/C.Tf);
else
    fprintf('N (filtro derivativo) = infinito en la forma ideal del PID\n');
end

fprintf('\nCumple overshoot < 15%%: %s\n', string(meets_mp));
fprintf('Cumple tss < X: %s\n', string(meets_ts));

resumen = table(grupo, X, C.Kp, C.Ki, C.Kd, ...
    info_pid.CrossoverFrequency, info_pid.PhaseMargin, ...
    info_cl.SettlingTime, info_cl.Overshoot, ...
    'VariableNames', {'Grupo', 'X_seg', 'Kp', 'Ki', 'Kd', ...
    'wc_rad_s', 'PM_deg', 'tss_seg', 'MP_pct'});

disp('Tabla resumen:');
disp(resumen);

%% Graficas solicitadas
figure('Color', 'w', 'Visible', matlab.lang.OnOffSwitchState(show_figures));
pzmap(G);
grid on;
title('Semana 9 - Mapa de polos y ceros de la planta ajustada');

figure('Color', 'w', 'Visible', matlab.lang.OnOffSwitchState(show_figures));
plot(t_ol, y_ol, 'LineWidth', 1.4);
hold on;
yline(1, '--', 'Referencia r = 1', 'LineWidth', 1.0);
hold off;
grid on;
title('Semana 9 - Respuesta al escalon en lazo abierto');
xlabel('Tiempo (s)');
ylabel('Salida y(t)');
legend('y_{OL}(t)', 'r(t)', 'Location', 'best');

figure('Color', 'w', 'Visible', matlab.lang.OnOffSwitchState(show_figures));
yyaxis left;
plot(t_vec, y_cl, 'LineWidth', 1.4);
ylabel('Salida y(t)');

yyaxis right;
plot(t_vec, u_t, 'LineWidth', 1.4);
ylabel('Control u(t)');

grid on;
xlabel('Tiempo (s)');
title('Semana 10 - Comparacion entre salida y senal de control');
legend('y(t)', 'u(t)', 'Location', 'best');

figure('Color', 'w', 'Visible', matlab.lang.OnOffSwitchState(show_figures));
margin(L);
grid on;
title('Semana 10 - Lazo abierto compensado C(s)G(s)');
