import pandas as pd

def minimize(df, n=192):
    '''
    Returns the n rows of df with lowest NN + NPN. One could also minimize
    e.g. NN + NON + NPN, but beware that penalizing NON leads to nonwords that
    begin with strange onsets like 'gw'.
    '''
    # assign score of NN + NPN to each nonword
    score = [df['NN'][i] + df['NPN'][i] for i in range(len(df.index))]

    # insert score column
    df = df.assign(score=score)

    # sort by score in ascending order
    df = df.sort_values(by=['score'])

    # keep only the n nonwords with lowest scores (first n rows)
    return df.head(n)

def filter(df, q=0.667):
    '''
    Returns the rows of df whose NN, NON, and NPN values are in the
    bottom proportion q of the entire distribution (default q=2/3).
    '''
    # store quantiles (Q such that P(N <= Q) = q) in dictionary
    quantiles = { N : df.quantile(q=q)[N] for N in ['NN', 'NON', 'NPN'] }

    # keep only the rows in bottom quantile of each distribution
    df = df.loc[(df['NN'] <= quantiles['NN']) &
                (df['NON'] <= quantiles['NON']) &
                (df['NPN'] <= quantiles['NPN'])]

    # put back in alphabetical order
    df = df.sort_values(by=['W'])
    return df

def sample(df, n=500):
    return df.sample(n)

if __name__ == '__main__':
    # read full file of nonwords
    df = pd.read_csv('ARC_nonwords.txt', delim_whitespace=True)
    print(df.head())

    # filter and sample nonwords
    filtered = filter(df)
    sampled = sample(filtered)
    sampled.to_csv('nonwords_filtered_sample.csv', index=False)
