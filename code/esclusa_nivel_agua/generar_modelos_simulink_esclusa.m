function generar_modelos_simulink_esclusa()
%GENERAR_MODELOS_SIMULINK_ESCLUSA
% Genera modelos base en Simulink para el proyecto de la esclusa.

p = parametros_esclusa();
outdir = fileparts(mfilename('fullpath'));
addpath(outdir);

preparar_senales_workspace(p);

crear_modelo_lineal_abierto(p, outdir);
crear_modelo_realista_abierto(p, outdir);
crear_lazo_cerrado_lineal(p, outdir);
crear_lazo_cerrado_no_lineal(p, outdir);

fprintf('\nModelos Simulink generados en:\n%s\n', outdir);
end

function preparar_senales_workspace(p)
t_ol = p.tvec_ol;
u_ol = [t_ol, p.u_step_ol * ones(size(t_ol))];

t_cl = p.tvec_cl;
r = arrayfun(@(tt) ref_profile(tt, p), t_cl);
d = arrayfun(@(tt) disturbance_profile(tt, p), t_cl);

assignin('base', 'u_ol_signal', u_ol);
assignin('base', 'ref_signal', [t_cl, r]);
assignin('base', 'dist_signal', [t_cl, d]);
assignin('base', 'plant_num', p.Kv);
assignin('base', 'plant_den', conv([p.tau_v 1], [p.Ac * p.Lh, p.Ac * p.Rh, p.Kh]));
assignin('base', 'dist_num', 1);
assignin('base', 'dist_den', [p.Ac * p.Lh, p.Ac * p.Rh, p.Kh]);
assignin('base', 'controller_num', conv([p.tau_v 1], [p.Ac * p.Lh, p.Ac * p.Rh, p.Kh]));
assignin('base', 'controller_den', ...
    p.Kv * p.lambda * conv([1 0], [p.lambda^2, 3 * p.lambda, 3]));
end

function crear_modelo_lineal_abierto(p, outdir)
mdl = 'modelo_lineal_abierto_esclusa';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_ol));

add_block('simulink/Sources/From Workspace', [mdl '/u_cmd'], ...
    'VariableName', 'u_ol_signal', 'Position', [40 80 145 110]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/PlantaLineal'], ...
    'Numerator', 'plant_num', 'Denominator', 'plant_den', ...
    'Position', [220 70 360 120]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [430 65 520 125]);
add_block('simulink/Sinks/To Workspace', [mdl '/y_ol_lineal'], ...
    'VariableName', 'y_ol_lineal', 'SaveFormat', 'StructureWithTime', ...
    'Position', [430 150 560 180]);

add_line(mdl, 'u_cmd/1', 'PlantaLineal/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'Scope/1', 'autorouting', 'on');
add_line(mdl, 'PlantaLineal/1', 'y_ol_lineal/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_modelo_realista_abierto(p, outdir)
mdl = 'modelo_realista_abierto_esclusa';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_ol));

add_block('simulink/Sources/From Workspace', [mdl '/u_cmd'], ...
    'VariableName', 'u_ol_signal', 'Position', [35 70 145 100]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [180 63 255 107]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ActuadorValvula'], ...
    'Numerator', '1', 'Denominator', mat2str([p.tau_v 1]), ...
    'Position', [295 55 400 115]);
add_block('simulink/Sources/Constant', [mdl '/d_zero'], ...
    'Value', '0', 'Position', [300 180 360 210]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_q'], ...
    'Position', [635 55 665 85]);
add_block('simulink/Math Operations/Gain', [mdl '/1_Ac'], ...
    'Gain', num2str(1 / p.Ac), 'Position', [700 52 760 88]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_h'], ...
    'Position', [800 55 830 85]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxDQ'], ...
    'Inputs', '4', 'Position', [460 35 480 195]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/DinamicaCaudal'], ...
    'MATLABFcn', expr_dq(p), 'OutputDimensions', '1', ...
    'Position', [520 80 645 120]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxScope'], ...
    'Inputs', '3', 'Position', [875 45 895 125]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [935 40 1030 130]);

