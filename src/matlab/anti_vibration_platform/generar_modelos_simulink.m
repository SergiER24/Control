function generar_modelos_simulink()
%GENERAR_MODELOS_SIMULINK
% Genera modelos base en Simulink para la actividad.

p = parametros_plataforma();
outdir = fileparts(mfilename('fullpath'));
addpath(outdir);

preparar_senales_workspace(p);

crear_modelo_aproximado_lineal_abierto(p, outdir);
crear_modelo_realista_no_lineal_abierto(p, outdir);
crear_lazo_cerrado_lineal_imc(p, outdir);
crear_lazo_cerrado_no_lineal_imc(p, outdir);

fprintf('\nModelos Simulink generados en:\n%s\n', outdir);
fprintf(['Si desea migrar el modelo realista a Simscape, use la guia del ', ...
    'documento detallado.\n']);
end

function preparar_senales_workspace(p)
t_ol = p.tvec_ol;
u_ol = [t_ol, p.u_step_ol * ones(size(t_ol))];
z_ol = [t_ol, zeros(size(t_ol))];
zd_ol = [t_ol, zeros(size(t_ol))];

t_cl = p.tvec_cl;
r = arrayfun(@(tt) ref_profile(tt, p), t_cl);
[z, zd] = arrayfun(@(tt) base_profile(tt, p), t_cl);

assignin('base', 'u_ol_signal', u_ol);
assignin('base', 'z_ol_signal', z_ol);
assignin('base', 'zd_ol_signal', zd_ol);
assignin('base', 'ref_signal', [t_cl, r]);
assignin('base', 'z_signal', [t_cl, z]);
assignin('base', 'zd_signal', [t_cl, zd]);
assignin('base', 'plant_num', p.Ka);
assignin('base', 'plant_den', conv([p.tau_a 1], [p.m p.c p.k]));
assignin('base', 'controller_num', conv([p.tau_a 1], [p.m p.c p.k]));
assignin('base', 'controller_den', ...
    p.Ka * p.lambda * conv([1 0], [p.lambda^2 3*p.lambda 3]));
end

function crear_modelo_aproximado_lineal_abierto(p, outdir)
mdl = 'modelo_aproximado_lineal_abierto';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_ol));

add_block('simulink/Sources/From Workspace', [mdl '/u_cmd'], ...
    'VariableName', 'u_ol_signal', 'Position', [40 80 150 110]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/PlantaLineal'], ...
    'Numerator', 'plant_num', 'Denominator', 'plant_den', ...
    'Position', [220 70 360 120]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [430 64 520 126]);
add_block('simulink/Sinks/To Workspace', [mdl '/y_ol_lineal'], ...
    'VariableName', 'y_ol_lineal', 'SaveFormat', 'StructureWithTime', ...
    'Position', [430 150 560 180]);

add_line(mdl, 'u_cmd/1', 'PlantaLineal/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'Scope/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'y_ol_lineal/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_lazo_cerrado_lineal_imc(p, outdir)
mdl = 'lazo_cerrado_lineal_imc';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_cl));

add_block('simulink/Sources/From Workspace', [mdl '/Referencia'], ...
    'VariableName', 'ref_signal', 'Position', [35 65 145 95]);
add_block('simulink/Math Operations/Sum', [mdl '/Error'], ...
    'Inputs', '+-', 'Position', [190 62 210 98]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ControladorIMC'], ...
    'Numerator', 'controller_num', 'Denominator', 'controller_den', ...
    'Position', [255 48 405 112]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [440 59 510 101]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/PlantaLineal'], ...
    'Numerator', 'plant_num', 'Denominator', 'plant_den', ...
    'Position', [560 48 700 112]);
add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
    'Inputs', '3', 'Position', [770 53 790 127]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [845 48 935 132]);
add_block('simulink/Sinks/To Workspace', [mdl '/salida_lineal_cl'], ...
    'VariableName', 'salida_lineal_cl', 'SaveFormat', 'StructureWithTime', ...
    'Position', [845 150 980 180]);

