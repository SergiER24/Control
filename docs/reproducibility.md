# Reproducibility Guide

## Portable Python Workflow

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python src/python/control_portfolio.py
python -m unittest discover -s tests -v
```

Generated artifacts:

- `figures/bode_response.png`
- `figures/root_locus.png`
- `figures/open_loop_comparison.png`
- `figures/closed_loop_step.png`
- `figures/closed_loop_tracking.png`
- `results/control_summary.json`
- `results/closed_loop_response.csv`

## MATLAB and Simulink Workflow

Run the original implementation from MATLAB:

```matlab
cd src/matlab/anti_vibration_platform
run_all
```

The MATLAB workflow generates additional `.slx`, `.mat`, `.csv`, and figure
artifacts. MATLAB and Simulink are not required for the portable Python
analysis.
