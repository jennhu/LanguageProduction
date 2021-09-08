'''
    Name: analyze.py
    Author: Jennifer Hu
    Purpose: Compute and minimize entropy for the elicited productions.
'''

import argparse
from utils import *
import spacy
import pandas as pd
from numpy import mean, std

##################################################################################
## HELPER FUNCTIONS
##################################################################################

def get_token_stats(df, stim, nlp):
    '''
    Returns mean and standard deviation of distribution of number of tokens
    across responses for a particular stimulus.
    '''
    # get productions associated with particular stimulus
    productions = df.loc[df.img == stim].production
    # parse and clean
    docs = nlp.pipe(productions, batch_size=50, n_threads=4)
    texts = [[token.text for token in doc] for doc in docs]
    texts = [clean(token_list) for token_list in texts]
    # calculate number of tokens
    num_tokens = [len(token_list) for token_list in texts]
    return mean(num_tokens), std(num_tokens)

def mean_std_lengths(df, nlp):
    '''
    Returns mean and standard deviation of production lengths (in tokens)
    for each image stimulus.
    '''
    # get list of stimuli
    stims = df.img.unique()
    # get means and stds
    stats = [get_token_stats(df, stim, nlp) for stim in stims]
    means, stds = unzip(stats)
    return means, stds

def num_unique(df, stim, val, lemma=False, nlp=None):
    '''
    Returns number of unique responses or lemmas for a given stimulus and
    column name (val).
    '''
    # get rows corresponding to stim and column corresponding to val
    texts = df.loc[df.img == stim, val].values
    # clean texts (remove punctuation, capitalization)
    texts = clean(texts)

    if lemma:
        # count number of unique lemmas
        docs = nlp.pipe(texts, batch_size=50, n_threads=4)
        lemmas = [token.lemma_ for doc in docs for token in doc]
        return num_unique_elts(lemmas)
    else:
        # count number of unique responses
        return num_unique_elts(texts)

def count_unique(df, nlp):
    '''
    Returns dict with number of unique responses for the values in df,
    as well as the number of unique lemmas for the single-word columns
    (vp_head and subject_np_head).
    '''
    # get list of stimuli
    stims = df.img.unique()
    # list of column names to calculate over
    vals = [c for c in list(df) if c not in ['img', 'production', 'hit']]
    # get number of unique responses
    data = { val : [num_unique(df, stim, val) for stim in stims]
                   for val in vals }
    # get number of unique lemmas for vp and np heads
    data['vp_head_lemmas'] = [
        num_unique(df, stim, 'vp_head', lemma=True, nlp=nlp) for stim in stims
    ]
    data['subject_np_head_lemmas'] = [
        num_unique(df, stim, 'subject_np_head', lemma=True, nlp=nlp)
        for stim in stims
    ]
    data['img'] = stims
    return data

def minimize(df, nlp):
    unique = count_unique(df, nlp)
    _, stds = mean_std_lengths(df, nlp)
    unique['std_num_tokens'] = stds
    # calculate and sort by sum of entire row
    df = pd.DataFrame(unique)
    df['sum'] = df.sum(numeric_only=True, axis=1)
    sorted_df = df.sort_values(by=['sum'])
    return sorted_df

##################################################################################
## MAIN
##################################################################################

def main(data, out, overwrite):
    if data == out and not overwrite:
        raise NameError('Pass the -O flag to allow overwriting.')

    else:
        nlp = spacy.load('en')

        print('Reading data from {}...'.format(data))
        data_df = pd.read_csv(data)

        print('Minimizing entropy...')
        sorted = minimize(data_df, nlp)

        sorted.to_csv(out, index=False)
        print('Saved to {}'.format(out))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str,
                        help='path to data file (expects .csv)')
    parser.add_argument('--out', type=str,
                        help='path to write output file')
    parser.add_argument('--overwrite', '-O', action='store_true', default=False,
                        help='flag to overwrite data file if data==out')
    args = parser.parse_args()

    main(**vars(args))
