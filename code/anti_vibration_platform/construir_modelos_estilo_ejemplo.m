function construir_modelos_estilo_ejemplo()
%CONSTRUIR_MODELOS_ESTILO_EJEMPLO
% Deja la carpeta con una estructura de nombres similar al ejemplo entregado.

outdir = fileparts(mfilename('fullpath'));

% Primero se generan los modelos base de Simulink.
generar_modelos_simulink();

% Luego se renombran/copían con nombres similares al ejemplo.
copy_if_exists(fullfile(outdir, 'modelo_realista_no_lineal_abierto.slx'), ...
    fullfile(outdir, 'comparacion_modelos.slx'));
copy_if_exists(fullfile(outdir, 'lazo_cerrado_lineal_imc.slx'), ...
    fullfile(outdir, 'comparacion_controladores.slx'));
copy_if_exists(fullfile(outdir, 'lazo_cerrado_no_lineal_imc.slx'), ...
    fullfile(outdir, 'sistema_real.slx'));

fprintf('\nModelos con nombres estilo ejemplo actualizados.\n');
fprintf('comparacion_modelos.slx\n');
fprintf('comparacion_controladores.slx\n');
fprintf('sistema_real.slx\n');
fprintf(['Si quieres una version fisica montada 100%% en Simscape, sigue la ', ...
    'guia en guia_armado_simscape.md.\n']);
end

function copy_if_exists(src, dst)
if exist(src, 'file')
    copyfile(src, dst);
end
end
