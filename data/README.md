# Data preparation

This directory contains the second level data from the three fMRI experiments and code that compiles all the data for analysis and plotting.

The script [`create_dataset/create_dataset.R`](create_dataset/create_dataset.R) compiles all of the fMRI effect estimate results from [`create_data_set/toolbox_output`](create_dataset/toolbox_output) into one `.csv` file: [`fMRI_all_indiv_production_data.csv`](fMRI_all_indiv_production_data.csv). This contains all of the estimated BOLD % signal increase values for every condition in every fROI (language, MD, and low-level production) for each subject in each of the three experiments. **This dataset is used for plotting and all analyses.** The [`create_dataset/create_dataset.R`](create_dataset/create_dataset.R) script also outputs [`fMRI_all_production_data_summaryMeanEffectSize.csv`](fMRI_all_production_data_summaryMeanEffectSize.csv), which contains the estimated BOLD % signal change values averaged over the subjects for each of the three fMRI experiments.

This directory also contains typing output for Experiment 3 ([`all_prodloc_typing_output_20200804.csv`](all_prodloc_typing_output_20200804.csv)) and annotated sentence production typing output ([`all_SPROD_annotated_data_20201210.csv`](all_SPROD_annotated_data_20201210.csv)).

Demographic information (age, gender, handedness) for all subjects is provided in [`demographics.csv`](demographics.csv).
