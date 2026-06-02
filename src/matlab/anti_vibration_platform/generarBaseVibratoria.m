function [z, zd, t] = generarBaseVibratoria(t, p)
%GENERARBASEVIBRATORIA Genera el desplazamiento y la velocidad de la base.
%
% Uso:
%   [z, zd, t] = generarBaseVibratoria(t, p)
%
% Entrada:
%   t : vector de tiempo
%   p : estructura de parametros
%
% Salida:
%   z  : desplazamiento de base [m]
%   zd : velocidad de base [m/s]

t = t(:);
z = zeros(size(t));
zd = zeros(size(t));

for k = 1:numel(t)
    tk = t(k);

    if tk < p.t_dist1
        z(k) = 0;
        zd(k) = 0;
    elseif tk < p.t_dist2
        w = 2*pi*1.2;
        tau = tk - p.t_dist1;
        z(k) = 1.5e-3 * sin(w*tau);
        zd(k) = 1.5e-3 * w * cos(w*tau);
    else
        tau = tk - p.t_dist2;
        w1 = 2*pi*0.8;
        w2 = 2*pi*2.4;
        z(k) = 1.0e-3 * sin(w1*tau) + 0.6e-3 * sin(w2*tau);
        zd(k) = 1.0e-3 * w1 * cos(w1*tau) + 0.6e-3 * w2 * cos(w2*tau);
    end
end
end
