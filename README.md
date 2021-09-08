# Materials for Hu, Small, et al. (2021)

This repository contains scripts and stimuli for the experiments described in the paper "The language network supports both lexical access and sentence generation during language production" (Hu, Small, et al. 2021). This `README` contains information about the design of the experiments, paths to the stimuli, and instructions for running the scripts.

Note that the instructions and trial timing information below reflect the *spoken* task in Experiments 1 & 2a. Please refer to the paper and code comments for information about the *typed* task (Experiment 2b). Experiment 3 is briefly discussed [here](#experiment-3); please refer to the paper for details.

# Table of contents
- [Experiment design](#experiment-design)
    - [Conditions](#conditions)
    - [Stimuli](#stimuli)
    - [Trials](#trials)
    - [Blocks](#blocks)
    - [Experimental lists](#experimental-lists)
- [Running the experiment](#running-the-experiment)
    - [Instructions and sample items](#instructions-and-sample-items)
    - [Experimental script](#experimental-script)
- [Data analysis](#data-analysis)

# Experiment design

## Conditions

The experiment has the following six conditions:

| Block | Condition | Description | Task |
| ----- | --------- | ----------- | ---- |
| A | SProd | Sentence production (critical) | Describe photo of event |
| B | VisEvSem | Event semantics | Perform semantic judgment task on SProd photos |
| C | WProd | Word list production | Name simplified version of objects in SProd photos |
| D | SComp | Sentence comprehension | Read sentence (silently) |
| E | WComp | Word list comprehension | Read list of words (silently) |
| F | NProd | Articulation / low-level production | Read nonwords out loud |

The conditions are designed to probe the following cognitive processes:

|    | SProd | VisEvSem | WProd | SComp | WComp | NProd |
| -- | :---: | :---: | :---: | :---: | :---: | :---: |
| Conceptual processing of objects and events (from visual input) |	**+** (events) | **+** (events)	| **+**	(objects) | — | — | — |
| Lexical access (in production) | **+** | — | **+** | — | — | — |
| Morpho-syntactic processing (ordering and inflecting words, etc.) |	**+**	| —	| — | — | — | — |
| Articulation | **+** | — | **+** | — | — | **+** |
| Lexical access (in comprehension) | — | — | —	| **+** | **+** | — |
| Combinatorial, syntactic/semantic processing (in comprehension)	| — | — | —	| **+** | — | — |

## Stimuli

The stimuli for the conditions can be found at the following paths.

| Condition | Materials | Path |
| :-------: | :-------: | :--: |
| SProd | 128 event images | [`SProd/stimuli`](SProd/stimuli) |
| VisEvSem | 128 event images | [`SProd/stimuli`](SProd/stimuli) |
| WProd | 128 object-set images | [`WProd/stimuli`](WProd/stimuli) |
| SComp | 128 (target) event sentences | [`keys/key_ev.csv`](keys/key_ev.csv) |
| WComp | 128 (target) object word lists | [`keys/key_ob.csv`](keys/key_ob.csv) |
| NProd | 256 nonwords | [`NProd/stimuli/nonwords.txt`](NProd/stimuli/nonwords.txt) |

The stimuli for the SProd, VisEvSem, and SComp conditions are **event-based**, and WProd and WComp are **object-based**. 
The files [`keys/key_ev.csv`](keys/key_ev.csv) and [`keys/key_ob.csv`](keys/key_ob.csv) contain information for the event- and object-based experimental materials, respectively, including image paths and their associated target sentences/word lists.

The file [`expt1-2/ProdLoc_materials.csv`](expt1-2/ProdLoc_materials.csv) contains the list of materials expected by the MATLAB experimental script (see [Experimental script](#experimental-script) for more details). If you wish to alter the materials in order to re-run the experiment, then you can regenerate this file by running 
`python generate_material_list.py`. Most users will not need to do this.

### Selecting stimuli

The code and raw data for selecting event photos, object photos, and nonwords are in the [`SProd`](SProd), [`WProd`](WProd), and [`NProd`](NProd) folders, respectively. Please refer to the `README` in the respective folders for more details on how stimuli were selected.

## Trials

Each trial (3s) is structured as follows:
1. 200ms initial fixation cross
2. 2800ms presentation of the image/words

The images are presented at the center of the screen. The sentences, word lists, and nonword lists are presented all at once (not word by word). We have 4 words/nonwords in the WComp and NProd conditions per trial.

## Blocks

There are **16 blocks per condition**. Each block has four trials, and each trial (across conditions) takes 3s. Instructions are presented for 2s at the beginning of each block, giving us **14s blocks**.

Each run consists of two blocks per condition, and are structured as follows:

```
Fix A B C D E F Fix F E D C B A Fix
```

where `Fix` are fixation blocks (each 12s long), and `A`-`F` are blocks for the six conditions (see first table in the [Conditions](#conditions) section).

There are 12 possible orders for the run:

```
-c 1  Fix A B C D E F Fix F E D C B A Fix
-c 2  Fix B C D E F A Fix A F E D C B Fix
-c 3  Fix C D E F A B Fix B A F E D C Fix
-c 4  Fix D E F A B C Fix C B A F E D Fix
-c 5  Fix E F A B C D Fix D C B A F E Fix
-c 6  Fix F A B C D E Fix E D C B A F Fix
-c 7  Fix F E D C B A Fix A B C D E F Fix
-c 8  Fix A F E D C B Fix B C D E F A Fix
-c 9  Fix B A F E D C Fix C D E F A B Fix
-c 10 Fix C B A F E D Fix D E F A B C Fix
-c 11 Fix D C B A F E Fix E F A B C D Fix
-c 12 Fix E D C B A F Fix F A B C D E Fix
```

Each run takes 204s (3.4 min), so the whole study takes **25-30 min**.

## Experimental lists

With 16 blocks per condition, we have 16 * 4 = 64 trials per condition. We have 128 **event images** and 128 corresponding **target sentences**. Similarly, we have 128 **object-set images** and 128 corresponding **target word lists**. (See the paper and [Stimuli](#stimuli) section for more details.)

We enumerate these materials 1-64 and 65-128 such that each split forms a diverse group of images/sentences (e.g., musical instruments are evenly split). Furthermore, the object-set images are numbered such that the 2-, 3-, and 4-object sets are evenly split across 1-64 and 65-128. Note that the numbers within the **event** materials correspond to each other, and same for the **object** materials, but not between events and objects.

The experimental lists are structured as follows.

| Condition | List 1 | List 2 |
| --------- | ------ | ------ |
| SProd | Event images 1-64 | Event images 65-128 |
| VisEvSem | Event images 1-64 | Event images 65-128 |
| WProd | Object-set images 1-64 | Object-set images 65-128 |
| SComp | Event sentences 65-128 | Event sentences 1-64 |
| WComp | Object word lists 65-128 | Object word lists 1-64 |
| NProd | Nonword lists 1-64 | Nonword lists 1-64 |

Note that each participant sees each event picture twice (once in the SProd condition, and once in the VisEvSem condition). The materials for the NProd condition are the same across the two lists.

# Running the experiment

## Instructions and sample items

### Before experiment
Please refer to [`expt1-2/instructions/instructions.docx`](expt1-2/instructions/instructions.docx) for the instructions shown to participants prior to the experiment (outside the scanner).

Participants were also shown sample items prior to the experiment. The sample items for the spoken (Experiments 1 & 2a) and typed (Experiment 2b) experiments are found at [`expt1-2/instructions/SampleItemsSpoken.pdf`](expt1-2/instructions/SampleItemsSpoken.pdf) and [`expt1-2/instructions/SampleItemsTyped.pdf`](expt1-2/instructions/SampleItemsTyped.pdf), respectively. The items themselves are identical, with modified instructions.

### During experiment
There is an instructions screen before each block (2s). These instructions also appear in small font in the lower right corner of the screen throughout the block.

| Condition | Instructions |
| --------- | ------------ |
| SProd | "Describe the event out loud" |
| VisEvSem	| "Indoors (=1) or outdoors (=2)?" |
| WProd | "Name the objects out loud" |
| SComp	| "Read the sentence silently" |
| WComp	| "Read the words silently" |
| NProd	| "Say the nonwords out loud" |

## Experimental script

The spoken (Experiment 1 & 2a) and typed (Experiment 2b) experiments are launched using MATLAB with the scripts [`expt1-2/ProdLoc.m`](expt1-2/ProdLoc.m) and [`expt1-2/ProdLoc_typing.m`](expt1-2/ProdLoc_typing.m), respectively. Both scripts take the following arguments:

| Argument | Description | Value |
| -------- | ----------- | ----- |
| `-s` | Subject ID | `string` |
| `-l` | Experimental list | `{1,2}` (or `0` for practice run)
| `-c` | Condition order (randomly selected for each participant/run) | `{1,2,...,12}` |
| `-r` | Run number (6 runs gives us 12 blocks per condition total) | `{1,2,...,6}` (or `'practice'`) |

Passing the flag `-s debug` makes the experiment run faster, and skips asking about overwriting the output files.

Please note that VisEvSem is referred to as **EVSEM** and NProd is referred to as **ARTIC** in the experimental scripts.

## Experiment 3

The materials and experimental script for Experiment 3 can be found at [`expt3`](expt3). The image files can be downloaded at [this Dropbox link](https://www.dropbox.com/sh/8zwtjj23fc5f03j/AAB9sX6eTn5GNUvFU8O4Vnsba?dl=0) (after downloading, rename/place the folder at `expt3/image_files`). Please note that the script `prodexp.py` requires [Vision Egg](http://visionegg.org/), which is no longer maintained.

# Data analysis

All estimated BOLD % signal change values for all three fMRI experiments are compiled at [`data/fMRI_all_indiv_production_data.csv`](data/fMRI_all_indiv_production_data.csv). Details on how these values were obtained are in the Methods of the paper. This dataset is used for generating figures and statistical analyses.

Typing output for Experiment 2 is available at [`data/all_prodloc_typing_output_20200804.csv`](data/all_prodloc_typing_output_20200804.csv), and annotated typing output for the sentence production condition is available at [`data/all_SPROD_annotated_data_20201210.csv`](data/all_SPROD_annotated_data_20201210.csv).

The [`analysis`](analysis) directory contains all code, results, and instructions on running the linear mixed effect models as decribed in the paper.

The [`figures`](figures) directory contains all code, figures, and instructions on generating the figures as seen in the paper.
