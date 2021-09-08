'''
    Name: parse.py
    Author: Jennifer Hu
    Purpose: Parse the productions into subject NP and VP and save to file.
'''

import argparse
import pandas as pd
import spacy
from utils import *

##################################################################################
## HELPER FUNCTIONS
##################################################################################

def get_subject_np(doc):
    try:
        subject_np = next(np for np in doc.noun_chunks if is_subj_np(np))
        return subject_np, subject_np.root
    except StopIteration:
        return None, None

def get_vp(doc):
    try:
        main_v = next(token for token in doc if is_main_v(token))
        # TODO: fix this. Currently, this returns the rest of the sentence...
        return doc[main_v.i : main_v.right_edge.i + 1], main_v.head
    except StopIteration:
        return None, None

def get_cols(docs):
    nps_vps = [(get_subject_np(doc), get_vp(doc)) for doc in docs]
    [nps, vps] = unzip(nps_vps)
    [np_phrases, np_heads] = unzip(nps)
    [vp_phrases, vp_heads] = unzip(vps)

    cols_dict = {
        'subject_np' : np_phrases,
        'vp' : vp_phrases,
        'subject_np_head' : np_heads,
        'vp_head' : vp_heads
    }

    return cols_dict

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

        print('Parsing sentences...')
        docs = nlp.pipe(data_df.production, batch_size=50, n_threads=4)

        print('Getting NPs and VPs...')
        cols_dict = get_cols(docs)

        data_df = data_df.assign(**cols_dict)
        data_df.to_csv(out, index=False)
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
