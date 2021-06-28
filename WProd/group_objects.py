'''
    Name: group_objects.py
    Author: Jennifer Hu
    Purpose: Helper functions to generate groups of 2, 3, and 4 isolated
             object images, and save these object group images.
'''
import json
from numpy.random import randint
from os import listdir
from itertools import combinations
import matplotlib.pyplot as plt
from random import shuffle

def write_groups_sample(out_file):
    imgs = listdir('raw_object_images')
    num_per_group = [2, 3, 4]
    num_to_sample = [40, 80, 40]

    groups = {
        n : list(combinations(imgs, n)) for n in num_per_group
    }
    for i, n in enumerate(num_per_group):
        all_combos = groups[n]
        indices = randint(len(all_combos), size=num_to_sample[i])
        sample = [all_combos[j] for j in indices]
        groups[n] = sample

    with open(out_file, 'w') as f:
        json.dump(groups, f, indent=4)

def generate_group_images(group_file, n='all'):
    with open(group_file, 'r') as f:
        groups = json.load(f)
    if n == 'all':
        for n, n_groups in groups.items():
            for g in n_groups:
                write_group_images(g)
    else:
        n_groups = groups[str(n)]
        for g in n_groups:
            write_group_images(g)

def squeeze_margins():
    '''
    Removes (most) whitespace from margins of matplotlib figure.
    Credit goes to https://stackoverflow.com/a/27227718
    '''
    plt.gca().set_axis_off()
    plt.subplots_adjust(top=1, bottom=0, right=1, left=0,
                        hspace=0.2, wspace=0.2)
    plt.margins(0, 0)
    plt.gca().xaxis.set_major_locator(plt.NullLocator())
    plt.gca().yaxis.set_major_locator(plt.NullLocator())

def write_group_images(g):
    # explicitly shuffle the order of objects
    shuffle(g)
    n = len(g)
    if n == 4:
        nrows, ncols = 2, 2
    else:
        nrows, ncols = 1, n
    _, axarr = plt.subplots(nrows=nrows, ncols=ncols)
    for i, im_path in enumerate(g):
        if n == 4:
            ax = axarr[i / 2, i % 2]
        else:
            ax = axarr[i]
        image = plt.imread('raw_object_images/{}'.format(im_path))
        ax.imshow(image)
        ax.axis('off')

    g = [s.split('.')[0] for s in g]
    fname = 'stimuli/practice/PRACTICE_{}.jpg'.format('-'.join(g))
    squeeze_margins()
    plt.savefig(fname, dpi=300, bbox_inches='tight')
    plt.close('all')

if __name__ == '__main__':
    group_file = 'object_groups_practice.json'
    generate_group_images(group_file)
