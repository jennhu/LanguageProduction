# Plotting figures

This directory contains code to plot figures ([`code/production_paper_fROI_response_figures.py`](code/production_paper_fROI_response_figures.py)), images used in plotting ([`images`](/images)), and the rendered figures ([`figures`](figures)). The plotting code uses the data from [`../data`](../data).

Note that Figure 1 was created using tikz, so it must be compiled from the LaTeX source. The source files are in [`code/figure1`](code/figure1), and the rendered PDF and tiff files are in [`figures`](figures). Within the [`code/figure1`](code/figure1) directory, you can run `xelatex -shell-escape figure1.tex` to recompile the figure.

The script [`code/production_typing_response_figures.py`](code/production_typing_response_figures.py) plots the figures showing the well-formedness of the typing responses. It uses the data from [`../data/all_SPROD_annotated_data_20201210.csv`](../data/all_SPROD_annotated_data_20201210.csv) and [`../data/all_prodloc_typing_output_20200804.csv`](../data/all_prodloc_typing_output_20200804.csv).