add_line(mdl, 'Referencia/1', 'Error/1', 'autorouting', 'on');
add_line(mdl, 'Error/1', 'ControladorIMC/1', 'autorouting', 'on');
add_line(mdl, 'ControladorIMC/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'PlantaLineal/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'Error/2', 'autorouting', 'on');
add_line(mdl, 'Referencia/1', 'Mux/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'Mux/2', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'Mux/3', 'autorouting', 'on');
add_line(mdl, 'Mux/1', 'Scope/1', 'autorouting', 'on');
add_line(mdl, 'Mux/1', 'salida_lineal_cl/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_modelo_realista_no_lineal_abierto(p, outdir)
mdl = 'modelo_realista_no_lineal_abierto';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_ol));

add_block('simulink/Sources/From Workspace', [mdl '/u_cmd'], ...
    'VariableName', 'u_ol_signal', 'Position', [30 65 140 95]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [180 58 250 102]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Actuador'], ...
    'Numerator', mat2str(p.Ka), ...
    'Denominator', mat2str([p.tau_a 1]), ...
    'Position', [295 48 395 112]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_v'], ...
    'Position', [615 55 645 85]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_x'], ...
    'Position', [710 55 740 85]);
add_block('simulink/Sources/From Workspace', [mdl '/z_base'], ...
    'VariableName', 'z_ol_signal', 'Position', [445 150 555 180]);
add_block('simulink/Sources/From Workspace', [mdl '/zd_base'], ...
    'VariableName', 'zd_ol_signal', 'Position', [445 205 555 235]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxSusp'], ...
    'Inputs', '4', 'Position', [430 28 450 122]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/FuerzaSuspension'], ...
    'MATLABFcn', expr_fuerza_no_lineal(p), ...
    'OutputDimensions', '1', ...
    'Position', [485 42 620 78]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxTope'], ...
    'Inputs', '2', 'Position', [430 248 450 302]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/FuerzaTope'], ...
    'MATLABFcn', expr_fuerza_tope(p), ...
    'OutputDimensions', '1', ...
    'Position', [485 255 620 291]);
add_block('simulink/Math Operations/Sum', [mdl '/SumaFuerzas'], ...
    'Inputs', '+--', 'Position', [575 46 595 114]);
add_block('simulink/Math Operations/Gain', [mdl '/1_m'], ...
    'Gain', num2str(1/p.m), 'Position', [615 115 680 145]);
add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
    'Inputs', '3', 'Position', [790 45 810 125]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [850 40 945 130]);

