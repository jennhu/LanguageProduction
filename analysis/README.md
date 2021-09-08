# Data analysis

This directory contains the code for running statistical analyses and generating table outputs.


## Statistical tests

The scripts [`lmers.R`](lmers.R) and [`lmers_convergence_tracking.R`](lmers_convergence_tracking.R) run the same linear mixed effect models, but [`lmers_convergence_tracking.R`](lmers_convergence_tracking.R) generates a `convergence_tracking_outputs/*.csv` output that shows any model that fails to converge. For any model that failed to converge, we used [`testing_convergence_allFit.R`](testing_convergence_allFit.R) to test the model with multiple optimizer functions and verify that they all generate the same values.

## Generating tables

The script [`format_table.py`](format_table.py) reads the `results/*.csv` files and outputs LaTeX tables with cell highlighting based on statistical significance levels. Each table is saved in its own `.tex` file in the [`tables`](tables) folder, and can be compiled independently to form a standalone PDF document.