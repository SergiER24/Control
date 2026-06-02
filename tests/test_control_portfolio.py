"""Regression tests for the portable control analysis."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src" / "python"))

import control_portfolio as model


class ControlPortfolioTests(unittest.TestCase):
    def test_nominal_plant_is_stable(self) -> None:
        _, denominator = model.plant_coefficients()
        self.assertTrue(np.all(np.roots(denominator).real < 0.0))

    def test_state_space_dimensions_match_third_order_plant(self) -> None:
        a_matrix, b_matrix, c_matrix, d_matrix = model.state_space_matrices()
        self.assertEqual(a_matrix.shape, (3, 3))
        self.assertEqual(b_matrix.shape, (3, 1))
        self.assertEqual(c_matrix.shape, (1, 3))
        self.assertEqual(d_matrix.shape, (1, 1))

    def test_nonlinear_simulation_remains_finite(self) -> None:
        response = model.simulate_nonlinear_closed_loop()
        self.assertTrue(np.isfinite(response["position_m"]).all())
        self.assertLessEqual(np.max(np.abs(response["voltage_v"])), model.ACTUATOR_LIMIT_V + 1e-12)


if __name__ == "__main__":
    unittest.main()
