import sympy as sp


def main():
    # Simbolos fisicos
    m, c, k = sp.symbols("m c k", positive=True, nonzero=True)
    K_f, K_e = sp.symbols("K_f K_e", positive=True, nonzero=True)
    L, R = sp.symbols("L R", positive=True, nonzero=True)
    s, lambda_ = sp.symbols("s lambda", positive=True, nonzero=True)

    # Variables auxiliares
    q, qd, qdd, u, i = sp.symbols("q qd qdd u i")

    print("\n=== 1. Planta nominal completa de tercer orden ===")
    G_full = sp.simplify(K_f / ((L * s + R) * (m * s**2 + c * s + k) + K_f * K_e * s))
    print("G_full(s) =")
    sp.pprint(G_full)

    den_full = sp.expand(sp.denom(G_full))
    print("\nDenominador expandido:")
    sp.pprint(den_full)

    print("\n=== 2. Reduccion fisica por dinamica electrica rapida ===")
    i_qs = sp.simplify((u - K_e * qd) / R)
    print("Si L*di/dt ~= 0, entonces i ~= ")
    sp.pprint(i_qs)

    eq_reduced = sp.Eq(
        m * qdd + (c + K_f * K_e / R) * qd + k * q,
        (K_f / R) * u,
    )
    print("\nEcuacion reducida fisica:")
    sp.pprint(eq_reduced)

    G_red_phys = sp.simplify((K_f / R) / (m * s**2 + (c + K_f * K_e / R) * s + k))
    print("\nG_red_fisica(s) =")
    sp.pprint(G_red_phys)

    print("\n=== 3. Modelo de sintonia adoptado en el proyecto ===")
    G_tune = sp.simplify(1 / (m * s**2 + c * s + k))
    print("G_r(s) =")
    sp.pprint(G_tune)

    print("\n=== 4. Sintonia IMC ===")
    T_d = sp.simplify(1 / (lambda_ * s + 1))
    C_imc = sp.simplify(T_d / (G_tune * (1 - T_d)))
    print("C_IMC(s) =")
    sp.pprint(C_imc)

    print("\nControl expandido:")
    sp.pprint(sp.expand(C_imc))

    print("\n=== 5. Parametros generales del PID ideal ===")
    Kc = sp.simplify(c / lambda_)
    tau_I = sp.simplify(c / k)
    tau_D = sp.simplify(m / c)
    print("Kc =")
    sp.pprint(Kc)
    print("tau_I =")
    sp.pprint(tau_I)
    print("tau_D =")
    sp.pprint(tau_D)

    print("\n=== 6. Sustitucion numerica del proyecto ===")
    vals = {m: 1, c: 5, k: 100, lambda_: sp.Rational(1, 10)}
    C_num = sp.simplify(C_imc.subs(vals))
    print("C_IMC numerico =")
    sp.pprint(C_num)

    print("\nForma expandida numerica:")
    sp.pprint(sp.expand(C_num))

    print("\nParametros numericos:")
    print("Kc =", sp.simplify(Kc.subs(vals)))
    print("tau_I =", sp.simplify(tau_I.subs(vals)))
    print("tau_D =", sp.simplify(tau_D.subs(vals)))

    print("\n=== 7. Conversion a forma paralela ===")
    Kp = sp.simplify(Kc.subs(vals))
    Ki = sp.simplify((Kc / tau_I).subs(vals))
    Kd = sp.simplify((Kc * tau_D).subs(vals))
    print("Kp =", Kp)
    print("Ki =", Ki)
    print("Kd =", Kd)

    print("\n=== 8. Verificacion de estabilidad del modelo reducido ===")
    omega_n = sp.simplify(sp.sqrt(k / m))
    zeta = sp.simplify(c / (2 * sp.sqrt(m * k)))
    print("omega_n =")
    sp.pprint(omega_n.subs(vals))
    print("zeta =")
    sp.pprint(zeta.subs(vals))


if __name__ == "__main__":
    main()
