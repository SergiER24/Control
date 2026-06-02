clear; clc; close all;
format short g;

%% Practica 3.2 - MagLev
% Script completo para:
% 1) linealizacion en espacio de estados
% 2) controlabilidad y observabilidad
% 3) diseno del controlador u = -Kx
% 4) simulacion sin Kg
% 5) simulacion con Kg = -705
% 6) simulacion con control integral Ke = -4000

%% Constantes de la guia
K_m = 6.5308e-5;
M_b = 0.068;
g   = 9.81;
R_s = 1;
R_c = 10;
R   = R_s + R_c;
L_c = 0.4125;

%% Punto de operacion de la Figura 2
x_01 = 6e-3;
x_02 = 0;
x_03 = 0.86;
x_03_eq = sqrt(2 * M_b * g * x_01^2 / K_m);
u_0 = R * x_03;

%% Modelo linealizado alrededor de (x_01, x_02, x_03)
% f1 = x2
% f2 = g - (K_m/(2*M_b)) * (x3/x1)^2
% f3 = -(R/L_c) * x3 + (1/L_c) * u
%
% A = df/dx |x0 , B = df/du |x0 , C = dh/dx |x0
A = [0, 1, 0;
     (K_m / M_b) * (x_03^2 / x_01^3), 0, -(K_m / M_b) * (x_03 / x_01^2);
     0, 0, -R / L_c];

B = [0;
     0;
     1 / L_c];

C = [1, 0, 0];
D = 0;

%% Mostrar resultados del prelaboratorio
disp('===== PUNTO DE OPERACION =====');
fprintf('x0 = [%.6f  %.6f  %.6f]^T\n', x_01, x_02, x_03);
fprintf('x03 de equilibrio exacto = %.6f A\n', x_03_eq);
fprintf('u0 asociado a x03 = %.6f V\n\n', u_0);

disp('===== MATRICES LINEALIZADAS =====');
disp('A ='); disp(A);
disp('B ='); disp(B);
disp('C ='); disp(C);
disp('D ='); disp(D);

%% Controlabilidad y observabilidad
Co = [B, A * B, A^2 * B];
Ob = [C;
      C * A;
      C * A^2];

rango_Co = rank(Co);
rango_Ob = rank(Ob);

disp('===== CONTROLABILIDAD Y OBSERVABILIDAD =====');
disp('Matriz de controlabilidad Co ='); disp(Co);
disp('Matriz de observabilidad Ob ='); disp(Ob);
fprintf('rank(Co) = %d\n', rango_Co);
fprintf('rank(Ob) = %d\n', rango_Ob);

if rango_Co == size(A, 1)
    disp('=> El sistema es controlable.');
else
    disp('=> El sistema NO es controlable.');
end

if rango_Ob == size(A, 1)
    disp('=> El sistema es observable.');
else
    disp('=> El sistema NO es observable.');
end

%% Diseno de K con Ackermann
% Polinomio pedido por la guia:
% (s + 100)(s^2 + 28s + 400) = s^3 + 128s^2 + 3200s + 40000
pol_deseado = [1, 128, 3200, 40000];
p_deseados = roots(pol_deseado);

phi_A = A^3 + 128 * A^2 + 3200 * A + 40000 * eye(3);
K = [0, 0, 1] * (Co \ phi_A);

Acl = A - B * K;
autovalores_cl = eig(Acl);

disp('===== CONTROLADOR =====');
disp('Polos deseados ='); disp(p_deseados);
disp('K ='); disp(K);
disp('Polos de A - B*K ='); disp(autovalores_cl);

%% Ganancia de referencia
Kg_calculado = -1 / (C * (Acl \ B));
Kg_guia = -705;
Ke = -4000;

disp('===== GANANCIAS ADICIONALES =====');
fprintf('Kg calculado por ganancia DC = %.6f\n', Kg_calculado);
fprintf('Kg usado en la guia         = %.6f\n', Kg_guia);
fprintf('Ke usado en la guia         = %.6f\n', Ke);

%% Simulaciones
t_final = 2.0;
tspan = linspace(0, t_final, 3000).';
r0 = 0.006;
ref = r0 * ones(size(tspan));

% Caso 1: realimentacion de estados sin Kg
x0 = zeros(3, 1);
[t1, x1] = ode45(@(t, x) dinamica_estado(t, x, A, B, K, r0), tspan, x0);
y1 = (C * x1.').';

% Caso 2: realimentacion de estados con Kg = -705
[t2, x2] = ode45(@(t, x) dinamica_estado(t, x, A, B, K, Kg_guia * r0), tspan, x0);
y2 = (C * x2.').';

% Caso 3: control integral con Ke = -4000
x0_aug = zeros(4, 1);
[t3, x3_aug] = ode45(@(t, x) dinamica_integral(t, x, A, B, C, K, Ke, r0), tspan, x0_aug);
y3 = x3_aug(:, 1:3) * C.';

%% Reporte numerico rapido
disp('===== VALORES FINALES DE LAS SIMULACIONES =====');
fprintf('Sin Kg:            y(%.1f s) = %.8f m\n', t1(end), y1(end));
fprintf('Con Kg = -705:     y(%.1f s) = %.8f m\n', t2(end), y2(end));
fprintf('Con control int.:  y(%.1f s) = %.8f m\n', t3(end), y3(end));

%% Graficas
figure('Color', 'w', 'Name', 'MagLev - Sin Kg');
plot(t1, ref, '--k', 'LineWidth', 1.5); hold on;
plot(t1, y1, 'b', 'LineWidth', 2);
grid on;
xlabel('Tiempo [s]');
ylabel('Salida y = x_1 [m]');
title('Respuesta con realimentacion de estados sin Kg');
legend('Referencia', 'Salida', 'Location', 'best');

figure('Color', 'w', 'Name', 'MagLev - Con Kg');
plot(t2, ref, '--k', 'LineWidth', 1.5); hold on;
plot(t2, y2, 'r', 'LineWidth', 2);
grid on;
xlabel('Tiempo [s]');
ylabel('Salida y = x_1 [m]');
title('Respuesta con realimentacion de estados y Kg = -705');
legend('Referencia', 'Salida', 'Location', 'best');

figure('Color', 'w', 'Name', 'MagLev - Control integral');
plot(t3, ref, '--k', 'LineWidth', 1.5); hold on;
plot(t3, y3, 'm', 'LineWidth', 2);
grid on;
xlabel('Tiempo [s]');
ylabel('Salida y = x_1 [m]');
title('Respuesta con control integral, Ke = -4000');
legend('Referencia', 'Salida', 'Location', 'best');

%% Si quiere exportar figuras, descomente estas lineas:
% exportgraphics(figure(1), 'maglev_sin_Kg.png', 'Resolution', 300);
% exportgraphics(figure(2), 'maglev_con_Kg.png', 'Resolution', 300);
% exportgraphics(figure(3), 'maglev_control_integral.png', 'Resolution', 300);

function dx = dinamica_estado(~, x, A, B, K, r)
u = r - K * x;
dx = A * x + B * u;
end

function dx = dinamica_integral(~, x_aug, A, B, C, K, Ke, r)
x = x_aug(1:3);
z = x_aug(4);

y = C * x;
e = r - y;
u = Ke * z - K * x;

dx = zeros(4, 1);
dx(1:3) = A * x + B * u;
dx(4) = e;
end
