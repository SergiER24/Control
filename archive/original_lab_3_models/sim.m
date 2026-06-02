%% PARÁMETROS DEL SISTEMA QUANSER SRV02 ROTPEN [cite: 82-135]
mp = 0.127;     % Masa del péndulo [kg] [cite: 85-88]
Lp = 0.337;     % Longitud del péndulo [m] [cite: 89-91]
Jp = 0.0012;    % Momento de inercia del péndulo [kg*m^2] [cite: 92-95]
Bp = 0.0024;    % Coef. amortiguación del péndulo [N*m*s/rad] [cite: 96-99]
Lr = 0.2159;    % Longitud del brazo rotatorio [m] [cite: 100-103]
Jr = 9.98e-4;   % Momento de inercia del brazo [kg*m^2] [cite: 105-108]
Br = 0.0024;    % Coef. amortiguación del brazo [N*m*s/rad] [cite: 110-114]
Rm = 2.6;       % Resistencia de la armadura [Ohm] [cite: 115-118]
kt = 7.68e-3;   % Constante torque-corriente [N*m/A] [cite: 119-121]
km = 7.68e-3;   % Constante fuerza contraelectromotriz [V*s/rad] [cite: 122-124]
Kg = 70;        % Relación de transmisión [cite: 126-127]
eta_m = 0.69;   % Eficiencia del motor [cite: 128]
eta_g = 0.9;    % Eficiencia de la caja de cambios [cite: 129]
g = 9.777;      % Gravedad [m/s^2] [cite: 133-135]

%% 1 y 2. REPRESENTACIÓN EN ESPACIO DE ESTADOS [cite: 139-150]
% Variables agrupadas para simplificar las ecuaciones matriciales
J_eq = mp*Lr^2 + Jr;
Jp_star = Jp + 0.25*mp*Lp^2;
M_eq = 0.5*mp*Lp*Lr;
Peq = 0.5*mp*Lp*g;
c1 = (eta_g * Kg * eta_m * kt) / Rm;
c2 = (eta_g * Kg^2 * eta_m * kt * km) / Rm + Br;
Delta = J_eq*Jp_star - M_eq^2;

% Construcción de matrices A, B, C, D
A = [0, 0, 1, 0;
     0, 0, 0, 1;
     0, (M_eq*Peq)/Delta, -(Jp_star*c2)/Delta, -(M_eq*Bp)/Delta;
     0, (J_eq*Peq)/Delta, -(M_eq*c2)/Delta,   -(J_eq*Bp)/Delta];

B = [0;
     0;
     (Jp_star*c1)/Delta;
     (M_eq*c1)/Delta];

% La salida es x2 (alfa) [cite: 150]
C = [0, 1, 0, 0;
    1, 0, 0, 0];
D = 0;

%% 3. ANÁLISIS DE ESTABILIDAD [cite: 151]
polos_lazo_abierto = eig(A);

%% 4. CONTROLABILIDAD Y OBSERVABILIDAD [cite: 152]
Co = ctrb(A,B);
rango_Co = rank(Co);

Ob = obsv(A,C);
rango_Ob = rank(Ob);

%% 5 y 6. POLINOMIO CARACTERÍSTICO Y POLOS DESEADOS [cite: 153-156]
zeta = 0.7;
wn = 4;

% Cálculo de polos complejos conjugados [cite: 154-155]
p1 = -zeta*wn + 1i*wn*sqrt(1-zeta^2);
p2 = -zeta*wn - 1i*wn*sqrt(1-zeta^2);
p3 = -30;
p4 = -40;

polos_deseados = [p1, p2, p3, p4];

%% 7. DISEÑO DEL CONTROLADOR (FÓRMULA DE ACKERMAN) [cite: 157-159]
K = acker(A, B, polos_deseados);

%% RESULTADOS
disp('--- MATRICES DEL SISTEMA ---');
disp('Matriz A:'); disp(A);
disp('Matriz B:'); disp(B);
disp('--- PROPIEDADES ---');
fprintf('Rango matriz controlabilidad: %d\n', rango_Co);
fprintf('Rango matriz observabilidad: %d\n', rango_Ob);
disp('--- CONTROLADOR ---');
disp('Vector de Ganancias K:'); disp(K);