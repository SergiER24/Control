function Fnl = fuerza_no_lineal_suspension(u, k, c, k3, Fc, v_eps)
%FUERZA_NO_LINEAL_SUSPENSION Fuerza no lineal de la suspension.
% u = [x; v; z; zd]

x = u(1);
v = u(2);
z = u(3);
zd = u(4);

relx = x - z;
relv = v - zd;

Fnl = k*relx + c*relv + k3*relx^3 + Fc*tanh(relv / v_eps);
end
