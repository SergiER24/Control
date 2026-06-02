function p = parametros_esclusa()
%PARAMETROS_ESCLUSA Parametros fisicos y de simulacion del proyecto.

s = tf('s');

% Camara de esclusa
p.Ac = 40.0;         % m^2, area efectiva de la camara
p.h0 = 4.0;          % m, nivel nominal de operacion
p.h_min = 1.0e-4;    % m, cota minima para evitar raiz de numero negativo

% Hidraulica linealizada
p.Lh = 3.0;          % s^2/m^2, inercia hidraulica equivalente
p.Rh = 0.65;         % s/m^2, perdida lineal equivalente
p.Kh = 1.0;          % 1/s^2, rigidez hidraulica linealizada
p.Kv = 0.70;         % m^3/(s*cmd), ganancia flujo-valvula

% No linealidades del modelo realista
p.Rt = 0.50;         % perdida turbulenta proporcional a q|q|
p.Kh_nl = 2 * sqrt(p.h0) * p.Kh; % asegura la misma linealizacion local

% Actuador de valvula
p.tau_v = 2.0;       % s, dinamica del actuador
p.u_sat = 1.0;       % apertura maxima normalizada

% Pruebas
p.u_step_ol = 0.25;  % escalon en lazo abierto
p.lambda = 5.0;      % s, filtro IMC

% Ventanas de simulacion
p.t_ol = 180.0;
p.t_cl = 320.0;
p.dt = 0.05;

% Referencia en lazo cerrado
p.t_ref1 = 20.0;
p.t_ref2 = 120.0;
p.t_ref3 = 220.0;
p.ref1 = 0.25;       % m
p.ref2 = -0.15;      % m
p.ref3 = 0.10;       % m

% Perturbacion hidraulica
p.t_dist1 = 80.0;
p.t_dist2 = 180.0;
p.d_amp = 0.05;      % amplitud equivalente de perturbacion
p.d_freq = 0.03;     % Hz

% Planta lineal aproximada
% G(s) = H(s)/U(s) = Kv / ((tau_v s + 1)(Ac Lh s^2 + Ac Rh s + Kh))
p.G = minreal(p.Kv / ((p.tau_v * s + 1) * ...
    (p.Ac * p.Lh * s^2 + p.Ac * p.Rh * s + p.Kh)));

% Ruta de perturbacion hidraulica d(t) -> h(t)
p.Gd = minreal(1 / (p.Ac * p.Lh * s^2 + p.Ac * p.Rh * s + p.Kh));

% Control IMC nominal con T(s) = 1 / (lambda s + 1)^3
p.Fimc = 1 / (p.lambda * s + 1)^3;
p.Gc = minreal(((p.tau_v * s + 1) * ...
    (p.Ac * p.Lh * s^2 + p.Ac * p.Rh * s + p.Kh)) / ...
    (p.Kv * p.lambda * s * (p.lambda^2 * s^2 + 3 * p.lambda * s + 3)));
p.Tnom = minreal(feedback(p.Gc * p.G, 1));

% Propiedades derivadas del subsistema hidraulico de segundo orden
p.wn = sqrt(p.Kh / (p.Ac * p.Lh));
p.zeta = (p.Ac * p.Rh) / (2 * sqrt((p.Ac * p.Lh) * p.Kh));

% Mallas temporales
p.tvec_ol = (0:p.dt:p.t_ol).';
p.tvec_cl = (0:p.dt:p.t_cl).';

% Directorio de trabajo
p.workdir = fileparts(mfilename('fullpath'));
end
