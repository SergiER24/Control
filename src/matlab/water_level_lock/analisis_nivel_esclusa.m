function [resultados, p] = analisis_nivel_esclusa(save_figures)
%ANALISIS_NIVEL_ESCLUSA
% Modelado, analisis, diseno IMC y simulaciones del proyecto.

if nargin < 1
    save_figures = true;
end

p = parametros_esclusa();
show_figures = usejava('desktop');
outdir = p.workdir;
figdir = fullfile(outdir, 'figuras');

if ~exist(figdir, 'dir')
    mkdir(figdir);
end

fprintf('\n=== PARTE 1. MODELO LINEAL APROXIMADO ===\n');
fprintf(['G(s) = Kv / ((tau_v s + 1)(Ac Lh s^2 + Ac Rh s + Kh))\n']);
disp(p.G);

z = zero(p.G);
pl = pole(p.G);

fprintf('Ceros de la planta aproximada:\n');
disp(z.');
fprintf('Polos de la planta aproximada:\n');
disp(pl.');
fprintf('Ganancia DC de la planta: %.6f m/unidad de mando\n', dcgain(p.G));
fprintf('Frecuencia natural del bloque hidraulico: %.6f rad/s\n', p.wn);
fprintf('Factor de amortiguamiento del bloque hidraulico: %.6f\n', p.zeta);

if all(real(pl) < 0)
    fprintf('La planta aproximada es estable en lazo abierto.\n');
else
    fprintf('La planta aproximada NO es estable en lazo abierto.\n');
end

fprintf('\n=== PARTE 2. DISENO DEL CONTROLADOR IMC ===\n');
fprintf('Filtro IMC: F(s) = 1 / (lambda s + 1)^3\n');
fprintf('lambda = %.4f s\n', p.lambda);
fprintf('Controlador equivalente Gc(s):\n');
disp(p.Gc);
fprintf('Transferencia nominal de lazo cerrado T(s):\n');
disp(p.Tnom);

fprintf('\n=== PARTE 3. SIMULACION EN LAZO ABIERTO ===\n');
[y_ol_lin, t_ol] = step(p.u_step_ol * p.G, p.tvec_ol);
[t_ol_nl, h_ol_nl] = simular_lazo_abierto_realista(p);

metricas_ol_lin = metricas_escalon(t_ol, y_ol_lin, y_ol_lin(end));
metricas_ol_nl = metricas_escalon(t_ol_nl, h_ol_nl, h_ol_nl(end));

fprintf('Lazo abierto lineal: y_ss = %.6f m, Mp = %.2f %%, tss = %.2f s\n', ...
    metricas_ol_lin.yss, metricas_ol_lin.Mp, metricas_ol_lin.tss);
fprintf('Lazo abierto realista: y_ss = %.6f m, Mp = %.2f %%, tss = %.2f s\n', ...
    metricas_ol_nl.yss, metricas_ol_nl.Mp, metricas_ol_nl.tss);

fprintf('\n=== PARTE 4. SIMULACION EN LAZO CERRADO ===\n');
resp_lin = simular_lazo_cerrado(p, false);
resp_nl = simular_lazo_cerrado(p, true);

idx_step = resp_lin.t >= p.t_ref1 & resp_lin.t < p.t_dist1;
metricas_cl_lin = metricas_escalon(resp_lin.t(idx_step) - p.t_ref1, ...
    resp_lin.h(idx_step), p.ref1);
metricas_cl_nl = metricas_escalon(resp_nl.t(idx_step) - p.t_ref1, ...
    resp_nl.h(idx_step), p.ref1);

idx_dist_lin = resp_lin.t >= p.t_dist1 & resp_lin.t <= p.t_dist2;
idx_dist_nl = resp_nl.t >= p.t_dist1 & resp_nl.t <= p.t_dist2;

e_dist_lin = resp_lin.r(idx_dist_lin) - resp_lin.h(idx_dist_lin);
e_dist_nl = resp_nl.r(idx_dist_nl) - resp_nl.h(idx_dist_nl);

metricas_dist_lin.rms = sqrt(mean(e_dist_lin.^2));
metricas_dist_lin.maxe = max(abs(e_dist_lin));
metricas_dist_nl.rms = sqrt(mean(e_dist_nl.^2));
metricas_dist_nl.maxe = max(abs(e_dist_nl));

fprintf('Lazo cerrado lineal: Mp = %.2f %%, tss = %.2f s, e_ss = %.6e m\n', ...
    metricas_cl_lin.Mp, metricas_cl_lin.tss, metricas_cl_lin.ess);
fprintf('Lazo cerrado realista: Mp = %.2f %%, tss = %.2f s, e_ss = %.6e m\n', ...
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

save(fullfile(outdir, 'resultados_proyecto2_esclusa.mat'), 'resultados');

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
    plot(t_ol, y_ol_lin, 'LineWidth', 1.6);
    hold on;
    plot(t_ol_nl, h_ol_nl, '--', 'LineWidth', 1.6);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Nivel h(t) [m]');
    title('Comparacion en lazo abierto: modelo lineal vs modelo realista');
    legend('Lineal aproximado', 'Realista no lineal', 'Location', 'best');
    if save_figures
        saveas(fig1, fullfile(figdir, 'comparacion_lazo_abierto.png'));
    end

    fig2 = figure('Color', 'w', ...
        'Visible', matlab.lang.OnOffSwitchState(show_figures));
    plot(resp_lin.t, resp_lin.r, 'k--', 'LineWidth', 1.2);
    hold on;
    plot(resp_lin.t, resp_lin.h, 'LineWidth', 1.6);
    plot(resp_nl.t, resp_nl.h, 'LineWidth', 1.6);
    plot(resp_lin.t, resp_lin.d, ':', 'LineWidth', 1.4);
    grid on;
    xlabel('Tiempo (s)');
    ylabel('Nivel / perturbacion');
    title('Lazo cerrado: seguimiento de referencia y rechazo de perturbaciones');
    legend('Referencia', 'Modelo lineal', 'Modelo realista', ...
        'Perturbacion hidraulica', 'Location', 'best');
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
    ylabel('Senal de control u(t)');
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

function [t, h] = simular_lazo_abierto_realista(p)
t = p.tvec_ol;
u = p.u_step_ol * ones(size(t));
sol = ode45(@(tt, xx) ode_abierto_realista(tt, xx, p, u), ...
    [t(1) t(end)], [0; 0; 0]);
X = deval(sol, t).';
h = X(:, 1);
end

function dx = ode_abierto_realista(t, x, p, u_profile)
u = interp1(p.tvec_ol, u_profile, t, 'previous', 'extrap');
u = max(min(u, p.u_sat), -p.u_sat);

h = x(1);
q = x(2);
xv = x(3);

Habs = max(p.h0 + h, p.h_min);
head_nl = p.Kh_nl * (sqrt(Habs) - sqrt(p.h0));
loss_nl = p.Rh * q + p.Rt * q * abs(q);

dx = zeros(3, 1);
dx(1) = q / p.Ac;
dx(2) = (p.Kv * xv - loss_nl - head_nl) / p.Lh;
dx(3) = (-xv + u) / p.tau_v;
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
resp.h = X(:, 1);
resp.q = X(:, 2);
resp.xv = X(:, 3);
resp.xc = X(:, 4:end);
resp.r = arrayfun(@(tt) senal_referencia(tt, p), t);
resp.d = arrayfun(@(tt) perturbacion_hidraulica(tt, p), t);
resp.u = zeros(size(t));

for k = 1:numel(t)
    e = resp.r(k) - resp.h(k);
    uk = Cc * resp.xc(k, :).'+ Dc * e;
    resp.u(k) = max(min(uk, p.u_sat), -p.u_sat);
end
end

function dx = ode_lazo_cerrado(t, x, p, Ac, Bc, Cc, Dc, use_nonlinear_model)
h = x(1);
q = x(2);
xv = x(3);
xc = x(4:end);

r = senal_referencia(t, p);
d = perturbacion_hidraulica(t, p);
e = r - h;

u = Cc * xc + Dc * e;
u = max(min(u, p.u_sat), -p.u_sat);

if use_nonlinear_model
    Habs = max(p.h0 + h, p.h_min);
    head = p.Kh_nl * (sqrt(Habs) - sqrt(p.h0));
    loss = p.Rh * q + p.Rt * q * abs(q);
else
    head = p.Kh * h;
    loss = p.Rh * q;
end

dx = zeros(numel(x), 1);
dx(1) = q / p.Ac;
dx(2) = (p.Kv * xv - loss - head + d) / p.Lh;
dx(3) = (-xv + u) / p.tau_v;
dx(4:end) = Ac * xc + Bc * e;
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

function d = perturbacion_hidraulica(t, p)
if t < p.t_dist1 || t > p.t_dist2
    d = 0;
else
    tau = t - p.t_dist1;
    d = p.d_amp * sin(2 * pi * p.d_freq * tau);
end
end

function m = metricas_escalon(t, y, yref)
y = y(:);
t = t(:);
y0 = y(1);
yss = y(end);

if nargin < 3 || abs(yref) < 1.0e-12
    yref = yss;
end

[ypeak, idx_peak] = max(y);
[ymin, idx_min] = min(y);

if abs(yref) > 1.0e-12
    Mp = max(0, (ypeak - yref) / abs(yref) * 100);
    Mu = max(0, (yref - ymin) / abs(yref) * 100);
else
    Mp = 0;
    Mu = 0;
end

y10 = y0 + 0.1 * (yref - y0);
y90 = y0 + 0.9 * (yref - y0);

if yref >= y0
    idx10 = find(y >= y10, 1, 'first');
    idx90 = find(y >= y90, 1, 'first');
else
    idx10 = find(y <= y10, 1, 'first');
    idx90 = find(y <= y90, 1, 'first');
end

if isempty(idx10) || isempty(idx90)
    tr = NaN;
else
    tr = t(idx90) - t(idx10);
end

band = 0.02 * max(abs(yref), 1.0e-6);
idx_out = find(abs(y - yref) > band);
if isempty(idx_out)
    tss = 0;
elseif idx_out(end) < numel(t)
    tss = t(idx_out(end) + 1);
else
    tss = t(end);
end

m = struct();
m.yss = yss;
m.ess = yref - yss;
m.Mp = Mp;
m.Mu = Mu;
m.RiseTime = tr;
m.Peak = ypeak;
m.PeakTime = t(idx_peak);
m.Min = ymin;
m.MinTime = t(idx_min);
m.tss = tss;
end
