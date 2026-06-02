"""Generate reproducible control-analysis artifacts for the featured platform."""

from __future__ import annotations

import csv
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal
from scipy.integrate import solve_ivp


ROOT = Path(__file__).resolve().parents[2]
FIGURES = ROOT / "figures"
RESULTS = ROOT / "results"

MASS_KG = 12.0
STIFFNESS_N_M = 1800.0
DAMPING_N_S_M = 95.0
ACTUATOR_GAIN_N_V = 220.0
ACTUATOR_TIME_CONSTANT_S = 0.04
ACTUATOR_LIMIT_V = 1.5
IMC_LAMBDA_S = 0.10

CUBIC_STIFFNESS_N_M3 = 6.0e4
COULOMB_FRICTION_N = 1.0
VELOCITY_SMOOTHING_M_S = 1.0e-3
POSITION_LIMIT_M = 0.015
STOP_STIFFNESS_N_M = 8.0e4
STOP_DAMPING_N_S_M = 600.0


def plant_coefficients() -> tuple[np.ndarray, np.ndarray]:
    """Return numerator and denominator coefficients of the nominal plant."""
    numerator = np.array([ACTUATOR_GAIN_N_V], dtype=float)
    denominator = np.convolve(
        [ACTUATOR_TIME_CONSTANT_S, 1.0],
        [MASS_KG, DAMPING_N_S_M, STIFFNESS_N_M],
    )
    return numerator, denominator


def controller_coefficients() -> tuple[np.ndarray, np.ndarray]:
    """Return coefficients of the equivalent IMC feedback controller."""
    numerator = np.convolve(
        [ACTUATOR_TIME_CONSTANT_S, 1.0],
        [MASS_KG, DAMPING_N_S_M, STIFFNESS_N_M],
    )
    denominator = (
        ACTUATOR_GAIN_N_V
        * IMC_LAMBDA_S
        * np.convolve(
            [1.0, 0.0],
            [IMC_LAMBDA_S**2, 3.0 * IMC_LAMBDA_S, 3.0],
        )
    )
    return numerator, denominator


def nominal_closed_loop_coefficients() -> tuple[np.ndarray, np.ndarray]:
    """Return the nominal unity-feedback transfer function coefficients."""
    numerator = np.array([1.0], dtype=float)
    denominator = np.array(
        [
            IMC_LAMBDA_S**3,
            3.0 * IMC_LAMBDA_S**2,
            3.0 * IMC_LAMBDA_S,
            1.0,
        ],
        dtype=float,
    )
    return numerator, denominator


