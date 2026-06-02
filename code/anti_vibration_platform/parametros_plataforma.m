function p = parametros_plataforma()
%PARAMETROS_PLATAFORMA Parametros fisicos y de simulacion del proyecto.

s = tf('s');

% Parametros fisicos nominales de la plataforma
p.m = 12.0;          % kg
p.k = 1800.0;        % N/m
p.c = 95.0;          % N*s/m

% No linealidades del modelo realista
p.k3 = 6.0e4;        % N/m^3, resorte cubico
p.Fc = 1.0;          % N, friccion tipo Coulomb suavizada
p.v_eps = 1.0e-3;    % m/s, suavizado de tanh

% Actuador
p.Ka = 220.0;        % N/V, ganancia del actuador
p.tau_a = 0.04;      % s, dinamica del actuador
p.u_sat = 1.5;       % V, saturacion del actuador

% Topes mecanicos del modelo realista
p.x_lim = 0.015;     % m
p.k_stop = 8.0e4;    % N/m
p.c_stop = 600.0;    % N*s/m

% Disenos de prueba
p.u_step_ol = 0.05;  % V, escalon en lazo abierto
p.lambda = 0.10;     % s, filtro IMC

% Tiempos de simulacion
p.t_ol = 4.0;
p.t_cl = 24.0;
p.dt = 1.0e-3;

% Referencias por tramos para lazo cerrado
p.t_ref1 = 1.0;
p.t_ref2 = 9.0;
p.t_ref3 = 16.0;
p.ref1 = 0.0040;     % 4.0 mm
p.ref2 = -0.0025;    % -2.5 mm
p.ref3 = 0.0030;     % 3.0 mm

% Ventana principal de perturbacion
p.t_dist1 = 6.0;
p.t_dist2 = 14.0;

% Planta lineal aproximada: G(s) = Ka / ((tau_a s + 1)(m s^2 + c s + k))
p.G = minreal(p.Ka / ((p.tau_a*s + 1) * (p.m*s^2 + p.c*s + p.k)));

% Control IMC nominal con filtro F(s) = 1 / (lambda s + 1)^3
p.Fimc = 1 / (p.lambda*s + 1)^3;
p.Gc = minreal(((p.tau_a*s + 1) * (p.m*s^2 + p.c*s + p.k)) / ...
    (p.Ka * p.lambda * s * (p.lambda^2*s^2 + 3*p.lambda*s + 3)));
p.Tnom = minreal(feedback(p.Gc * p.G, 1));

% Propiedades derivadas de la parte mecanica
p.wn = sqrt(p.k / p.m);
p.zeta = p.c / (2 * sqrt(p.m * p.k));

% Mallas de tiempo
p.tvec_ol = (0:p.dt:p.t_ol).';
p.tvec_cl = (0:p.dt:p.t_cl).';

% Directorio de trabajo
p.workdir = fileparts(mfilename('fullpath'));
end
