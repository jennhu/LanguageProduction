'''
    Name: utils.py
    Author: Jennifer Hu
    Purpose: Basic helper functions, mostly list and string processing.
'''

##################################################################################
## LISTS
##################################################################################

def num_unique_elts(l):
    return len(set(l))

def unzip(tup_list):
    return list(zip(*tup_list))

def flatten(l):
    flat_list = [item for sublist in l for item in sublist]
    return flat_list

##################################################################################
## STRINGS & TOKENS
##################################################################################

def is_punct(s):
    punct = ['.', ',', ';', ':', '\'', '\"', '(', ')', '[', ']', '{', '}', '-']
    return s in punct

def is_subj_np(np):
    return np.root.dep_ == 'nsubj' or np.root.dep_ == 'ROOT'

def is_main_v(token):
    return token.dep_ in ['ROOT', 'acl'] and token.head.pos_ == 'VERB'

# NOTE: does not perform spell-check
def clean(text):
    # remove capitalization, punctuation, and NaN
    text = [s.lower() for s in text if (not is_punct(s)) and s == s]
    return text
