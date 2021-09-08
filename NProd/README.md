# Selecting nonwords

This directory contains the code and data for selecting the nonword stimuli. 

As outlined in the paper, we performed the following steps:

1. Selected monomorphemic syllables involving orthographically existing onsets, bodies, and legal bigrams from [ARC Nonword Database](http://www.cogsci.mq.edu.au/research/resources/nwdb/nwdb.html), resulting in [`ARC_nonwords.txt`](ARC_nonwords.txt)
2. Filtered for low numbers of onset and phonological neighbors (see [Filtering nonwords](#filtering-nonwords))
3. Randomly distributed resulting 256 nonwords into 64 groups of 4, resulting in [`stimuli/nonwords.txt`](stimuli/nonwords.txt)

## Filtering nonwords

We used [`filter_nonwords.py`](filter_nonwords.py) to filter nonwords based on NN, NON, and NPN (see the [ARC webpage](http://www.cogsci.mq.edu.au/research/resources/nwdb/nwdb.html) for explanation of column headers) and randomly sample 500. We then manually selected 256 based on pronuncability, as indicated by the `Include` column in [`nonwords_filtered_sample_annot.csv`](nonwords_filtered_sample_annot.csv).