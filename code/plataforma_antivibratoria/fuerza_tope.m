function Fstop = fuerza_tope(u, x_lim, k_stop, c_stop)
%FUERZA_TOPE Fuerza de topes mecanicos.
% u = [x; v]

x = u(1);
v = u(2);

if x > x_lim
    Fstop = k_stop * (x - x_lim) + c_stop * max(v, 0);
elseif x < -x_lim
    Fstop = k_stop * (x + x_lim) + c_stop * min(v, 0);
else
    Fstop = 0;
end
end