add_line(mdl, 'u_cmd/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'ActuadorValvula/1', 'autorouting', 'on');
add_line(mdl, 'ActuadorValvula/1', 'MuxDQ/3', 'autorouting', 'on');
add_line(mdl, 'd_zero/1', 'MuxDQ/4', 'autorouting', 'on');
add_line(mdl, 'Integrador_h/1', 'MuxDQ/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_q/1', 'MuxDQ/2', 'autorouting', 'on');
add_line(mdl, 'MuxDQ/1', 'DinamicaCaudal/1', 'autorouting', 'on');
add_line(mdl, 'DinamicaCaudal/1', 'Integrador_q/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_q/1', '1_Ac/1', 'autorouting', 'on');
add_line(mdl, '1_Ac/1', 'Integrador_h/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_h/1', 'MuxScope/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_q/1', 'MuxScope/2', 'autorouting', 'on');
add_line(mdl, 'ActuadorValvula/1', 'MuxScope/3', 'autorouting', 'on');
add_line(mdl, 'MuxScope/1', 'Scope/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_lazo_cerrado_lineal(p, outdir)
mdl = 'lazo_cerrado_lineal_imc_esclusa';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_cl));

add_block('simulink/Sources/From Workspace', [mdl '/Referencia'], ...
    'VariableName', 'ref_signal', 'Position', [30 50 145 80]);
add_block('simulink/Math Operations/Sum', [mdl '/Error'], ...
    'Inputs', '+-', 'Position', [185 47 205 83]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ControladorIMC'], ...
    'Numerator', 'controller_num', 'Denominator', 'controller_den', ...
    'Position', [245 35 395 95]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [430 42 505 88]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/PlantaControl'], ...
    'Numerator', 'plant_num', 'Denominator', 'plant_den', ...
    'Position', [550 30 705 90]);
add_block('simulink/Sources/From Workspace', [mdl '/Perturbacion'], ...
    'VariableName', 'dist_signal', 'Position', [550 135 665 165]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/PlantaPerturbacion'], ...
    'Numerator', 'dist_num', 'Denominator', 'dist_den', ...
    'Position', [705 125 860 185]);
add_block('simulink/Math Operations/Sum', [mdl '/SalidaTotal'], ...
    'Inputs', '++', 'Position', [915 60 935 140]);
add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
    'Inputs', '4', 'Position', [990 45 1010 155]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [1050 40 1145 150]);

