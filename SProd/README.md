# Selecting event photographs

This directory contains the code and data for norming the event photograph stimuli, which are taken from the [Flickr30k](http://bryanplummer.com/Flickr30kEntities/) dataset. **The images used in our experiment (including example and practice items) can be found at [`stimuli`](stimuli).**

As outlined in the paper, we performed the following steps:

1. Manually selected 400 images clearly depicting everyday events
2. Ran norming study on Amazon.com's Mechanical Turk to identify stimuli that would elicit the most consistent linguistic descriptions (see [MTurk study](#mturk-study))
3. Selected best stimuli (see [Selecting stimuli](#selecting-stimuli))

## MTurk study

On each trial, participants viewed a single photograph and were given the instructions “Please provide a one-sentence description of what is happening in the photo.” They were able to type freely in a textbox below the image and could only proceed to the next trial after submitting a non-empty response. We recruited 30 participants for each of the 400 images, and each participant produced descriptions for 100 images.

The file [`norm_exp.html`](norm_exp.html) can be copied and pasted into the MTurk interface to create a HIT. We split the 400 images across 4 HITs, each consisting of 100 randomly sampled images. The 400 image files are stored on an MIT web server, and the file names are specified in the `img_path_dict` variable. If you want to re-run the norming study, make sure to set `var TEST_MODE = false` and update `HIT_NUMBER` to ensure the photos are read from the right directory.

### Processing and visualizing data

The raw MTurk data (with anonymized worker IDs) has been saved in the [`mturk_data/raw`](mturk_data/raw) folder, and the clean CSV and JSON files can be found at [`mturk_data/clean`](mturk_data/clean). To reproduce the pipeline, you can run
```bash
cd scripts
./process_and_viz.sh
```
to process the raw data and generate a summary HTML file for each HIT. The HTML file can be viewed in any browser as a local file, and is helpful for visualizing the stimuli and their associated responses. 

## Selecting stimuli

We selected stimuli that elicit the most consistent responses across participants. We used the [spaCy](https://spacy.io/) API to compute the subject NPs, VPs, subject NP heads, VP heads, mean number of tokens, and standard deviation of number of tokens for each stimulus. Please note that you will need spaCy, in addition to a basic scientific installation of Python, in order to repeat these analyses.

We first ran [`scripts/parse.py`](scripts/parse.py) to parse the raw productions into subject NP and VP, and then manually cleaned the parses. The resulting file is [`mturk_data/analysis/clean_parses.csv`](mturk_data/analysis/clean_parses.csv).

Next, we computed three metrics for each photograph: (1) the number of unique responses in each of the parsed categories, (2) the number of unique lemmas for the single-word parsed categories (subject NP head and VP head), and (3) the standard deviation of the number of tokens per production. We then obtained a "linguistic variability" score by summing these three values for each image. The file [`mturk_data/analysis/sorted_stimuli.csv`](mturk_data/analysis/sorted_stimuli.csv) is the result of running [`scripts/analyze.py`](scripts/analyze.py) to perform this process. 

Finally, we chose the 200 photographs with the lowest scores and hand-selected 128 from these 200 to maximally cover a range of objects and actions. The final result of this process is [`mturk_data/analysis/final_stimuli.csv`](mturk_data/analysis/final_stimuli.csv).
