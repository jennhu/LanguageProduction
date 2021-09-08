# Constructing object stimuli

This directory contains the code and data for constructing the object photograph stimuli. **The images used in our experiment (including example and practice items) can be found at [`stimuli`](stimuli).**

As outlined in the paper, we performed the following steps:

1. Identified 2-4 words in each of the 128 sentence descriptions (see [`SProd/README.md`](../SProd/README.md) for more details) that referred to inanimate objects 
2. Selected images of each object (see [Selecting images](#selecting-images))
3. Generated object groups (see [Grouping objects](#grouping-objects))

## Selecting images

Object images were selected from the THINGS database ([Hebart et al., 2019](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0223792)) or [Pixabay](https://pixabay.com/), an online repository of stock photographs. In those images, each object is presented on a neutral but naturalistic background, which isolates the object from possibly associated events or concepts. 

## Grouping objects

We used [`group_objects.py`](group_objects.py) to generate all possible groups of 2, 3, and 4 object images, and then took a random sample of 40 2-object, 80 3-object, and 40 4-object groups, as there was an average of 3 content words in our target sentence productions. We then manually selected the final 128 object groups by discarding groups with semantically related objects, and ensuring that each object appeared 1-3 times. The associated object words (grouped in the same way) were presented in the WComp condition. 

In order to re-run [`group_objects.py`](group_objects.py), you will need the folder of raw individual object images. We have not staged this folder for reasons of space, and because they can be found in the THINGS database. Please contact the authors of this repository if you would like access to the individual images.