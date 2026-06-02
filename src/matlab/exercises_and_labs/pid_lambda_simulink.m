clear;
clc;

model = "modelo_pid_lambda_autogen";
lambda_values = [0.5 1 2 5];
t_stop = 200;
r_step = 1;

Gp_num = [-9 1];
Gp_den = conv([15 1], [3 1]);

build_simulink_model(model);

assignin("base", "Gp_num", Gp_num);
assignin("base", "Gp_den", Gp_den);
assignin("base", "t_stop", t_stop);
assignin("base", "r_step", r_step);

results(numel(lambda_values)) = struct( ...
    "lambda", [], ...
    "Kc", [], ...
    "tau_i", [], ...
    "tau_d", [], ...
    "tau_f", [], ...
    "y", [], ...
    "u", []);

for k = 1:numel(lambda_values)
    lambda = lambda_values(k);

    [Kc, tau_i, tau_d, tau_f] = pid_lambda_params(lambda);
    Gc_num = Kc * [tau_i * tau_d tau_i 1];
    Gc_den = conv([tau_i 0], [tau_f 1]);

    assignin("base", "lambda", lambda);
    assignin("base", "Kc", Kc);
    assignin("base", "tau_i", tau_i);
    assignin("base", "tau_d", tau_d);
    assignin("base", "tau_f", tau_f);
    assignin("base", "Gc_num", Gc_num);
    assignin("base", "Gc_den", Gc_den);

    simOut = sim(model, "StopTime", num2str(t_stop));

    results(k).lambda = lambda;
    results(k).Kc = Kc;
    results(k).tau_i = tau_i;
    results(k).tau_d = tau_d;
    results(k).tau_f = tau_f;
    results(k).y = simOut.get("y");
    results(k).u = simOut.get("u");
end

plot_results(results);
show_parameter_table(results);
if usejava("desktop")
    open_system(model);
else
    disp("Modelo guardado en el directorio actual.");
end

function build_simulink_model(model)
    model_file = fullfile(pwd, model + ".slx");

    if exist(model_file, "file")
        load_system(model);
        return;
    end

    new_system(model);

    add_block("simulink/Sources/Step", model + "/Referencia", ...
        "Position", [40 95 70 125], ...
        "Time", "0", ...
        "Before", "0", ...
        "After", "r_step");

    add_block("simulink/Math Operations/Sum", model + "/Suma", ...
        "Position", [115 94 135 126], ...
        "Inputs", "+-");

    add_block("simulink/Continuous/Transfer Fcn", model + "/Controlador", ...
        "Position", [180 86 320 134], ...
        "Numerator", "Gc_num", ...
        "Denominator", "Gc_den");

    add_block("simulink/Continuous/Transfer Fcn", model + "/Planta", ...
        "Position", [380 86 520 134], ...
        "Numerator", "Gp_num", ...
        "Denominator", "Gp_den");

    add_block("simulink/Sinks/To Workspace", model + "/Salida_y", ...
        "Position", [585 82 665 108], ...
        "VariableName", "y", ...
        "SaveFormat", "Timeseries");

    add_block("simulink/Sinks/To Workspace", model + "/Control_u", ...
        "Position", [380 150 460 176], ...
        "VariableName", "u", ...
        "SaveFormat", "Timeseries");

    add_block("simulink/Sinks/Scope", model + "/Scope", ...
        "Position", [585 120 615 150]);

    add_line(model, "Referencia/1", "Suma/1");
    add_line(model, "Suma/1", "Controlador/1");
    add_line(model, "Controlador/1", "Planta/1");
    add_line(model, "Planta/1", "Salida_y/1");
    add_line(model, "Planta/1", "Scope/1");
    add_line(model, "Planta/1", "Suma/2", "autorouting", "on");
    add_line(model, "Controlador/1", "Control_u/1", "autorouting", "on");

    set_param(model, "StopTime", "t_stop", "Solver", "ode45");
    save_system(model, model_file);
end

function [Kc, tau_i, tau_d, tau_f] = pid_lambda_params(lambda)
    Kc = 18 / (2 * lambda + 9);
    tau_i = 18;
    tau_d = 2.5;
    tau_f = lambda^2 / (2 * lambda + 9);
end

function plot_results(results)
    visible_state = "on";
    if ~usejava("desktop")
        visible_state = "off";
    end

    fig = figure("Color", "w", "Position", [100 100 950 700], ...
        "Visible", visible_state);
    tiledlayout(2, 1, "TileSpacing", "compact", "Padding", "compact");

    nexttile;
    hold on;
    for k = 1:numel(results)
        plot(results(k).y.Time, results(k).y.Data, "LineWidth", 1.6, ...
            "DisplayName", sprintf("\\lambda = %.2f", results(k).lambda));
    end
    grid on;
    xlabel("Tiempo (s)");
    ylabel("Salida y(t)");
    title("Respuesta en lazo cerrado para distintos valores de \lambda");
    legend("Location", "best");

    nexttile;
    hold on;
    for k = 1:numel(results)
        plot(results(k).u.Time, results(k).u.Data, "LineWidth", 1.6, ...
            "DisplayName", sprintf("\\lambda = %.2f", results(k).lambda));
    end
    grid on;
    xlabel("Tiempo (s)");
    ylabel("Accion de control u(t)");
    title("Esfuerzo de control");
    legend("Location", "best");

    if ~usejava("desktop")
        close(fig);
    end
end

function show_parameter_table(results)
    lambda = [results.lambda]';
    Kc = [results.Kc]';
    tau_i = [results.tau_i]';
    tau_d = [results.tau_d]';
    tau_f = [results.tau_f]';

    parameter_table = table(lambda, Kc, tau_i, tau_d, tau_f);
    disp(parameter_table);
end
