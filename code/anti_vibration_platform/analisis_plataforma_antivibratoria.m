function [resultados, p] = analisis_plataforma_antivibratoria(save_figures)
%ANALISIS_PLATAFORMA_ANTIVIBRATORIA
% Ejecuta el modelado, analisis, linealizacion, diseno IMC y simulaciones.

if nargin < 1
    save_figures = true;
end

p = parametros_plataforma();
show_figures = usejava('desktop');
outdir = p.workdir;
figdir = fullfile(outdir, 'figuras');

if ~exist(figdir, 'dir')
    mkdir(figdir);
end

fprintf('\n=== PARTE 1. MODELO LINEAL APROXIMADO ===\n');
fprintf('G(s) = Ka / ((tau_a s + 1)(m s^2 + c s + k))\n');
disp(p.G);

plant_num = p.Ka;
plant_den = conv([p.tau_a 1], [p.m p.c p.k]);
controller_num = conv([p.tau_a 1], [p.m p.c p.k]);
controller_den = p.Ka * p.lambda * conv([1 0], [p.lambda^2 3*p.lambda 3]);

z = zero(p.G);
pl = pole(p.G);

fprintf('Ceros de la planta aproximada:\n');
disp(z.');
fprintf('Polos de la planta aproximada:\n');
disp(pl.');
fprintf('Ganancia DC de la planta: %.6f m/V\n', dcgain(p.G));
fprintf('Frecuencia natural de la parte mecanica: %.4f rad/s\n', p.wn);
fprintf('Factor de amortiguamiento de la parte mecanica: %.4f\n', p.zeta);

if all(real(pl) < 0)
    fprintf('La planta aproximada es estable en lazo abierto.\n');
else
    fprintf('La planta aproximada NO es estable en lazo abierto.\n');
end

fprintf('\n=== PARTE 2. DISENO DEL CONTROLADOR IMC ===\n');
fprintf('Filtro IMC seleccionado: F(s) = 1 / (lambda s + 1)^3\n');
fprintf('lambda = %.4f s\n', p.lambda);
fprintf('Controlador resultante Gc(s):\n');
disp(p.Gc);
fprintf('Transferencia nominal en lazo cerrado T(s):\n');
disp(p.Tnom);

fprintf('\n=== PARTE 3. SIMULACION EN LAZO ABIERTO ===\n');
[y_ol_lin, t_ol] = step(p.u_step_ol * p.G, p.tvec_ol);
[t_ol_nl, x_ol_nl, Fa_ol_nl] = simular_lazo_abierto_realista(p); %#ok<ASGLU>

metricas_ol_lin = metricas_escalon(t_ol, y_ol_lin, y_ol_lin(end));
metricas_ol_nl = metricas_escalon(t_ol_nl, x_ol_nl, x_ol_nl(end));

fprintf('Lazo abierto lineal: y_ss = %.6f m, Mp = %.2f %%, tss = %.4f s\n', ...
    metricas_ol_lin.yss, metricas_ol_lin.Mp, metricas_ol_lin.tss);
fprintf('Lazo abierto realista: y_ss = %.6f m, Mp = %.2f %%, tss = %.4f s\n', ...
    metricas_ol_nl.yss, metricas_ol_nl.Mp, metricas_ol_nl.tss);

fprintf('\n=== PARTE 4. SIMULACION EN LAZO CERRADO ===\n');
resp_lin = simular_lazo_cerrado(p, false);
resp_nl  = simular_lazo_cerrado(p, true);

idx_step = resp_lin.t >= p.t_ref1 & resp_lin.t <= p.t_dist1;
metricas_cl_lin = metricas_escalon(resp_lin.t(idx_step) - p.t_ref1, ...
    resp_lin.x(idx_step), p.ref1);
metricas_cl_nl = metricas_escalon(resp_nl.t(idx_step) - p.t_ref1, ...
    resp_nl.x(idx_step), p.ref1);

idx_dist_lin = resp_lin.t >= p.t_dist1 & resp_lin.t <= p.t_dist2;
idx_dist_nl = resp_nl.t >= p.t_dist1 & resp_nl.t <= p.t_dist2;

e_dist_lin = resp_lin.r(idx_dist_lin) - resp_lin.x(idx_dist_lin);
e_dist_nl = resp_nl.r(idx_dist_nl) - resp_nl.x(idx_dist_nl);

metricas_dist_lin.rms = sqrt(mean(e_dist_lin.^2));
metricas_dist_lin.maxe = max(abs(e_dist_lin));
metricas_dist_nl.rms = sqrt(mean(e_dist_nl.^2));
metricas_dist_nl.maxe = max(abs(e_dist_nl));

fprintf('Lazo cerrado lineal: Mp = %.2f %%, tss = %.4f s, e_ss = %.6e m\n', ...
    metricas_cl_lin.Mp, metricas_cl_lin.tss, metricas_cl_lin.ess);
fprintf('Lazo cerrado realista: Mp = %.2f %%, tss = %.4f s, e_ss = %.6e m\n', ...
    metricas_cl_nl.Mp, metricas_cl_nl.tss, metricas_cl_nl.ess);
fprintf('Perturbacion lineal: RMS = %.6e m, max|e| = %.6e m\n', ...
    metricas_dist_lin.rms, metricas_dist_lin.maxe);
fprintf('Perturbacion realista: RMS = %.6e m, max|e| = %.6e m\n', ...
    metricas_dist_nl.rms, metricas_dist_nl.maxe);

resultados = struct();
resultados.p = p;
resultados.metricas_ol_lineal = metricas_ol_lin;
resultados.metricas_ol_realista = metricas_ol_nl;
resultados.metricas_cl_lineal = metricas_cl_lin;
resultados.metricas_cl_realista = metricas_cl_nl;
resultados.metricas_dist_lineal = metricas_dist_lin;
resultados.metricas_dist_realista = metricas_dist_nl;
resultados.respuesta_lineal = resp_lin;
resultados.respuesta_realista = resp_nl;

save(fullfile(outdir, 'resultados_actividad2.mat'), 'resultados');

tabla = table( ...
    metricas_ol_lin.yss, metricas_ol_lin.Mp, metricas_ol_lin.tss, ...
    metricas_ol_nl.yss, metricas_ol_nl.Mp, metricas_ol_nl.tss, ...
    metricas_cl_lin.Mp, metricas_cl_lin.tss, metricas_cl_lin.ess, ...
    metricas_cl_nl.Mp, metricas_cl_nl.tss, metricas_cl_nl.ess, ...
    metricas_dist_lin.rms, metricas_dist_lin.maxe, ...
    metricas_dist_nl.rms, metricas_dist_nl.maxe, ...
    'VariableNames', { ...
    'yss_ol_lineal', 'Mp_ol_lineal_pct', 'tss_ol_lineal_s', ...
    'yss_ol_realista', 'Mp_ol_realista_pct', 'tss_ol_realista_s', ...
    'Mp_cl_lineal_pct', 'tss_cl_lineal_s', 'ess_cl_lineal_m', ...
    'Mp_cl_realista_pct', 'tss_cl_realista_s', 'ess_cl_realista_m', ...
    'rms_dist_lineal_m', 'maxe_dist_lineal_m', ...
    'rms_dist_realista_m', 'maxe_dist_realista_m'});
writetable(tabla, fullfile(outdir, 'metricas_resumen.csv'));

if show_figures || save_figures
    fig1 = figure('Color', 'w', ...
        'Visible', matlab.lang.OnOffSwitchState(show_figures));
    plot(t_ol, y_ol_lin * 1e3, 'LineWidth', 1.6);
    hold on;
    plot(t_ol_nl, x_ol_nl * 1e3, '--', 'LineWidth', 1.6);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Desplazamiento de la plataforma (mm)');
    title('Comparacion en lazo abierto: modelo lineal vs modelo realista');
    legend('Lineal aproximado', 'Realista no lineal', 'Location', 'best');
    if save_figures
        saveas(fig1, fullfile(figdir, 'comparacion_lazo_abierto.png'));
    end

    fig2 = figure('Color', 'w', ...
        'Visible', matlab.lang.OnOffSwitchState(show_figures));
    plot(resp_lin.t, resp_lin.r * 1e3, 'k--', 'LineWidth', 1.2);
    hold on;
    plot(resp_lin.t, resp_lin.x * 1e3, 'LineWidth', 1.6);
    plot(resp_nl.t, resp_nl.x * 1e3, 'LineWidth', 1.6);
    plot(resp_lin.t, resp_lin.z * 1e3, ':', 'LineWidth', 1.4);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Desplazamiento (mm)');
    title('Lazo cerrado: seguimiento y rechazo a perturbaciones');
    legend('Referencia', 'Modelo lineal', 'Modelo realista', ...
        'Perturbacion de base', 'Location', 'best');
    if save_figures
        saveas(fig2, fullfile(figdir, 'seguimiento_y_perturbacion.png'));
    end

    fig3 = figure('Color', 'w', ...
        'Visible', matlab.lang.OnOffSwitchState(show_figures));
    plot(resp_lin.t, resp_lin.u, 'LineWidth', 1.6);
    hold on;
    plot(resp_nl.t, resp_nl.u, 'LineWidth', 1.6);
    yline(p.u_sat, '--', 'u_{sat}', 'LineWidth', 1.0);
    yline(-p.u_sat, '--', '-u_{sat}', 'LineWidth', 1.0);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Senal de control u(t) [V]');
    title('Esfuerzo de control');
    legend('Lineal', 'Realista', 'Location', 'best');
    if save_figures
        saveas(fig3, fullfile(figdir, 'esfuerzo_de_control.png'));
    end

    fig4 = figure('Color', 'w', ...
        'Visible', matlab.lang.OnOffSwitchState(show_figures));
    pzmap(p.G);
    grid on;
    title('Mapa de polos y ceros de la planta aproximada');
    if save_figures
        saveas(fig4, fullfile(figdir, 'pzmap_planta_aproximada.png'));
    end
end

end

function [t, x, Fa] = simular_lazo_abierto_realista(p)
t = p.tvec_ol;
u = p.u_step_ol * ones(size(t));
sol = ode45(@(tt, xx) ode_abierto_realista(tt, xx, p, u), [t(1) t(end)], [0; 0; 0]);
X = deval(sol, t).';
x = X(:, 1);
Fa = X(:, 3);
end

function dx = ode_abierto_realista(t, x, p, u_profile)
u = interp1(p.tvec_ol, u_profile, t, 'previous', 'extrap');
u = max(min(u, p.u_sat), -p.u_sat);

pos = x(1);
vel = x(2);
Fa = x(3);

relx = pos;
relv = vel;

Fnl = p.k*relx + p.c*relv + p.k3*relx^3 + p.Fc*tanh(relv / p.v_eps);
Fstop = hard_stop_force(pos, vel, p);

dx = zeros(3, 1);
dx(1) = vel;
dx(2) = (Fa - Fnl - Fstop) / p.m;
dx(3) = (-Fa + p.Ka*u) / p.tau_a;
end

function resp = simular_lazo_cerrado(p, use_nonlinear_model)
t = p.tvec_cl;

[Ac, Bc, Cc, Dc] = ssdata(ss(p.Gc));
nx = size(Ac, 1);

sol = ode45(@(tt, xx) ode_lazo_cerrado(tt, xx, p, Ac, Bc, Cc, Dc, ...
    use_nonlinear_model), [t(1) t(end)], zeros(3 + nx, 1));

X = deval(sol, t).';

resp = struct();
resp.t = t;
resp.x = X(:, 1);
resp.v = X(:, 2);
resp.Fa = X(:, 3);
resp.xc = X(:, 4:end);
resp.r = arrayfun(@(tt) senal_referencia(tt, p), t);
[resp.z, resp.zd] = arrayfun(@(tt) senal_base(tt, p), t);
resp.u = zeros(size(t));

for k = 1:numel(t)
    e = resp.r(k) - resp.x(k);
    uk = Cc * resp.xc(k, :).'+ Dc * e;
    resp.u(k) = max(min(uk, p.u_sat), -p.u_sat);
end
end

function dx = ode_lazo_cerrado(t, x, p, Ac, Bc, Cc, Dc, use_nonlinear_model)
pos = x(1);
vel = x(2);
Fa = x(3);
xc = x(4:end);

r = senal_referencia(t, p);
[z, zd] = senal_base(t, p);
e = r - pos;

u = Cc * xc + Dc * e;
u = max(min(u, p.u_sat), -p.u_sat);

relx = pos - z;
relv = vel - zd;

if use_nonlinear_model
    Fnl = p.k*relx + p.c*relv + p.k3*relx^3 + p.Fc*tanh(relv / p.v_eps);
    Fstop = hard_stop_force(pos, vel, p);
else
    Fnl = p.k*relx + p.c*relv;
    Fstop = 0;
end

dx = zeros(numel(x), 1);
dx(1) = vel;
dx(2) = (Fa - Fnl - Fstop) / p.m;
dx(3) = (-Fa + p.Ka*u) / p.tau_a;
dx(4:end) = Ac*xc + Bc*e;
end

function r = senal_referencia(t, p)
if t < p.t_ref1
    r = 0;
elseif t < p.t_ref2
    r = p.ref1;
elseif t < p.t_ref3
    r = p.ref2;
else
    r = p.ref3;
end
end

function [z, zd] = senal_base(t, p)
if t < p.t_dist1
    z = 0;
    zd = 0;
elseif t < p.t_dist2
    w = 2*pi*1.2;
    tau = t - p.t_dist1;
    z = 1.5e-3 * sin(w*tau);
    zd = 1.5e-3 * w * cos(w*tau);
else
    tau = t - p.t_dist2;
    w1 = 2*pi*0.8;
    w2 = 2*pi*2.4;
    z = 1.0e-3 * sin(w1*tau) + 0.6e-3 * sin(w2*tau);
    zd = 1.0e-3 * w1 * cos(w1*tau) + 0.6e-3 * w2 * cos(w2*tau);
end
end

function Fstop = hard_stop_force(pos, vel, p)
if pos > p.x_lim
    Fstop = p.k_stop * (pos - p.x_lim) + p.c_stop * max(vel, 0);
elseif pos < -p.x_lim
    Fstop = p.k_stop * (pos + p.x_lim) + p.c_stop * min(vel, 0);
else
    Fstop = 0;
end
end

function m = metricas_escalon(t, y, yref)
y = y(:);
t = t(:);
yss = y(end);

if abs(yref) < 1e-12
    yref = yss;
end

[ypeak, idx_peak] = max(y);
Mp = 100 * (ypeak - yref) / max(abs(yref), 1e-12);

idx10 = find(y >= 0.1*yref, 1, 'first');
idx90 = find(y >= 0.9*yref, 1, 'first');
if isempty(idx10) || isempty(idx90)
    tr = NaN;
else
    tr = t(idx90) - t(idx10);
end

tol = 0.02 * max(abs(yref), 1e-12);
inside = abs(y - yref) <= tol;
tss = NaN;
for k = 1:numel(t)
    if all(inside(k:end))
        tss = t(k);
        break;
    end
end

m = struct();
m.yss = yss;
m.ypeak = ypeak;
m.tp = t(idx_peak);
m.Mp = Mp;
m.tr = tr;
m.tss = tss;
m.ess = yref - y(end);
end
