function dq = hidraulica_no_lineal_esclusa(u, Lh, Kv, Rh, Rt, Kh_nl, h0, h_min)
%HIDRAULICA_NO_LINEAL_ESCLUSA
% u = [h; q; xv; d]

h = u(1);
q = u(2);
xv = u(3);
d = u(4);

Habs = max(h0 + h, h_min);
head_nl = Kh_nl * (sqrt(Habs) - sqrt(h0));
loss_nl = Rh * q + Rt * q * abs(q);

dq = (Kv * xv - loss_nl - head_nl + d) / Lh;
end