def state_space_matrices() -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Return a controllable canonical state-space realization of the plant."""
    numerator, denominator = plant_coefficients()
    return signal.tf2ss(numerator, denominator)


def _hard_stop_force(position_m: float, velocity_m_s: float) -> float:
    if position_m > POSITION_LIMIT_M:
        return STOP_STIFFNESS_N_M * (position_m - POSITION_LIMIT_M) + STOP_DAMPING_N_S_M * max(velocity_m_s, 0.0)
    if position_m < -POSITION_LIMIT_M:
        return STOP_STIFFNESS_N_M * (position_m + POSITION_LIMIT_M) + STOP_DAMPING_N_S_M * min(velocity_m_s, 0.0)
    return 0.0


def _platform_force(relative_position_m: float, relative_velocity_m_s: float, nonlinear: bool) -> float:
    force = STIFFNESS_N_M * relative_position_m + DAMPING_N_S_M * relative_velocity_m_s
    if nonlinear:
        force += CUBIC_STIFFNESS_N_M3 * relative_position_m**3
        force += COULOMB_FRICTION_N * np.tanh(relative_velocity_m_s / VELOCITY_SMOOTHING_M_S)
    return float(force)


def simulate_open_loop(nonlinear: bool, voltage_v: float = 0.05) -> tuple[np.ndarray, np.ndarray]:
    """Simulate the platform response to a constant actuator-voltage command."""

    def rhs(_: float, state: np.ndarray) -> np.ndarray:
        position_m, velocity_m_s, actuator_force_n = state
        voltage = float(np.clip(voltage_v, -ACTUATOR_LIMIT_V, ACTUATOR_LIMIT_V))
        suspension_force = _platform_force(position_m, velocity_m_s, nonlinear)
        stop_force = _hard_stop_force(position_m, velocity_m_s) if nonlinear else 0.0
        return np.array(
            [
                velocity_m_s,
                (actuator_force_n - suspension_force - stop_force) / MASS_KG,
                (-actuator_force_n + ACTUATOR_GAIN_N_V * voltage) / ACTUATOR_TIME_CONSTANT_S,
            ]
        )

    time_s = np.linspace(0.0, 4.0, 4001)
    solution = solve_ivp(rhs, (time_s[0], time_s[-1]), np.zeros(3), t_eval=time_s, rtol=1e-8, atol=1e-10)
    return time_s, solution.y[0]


def _reference_position_m(time_s: float) -> float:
    if time_s < 1.0:
        return 0.0
    if time_s < 9.0:
        return 0.0040
    if time_s < 16.0:
        return -0.0025
    return 0.0030


def _base_motion(time_s: float) -> tuple[float, float]:
    if time_s < 6.0:
        return 0.0, 0.0
    if time_s < 14.0:
        omega = 2.0 * np.pi * 1.2
        tau = time_s - 6.0
        return 1.5e-3 * np.sin(omega * tau), 1.5e-3 * omega * np.cos(omega * tau)
    tau = time_s - 14.0
    omega_1 = 2.0 * np.pi * 0.8
    omega_2 = 2.0 * np.pi * 2.4
    position = 1.0e-3 * np.sin(omega_1 * tau) + 0.6e-3 * np.sin(omega_2 * tau)
    velocity = 1.0e-3 * omega_1 * np.cos(omega_1 * tau) + 0.6e-3 * omega_2 * np.cos(omega_2 * tau)
    return float(position), float(velocity)


def simulate_nonlinear_closed_loop() -> dict[str, np.ndarray]:
    """Simulate nonlinear feedback tracking and base-disturbance rejection."""
    controller_num, controller_den = controller_coefficients()
    a_ctrl, b_ctrl, c_ctrl, d_ctrl = signal.tf2ss(controller_num, controller_den)
    n_controller_states = a_ctrl.shape[0]

    def rhs(time_s: float, state: np.ndarray) -> np.ndarray:
        position_m, velocity_m_s, actuator_force_n = state[:3]
        controller_state = state[3:]
        reference_m = _reference_position_m(time_s)
        base_position_m, base_velocity_m_s = _base_motion(time_s)
        error_m = reference_m - position_m
        voltage = float(np.clip((c_ctrl @ controller_state + d_ctrl * error_m).item(), -ACTUATOR_LIMIT_V, ACTUATOR_LIMIT_V))
        relative_position_m = position_m - base_position_m
        relative_velocity_m_s = velocity_m_s - base_velocity_m_s
        suspension_force = _platform_force(relative_position_m, relative_velocity_m_s, nonlinear=True)
        stop_force = _hard_stop_force(position_m, velocity_m_s)
        controller_derivative = a_ctrl @ controller_state + b_ctrl[:, 0] * error_m
        return np.concatenate(
            (
                [
                    velocity_m_s,
                    (actuator_force_n - suspension_force - stop_force) / MASS_KG,
                    (-actuator_force_n + ACTUATOR_GAIN_N_V * voltage) / ACTUATOR_TIME_CONSTANT_S,
                ],
                controller_derivative,
            )
        )

    time_s = np.linspace(0.0, 24.0, 2401)
    initial_state = np.zeros(3 + n_controller_states)
    solution = solve_ivp(rhs, (time_s[0], time_s[-1]), initial_state, t_eval=time_s, rtol=1e-7, atol=1e-9)

    reference_m = np.array([_reference_position_m(value) for value in time_s])
    base_position_m = np.array([_base_motion(value)[0] for value in time_s])
    voltage_v = np.empty_like(time_s)
    for index, state in enumerate(solution.y.T):
        error_m = reference_m[index] - state[0]
        voltage_v[index] = np.clip((c_ctrl @ state[3:] + d_ctrl * error_m).item(), -ACTUATOR_LIMIT_V, ACTUATOR_LIMIT_V)

    return {
        "time_s": time_s,
        "reference_m": reference_m,
        "position_m": solution.y[0],
        "base_position_m": base_position_m,
        "voltage_v": voltage_v,
    }


def _configure_plotting() -> None:
    plt.style.use("seaborn-v0_8-whitegrid")
    plt.rcParams.update({"figure.dpi": 120, "savefig.dpi": 220, "axes.spines.top": False, "axes.spines.right": False})


def _save_bode_plot() -> None:
    plant_num, plant_den = plant_coefficients()
    controller_num, controller_den = controller_coefficients()
    frequencies = np.logspace(-1, 3, 700)
    _, plant_magnitude, plant_phase = signal.bode(signal.TransferFunction(plant_num, plant_den), frequencies)
    _, loop_magnitude, loop_phase = signal.bode(
        signal.TransferFunction(np.convolve(plant_num, controller_num), np.convolve(plant_den, controller_den)),
        frequencies,
    )
    figure, axes = plt.subplots(2, 1, figsize=(8.2, 6.4), sharex=True)
    axes[0].semilogx(frequencies, plant_magnitude, label="Plant")
    axes[0].semilogx(frequencies, loop_magnitude, label="Compensated loop")
    axes[0].set_ylabel("Magnitude [dB]")
    axes[0].legend()
    axes[1].semilogx(frequencies, plant_phase, label="Plant")
    axes[1].semilogx(frequencies, loop_phase, label="Compensated loop")
    axes[1].set_ylabel("Phase [deg]")
    axes[1].set_xlabel("Angular frequency [rad/s]")
    figure.suptitle("Active anti-vibration platform frequency response")
    figure.tight_layout()
    figure.savefig(FIGURES / "bode_response.png")
    plt.close(figure)


def _save_root_locus_plot() -> None:
    plant_num, plant_den = plant_coefficients()
    padded_num = np.pad(plant_num, (len(plant_den) - len(plant_num), 0))
    gains = np.logspace(-2, 5, 700)
    branches = np.array([np.roots(plant_den + gain * padded_num) for gain in gains])
    figure, axis = plt.subplots(figsize=(7.4, 5.4))
    for branch in range(branches.shape[1]):
        axis.plot(branches[:, branch].real, branches[:, branch].imag, linewidth=1.4)
    poles = np.roots(plant_den)
    axis.scatter(poles.real, poles.imag, marker="x", s=80, color="black", label="Open-loop poles")
    axis.axvline(0.0, color="black", linewidth=0.8)
    axis.set_xlabel("Real axis")
    axis.set_ylabel("Imaginary axis")
    axis.set_title("Root locus of the nominal platform plant")
    axis.legend()
    figure.tight_layout()
    figure.savefig(FIGURES / "root_locus.png")
    plt.close(figure)


def _save_time_domain_plots(closed_loop: dict[str, np.ndarray]) -> None:
    time_s, linear_open = simulate_open_loop(nonlinear=False, voltage_v=1.0)
    nonlinear_time_s, nonlinear_open = simulate_open_loop(nonlinear=True, voltage_v=1.0)
    figure, axis = plt.subplots(figsize=(7.6, 4.6))
    axis.plot(time_s, 1e3 * linear_open, label="Linear model")
    axis.plot(nonlinear_time_s, 1e3 * nonlinear_open, "--", label="Nonlinear model")
    axis.set_xlabel("Time [s]")
    axis.set_ylabel("Platform displacement [mm]")
    axis.set_title("Open-loop step response")
    axis.legend()
    figure.tight_layout()
    figure.savefig(FIGURES / "open_loop_comparison.png")
    plt.close(figure)

    step_time_s = np.linspace(0.0, 1.2, 800)
    normalized_time = step_time_s / IMC_LAMBDA_S
    closed_step = 1.0 - np.exp(-normalized_time) * (1.0 + normalized_time + 0.5 * normalized_time**2)
    figure, axis = plt.subplots(figsize=(7.6, 4.6))
    axis.plot(step_time_s, closed_step, linewidth=2.0)
    axis.axhline(1.0, color="black", linestyle="--", linewidth=1.0, label="Reference")
    axis.set_xlabel("Time [s]")
    axis.set_ylabel("Normalized displacement")
    axis.set_title("Nominal closed-loop reference tracking")
    axis.legend()
    figure.tight_layout()
    figure.savefig(FIGURES / "closed_loop_step.png")
    plt.close(figure)

    figure, axis = plt.subplots(figsize=(8.4, 4.9))
    axis.plot(closed_loop["time_s"], 1e3 * closed_loop["reference_m"], "k--", label="Reference")
    axis.plot(closed_loop["time_s"], 1e3 * closed_loop["position_m"], label="Nonlinear platform")
    axis.plot(closed_loop["time_s"], 1e3 * closed_loop["base_position_m"], ":", label="Base disturbance")
    axis.set_xlabel("Time [s]")
    axis.set_ylabel("Displacement [mm]")
    axis.set_title("Nonlinear closed-loop tracking and disturbance rejection")
    axis.legend()
    figure.tight_layout()
    figure.savefig(FIGURES / "closed_loop_tracking.png")
    plt.close(figure)


def write_artifacts() -> dict[str, object]:
    """Generate plots, response data, and a machine-readable summary."""
    FIGURES.mkdir(exist_ok=True)
    RESULTS.mkdir(exist_ok=True)
    _configure_plotting()
    closed_loop = simulate_nonlinear_closed_loop()
    _save_bode_plot()
    _save_root_locus_plot()
    _save_time_domain_plots(closed_loop)

    disturbance_mask = (closed_loop["time_s"] >= 6.0) & (closed_loop["time_s"] <= 14.0)
    disturbance_error = closed_loop["reference_m"][disturbance_mask] - closed_loop["position_m"][disturbance_mask]
    plant_num, plant_den = plant_coefficients()
    poles = np.roots(plant_den)
    a_matrix, b_matrix, c_matrix, d_matrix = state_space_matrices()
    summary = {
        "project": "Active Anti-Vibration Platform",
        "nominal_parameters": {
            "mass_kg": MASS_KG,
            "stiffness_n_m": STIFFNESS_N_M,
            "damping_n_s_m": DAMPING_N_S_M,
            "actuator_gain_n_v": ACTUATOR_GAIN_N_V,
            "actuator_time_constant_s": ACTUATOR_TIME_CONSTANT_S,
            "imc_lambda_s": IMC_LAMBDA_S,
        },
        "analysis": {
            "plant_numerator": plant_num.tolist(),
            "plant_denominator": plant_den.tolist(),
            "plant_poles": [{"real": float(pole.real), "imag": float(pole.imag)} for pole in poles],
            "open_loop_stable": bool(np.all(poles.real < 0.0)),
            "natural_frequency_rad_s": float(np.sqrt(STIFFNESS_N_M / MASS_KG)),
            "damping_ratio": float(DAMPING_N_S_M / (2.0 * np.sqrt(MASS_KG * STIFFNESS_N_M))),
            "disturbance_window_rms_error_mm": float(1e3 * np.sqrt(np.mean(disturbance_error**2))),
            "maximum_control_voltage_v": float(np.max(np.abs(closed_loop["voltage_v"]))),
        },
        "state_space": {
            "A": a_matrix.tolist(),
            "B": b_matrix.tolist(),
            "C": c_matrix.tolist(),
            "D": d_matrix.tolist(),
        },
    }
    (RESULTS / "control_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    with (RESULTS / "closed_loop_response.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["time_s", "reference_m", "position_m", "base_position_m", "voltage_v"])
        writer.writerows(zip(*(closed_loop[key] for key in ["time_s", "reference_m", "position_m", "base_position_m", "voltage_v"])))
    return summary


def main() -> int:
    summary = write_artifacts()
    print(json.dumps(summary["analysis"], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
