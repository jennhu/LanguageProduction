'''
    Name: process_data.py
    Author: Jennifer Hu
    Purpose: Process MTurk responses from norming study and save cleaned data.
'''

import pandas as pd
import argparse
import json
from utils import flatten

NUM_TRIALS = 100

##################################################################################
## HELPER FUNCTIONS
##################################################################################

def get_resp(row, trial_num):
    return row['Answer.trial{}_resp'.format(trial_num)]

def get_stim(row, trial_num):
    return row['Answer.trial{}_stim'.format(trial_num)]

def df_from_batch(batch):
    '''
    Returns DataFrame from Batch file, keeping only the columns with responses.
    '''
    df = pd.read_csv(batch)
    col_names = df.columns.values.tolist()
    df = df.drop([c for c in col_names if 'Answer.' not in c], axis=1)
    return df

def get_all_stims(df):
    '''
    Returns list of all stimuli paths by reading the first row of df.
    '''
    row = df.iloc[[2]]
    stims = [get_stim(row, trial_num).values[0]
             for trial_num in range(1, NUM_TRIALS + 1)]
    return stims

def get_responses(df, stim):
    '''
    Returns list of responses for a given stimulus.
    '''
    trial_nums = range(1, NUM_TRIALS + 1)
    responses = [get_resp(row, trial_num) for trial_num in trial_nums
                                          for index, row in df.iterrows()
                                          if get_stim(row, trial_num) == stim]
    # only keep responses that are not NaN
    responses = [r for r in responses if r == r]
    return responses

##################################################################################
## WRITE DATA
##################################################################################

def write_processed_data(df, hit, out):
    '''
    Makes dict of <stimulus : response list> pairs and writes in two formats:
    (1) JSON file (<out>/hit<hit>.json)
    (2) CSV file (<out>/hit<hit>.csv)
    '''
    stims = get_all_stims(df)
    resp_dict = { stim : get_responses(df, stim) for stim in stims }

    out_file = '{}/hit{}'.format(out, hit)

    # write JSON file
    with open('{}.json'.format(out_file), 'w') as f:
        json.dump(resp_dict, f, indent=4, allow_nan=False)

    # write CSV file
    data = [[(resp, stim) for resp in responses]
            for stim, responses in resp_dict.items()]
    data = flatten(data)
    out_df = pd.DataFrame.from_records(data, columns=['production','img'])
    out_df.to_csv('{}.csv'.format(out_file), index=False)

##################################################################################
## MAIN
##################################################################################

def main(batch, hit, out):
    # read responses from Batch data into df
    print('Reading data from {}...'.format(batch))
    batch_df = df_from_batch(batch)

    # write processed data to specified folder
    write_processed_data(batch_df, hit, out)
    print('Wrote responses to {}'.format(out))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--batch', type=str,
                        help='path to Batch results file (expects .csv)')
    parser.add_argument('--hit', type=int, choices=[1,2,3,4],
                        help='HIT number (1-4)')
    parser.add_argument('--out', type=str,
                        help='path to folder for output files')
    args = parser.parse_args()

    main(**vars(args))