add_line(mdl, 'u_cmd/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'Actuador/1', 'autorouting', 'on');
add_line(mdl, 'Actuador/1', 'SumaFuerzas/1', 'autorouting', 'on');
add_line(mdl, 'SumaFuerzas/1', '1_m/1', 'autorouting', 'on');
add_line(mdl, '1_m/1', 'Integrador_v/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'Integrador_x/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'MuxSusp/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'MuxSusp/2', 'autorouting', 'on');
add_line(mdl, 'z_base/1', 'MuxSusp/3', 'autorouting', 'on');
add_line(mdl, 'zd_base/1', 'MuxSusp/4', 'autorouting', 'on');
add_line(mdl, 'MuxSusp/1', 'FuerzaSuspension/1', 'autorouting', 'on');
add_line(mdl, 'FuerzaSuspension/1', 'SumaFuerzas/2', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'MuxTope/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'MuxTope/2', 'autorouting', 'on');
add_line(mdl, 'MuxTope/1', 'FuerzaTope/1', 'autorouting', 'on');
add_line(mdl, 'FuerzaTope/1', 'SumaFuerzas/3', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'Mux/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'Mux/2', 'autorouting', 'on');
add_line(mdl, 'Actuador/1', 'Mux/3', 'autorouting', 'on');
add_line(mdl, 'Mux/1', 'Scope/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_lazo_cerrado_no_lineal_imc(p, outdir)
mdl = 'lazo_cerrado_no_lineal_imc';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_cl));

add_block('simulink/Sources/From Workspace', [mdl '/Referencia'], ...
    'VariableName', 'ref_signal', 'Position', [30 60 140 90]);
add_block('simulink/Math Operations/Sum', [mdl '/Error'], ...
    'Inputs', '+-', 'Position', [175 56 195 94]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ControladorIMC'], ...
    'Numerator', 'controller_num', 'Denominator', 'controller_den', ...
    'Position', [235 44 390 106]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [420 53 490 97]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Actuador'], ...
    'Numerator', mat2str(p.Ka), ...
    'Denominator', mat2str([p.tau_a 1]), ...
    'Position', [525 43 625 107]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_v'], ...
    'Position', [845 50 875 80]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_x'], ...
    'Position', [925 50 955 80]);
add_block('simulink/Sources/From Workspace', [mdl '/z_base'], ...
    'VariableName', 'z_signal', 'Position', [665 155 775 185]);
add_block('simulink/Sources/From Workspace', [mdl '/zd_base'], ...
    'VariableName', 'zd_signal', 'Position', [665 210 775 240]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxSusp'], ...
    'Inputs', '4', 'Position', [650 23 670 127]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/FuerzaSuspension'], ...
    'MATLABFcn', expr_fuerza_no_lineal(p), ...
    'OutputDimensions', '1', ...
    'Position', [705 37 840 73]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxTope'], ...
    'Inputs', '2', 'Position', [650 258 670 312]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/FuerzaTope'], ...
    'MATLABFcn', expr_fuerza_tope(p), ...
    'OutputDimensions', '1', ...
    'Position', [705 265 840 301]);
add_block('simulink/Math Operations/Sum', [mdl '/SumaFuerzas'], ...
    'Inputs', '+--', 'Position', [800 42 820 110]);
add_block('simulink/Math Operations/Gain', [mdl '/1_m'], ...
    'Gain', num2str(1/p.m), 'Position', [840 110 900 140]);
add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
    'Inputs', '4', 'Position', [1015 40 1035 140]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [1070 36 1170 145]);

add_line(mdl, 'Referencia/1', 'Error/1', 'autorouting', 'on');
add_line(mdl, 'Error/1', 'ControladorIMC/1', 'autorouting', 'on');
add_line(mdl, 'ControladorIMC/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'Actuador/1', 'autorouting', 'on');
add_line(mdl, 'Actuador/1', 'SumaFuerzas/1', 'autorouting', 'on');
add_line(mdl, 'SumaFuerzas/1', '1_m/1', 'autorouting', 'on');
add_line(mdl, '1_m/1', 'Integrador_v/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'Integrador_x/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'Error/2', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'MuxSusp/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'MuxSusp/2', 'autorouting', 'on');
add_line(mdl, 'z_base/1', 'MuxSusp/3', 'autorouting', 'on');
add_line(mdl, 'zd_base/1', 'MuxSusp/4', 'autorouting', 'on');
add_line(mdl, 'MuxSusp/1', 'FuerzaSuspension/1', 'autorouting', 'on');
add_line(mdl, 'FuerzaSuspension/1', 'SumaFuerzas/2', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'MuxTope/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_v/1', 'MuxTope/2', 'autorouting', 'on');
add_line(mdl, 'MuxTope/1', 'FuerzaTope/1', 'autorouting', 'on');
add_line(mdl, 'FuerzaTope/1', 'SumaFuerzas/3', 'autorouting', 'on');
add_line(mdl, 'Referencia/1', 'Mux/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_x/1', 'Mux/2', 'autorouting', 'on');
add_line(mdl, 'z_base/1', 'Mux/3', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'Mux/4', 'autorouting', 'on');
add_line(mdl, 'Mux/1', 'Scope/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function expr = expr_fuerza_no_lineal(p)
expr = sprintf(['fuerza_no_lineal_suspension(u,%.15g,%.15g,', ...
    '%.15g,%.15g,%.15g)'], ...
    p.k, p.c, p.k3, p.Fc, p.v_eps);
end

function expr = expr_fuerza_tope(p)
expr = sprintf('fuerza_tope(u,%.15g,%.15g,%.15g)', ...
    p.x_lim, p.k_stop, p.c_stop);
end

function reset_model(mdl, outdir)
if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
slx = fullfile(outdir, [mdl '.slx']);
if exist(slx, 'file')
    delete(slx);
end
end

function r = ref_profile(t, p)
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

function [z, zd] = base_profile(t, p)
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