add_line(mdl, 'Referencia/1', 'Error/1', 'autorouting', 'on');
add_line(mdl, 'Error/1', 'ControladorIMC/1', 'autorouting', 'on');
add_line(mdl, 'ControladorIMC/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'PlantaControl/1', 'autorouting', 'on');
add_line(mdl, 'PlantaControl/1', 'SalidaTotal/1', 'autorouting', 'on');
add_line(mdl, 'Perturbacion/1', 'PlantaPerturbacion/1', 'autorouting', 'on');
add_line(mdl, 'PlantaPerturbacion/1', 'SalidaTotal/2', 'autorouting', 'on');
add_line(mdl, 'SalidaTotal/1', 'Error/2', 'autorouting', 'on');
add_line(mdl, 'Referencia/1', 'Mux/1', 'autorouting', 'on');
add_line(mdl, 'SalidaTotal/1', 'Mux/2', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'Mux/3', 'autorouting', 'on');
add_line(mdl, 'Perturbacion/1', 'Mux/4', 'autorouting', 'on');
add_line(mdl, 'Mux/1', 'Scope/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function crear_lazo_cerrado_no_lineal(p, outdir)
mdl = 'lazo_cerrado_no_lineal_imc_esclusa';
reset_model(mdl, outdir);
new_system(mdl);
set_param(mdl, 'StopTime', num2str(p.t_cl));

add_block('simulink/Sources/From Workspace', [mdl '/Referencia'], ...
    'VariableName', 'ref_signal', 'Position', [30 45 145 75]);
add_block('simulink/Math Operations/Sum', [mdl '/Error'], ...
    'Inputs', '+-', 'Position', [180 42 200 78]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ControladorIMC'], ...
    'Numerator', 'controller_num', 'Denominator', 'controller_den', ...
    'Position', [235 30 390 90]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Saturacion'], ...
    'UpperLimit', num2str(p.u_sat), 'LowerLimit', num2str(-p.u_sat), ...
    'Position', [420 38 495 82]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/ActuadorValvula'], ...
    'Numerator', '1', 'Denominator', mat2str([p.tau_v 1]), ...
    'Position', [530 30 635 90]);
add_block('simulink/Sources/From Workspace', [mdl '/Perturbacion'], ...
    'VariableName', 'dist_signal', 'Position', [530 150 645 180]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_q'], ...
    'Position', [830 45 860 75]);
add_block('simulink/Math Operations/Gain', [mdl '/1_Ac'], ...
    'Gain', num2str(1 / p.Ac), 'Position', [895 42 955 78]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrador_h'], ...
    'Position', [995 45 1025 75]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxDQ'], ...
    'Inputs', '4', 'Position', [675 25 695 195]);
add_block('simulink/User-Defined Functions/Interpreted MATLAB Fcn', ...
    [mdl '/DinamicaCaudal'], ...
    'MATLABFcn', expr_dq(p), 'OutputDimensions', '1', ...
    'Position', [730 75 850 115]);
add_block('simulink/Signal Routing/Mux', [mdl '/MuxScope'], ...
    'Inputs', '4', 'Position', [1085 35 1105 145]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', [1140 30 1240 140]);

add_line(mdl, 'Referencia/1', 'Error/1', 'autorouting', 'on');
add_line(mdl, 'Error/1', 'ControladorIMC/1', 'autorouting', 'on');
add_line(mdl, 'ControladorIMC/1', 'Saturacion/1', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'ActuadorValvula/1', 'autorouting', 'on');
add_line(mdl, 'ActuadorValvula/1', 'MuxDQ/3', 'autorouting', 'on');
add_line(mdl, 'Perturbacion/1', 'MuxDQ/4', 'autorouting', 'on');
add_line(mdl, 'Integrador_h/1', 'Error/2', 'autorouting', 'on');
add_line(mdl, 'Integrador_h/1', 'MuxDQ/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_q/1', 'MuxDQ/2', 'autorouting', 'on');
add_line(mdl, 'MuxDQ/1', 'DinamicaCaudal/1', 'autorouting', 'on');
add_line(mdl, 'DinamicaCaudal/1', 'Integrador_q/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_q/1', '1_Ac/1', 'autorouting', 'on');
add_line(mdl, '1_Ac/1', 'Integrador_h/1', 'autorouting', 'on');
add_line(mdl, 'Referencia/1', 'MuxScope/1', 'autorouting', 'on');
add_line(mdl, 'Integrador_h/1', 'MuxScope/2', 'autorouting', 'on');
add_line(mdl, 'Saturacion/1', 'MuxScope/3', 'autorouting', 'on');
add_line(mdl, 'Perturbacion/1', 'MuxScope/4', 'autorouting', 'on');
add_line(mdl, 'MuxScope/1', 'Scope/1', 'autorouting', 'on');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
close_system(mdl);
end

function expr = expr_dq(p)
expr = sprintf(['hidraulica_no_lineal_esclusa(u,%.15g,%.15g,%.15g,', ...
    '%.15g,%.15g,%.15g,%.15g)'], ...
    p.Lh, p.Kv, p.Rh, p.Rt, p.Kh_nl, p.h0, p.h_min);
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

function d = disturbance_profile(t, p)
if t < p.t_dist1 || t > p.t_dist2
    d = 0;
else
    tau = t - p.t_dist1;
    d = p.d_amp * sin(2 * pi * p.d_freq * tau);
end
end
