'''
    Name: generate_material_list.py
    Author: Jennifer Hu
    Purpose: Generate the list of experimental materials expected by the
             MATLAB experimental script. Only needs to be run once.
             Only run this if you need to edit the materials/stimuli.
'''

import pandas as pd

def get_lists(key_path):
    key = pd.read_csv(key_path, index_col=None)
    return key[:64], key[64:]

def read_file(path):
    with open(path, 'r') as f:
        lines = f.readlines()
    return [s.strip('\n') for s in lines]

def main():
    headers = ['ItemNum', 'Condition', 'Item', 'List']
    data = {h: [] for h in headers}

    first_ev, last_ev = get_lists('keys/key_ev.csv')
    first_ob, last_ob = get_lists('keys/key_ob.csv')

    # SPROD, EVSEM, WPROD: LIST 1 1-64, LIST 2 65-128
    for list_i in [1, 2]:
        l_ev = first_ev if list_i == 1 else last_ev
        l_ob = first_ob if list_i == 1 else last_ob
        # SPROD
        data['ItemNum'] += l_ev['ev_id'].values.tolist()
        data['Condition'] += ['SPROD'] * len(l_ev.index)
        data['Item'] += l_ev['img'].values.tolist()
        data['List'] += [list_i] * len(l_ev.index)
        # EVSEM
        data['ItemNum'] += l_ev['ev_id'].values.tolist()
        data['Condition'] += ['EVSEM'] * len(l_ev.index)
        data['Item'] += l_ev['img'].values.tolist()
        data['List'] += [list_i] * len(l_ev.index)
        # WPROD
        data['ItemNum'] += l_ob['ob_id'].values.tolist()
        data['Condition'] += ['WPROD'] * len(l_ob.index)
        data['Item'] += l_ob['img'].values.tolist()
        data['List'] += [list_i] * len(l_ob.index)

    # SCOMP, WCOMP: LIST 1 65-128, LIST 2 1-64
    for list_i in [1, 2]:
        l_ev = last_ev if list_i == 1 else first_ev
        l_ob = last_ob if list_i == 1 else first_ob
        # SCOMP
        data['ItemNum'] += l_ev['ev_id'].values.tolist()
        data['Condition'] += ['SCOMP'] * len(l_ev.index)
        data['Item'] += [s.upper().strip('.') for s in l_ev['target'].values.tolist()]
        data['List'] += [list_i] * len(l_ev.index)
        # WCOMP
        data['ItemNum'] += l_ob['ob_id'].values.tolist()
        data['Condition'] += ['WCOMP'] * len(l_ob.index)
        data['Item'] += ['    '.join(w.upper().split(',')) for w in l_ob['target'].values.tolist()]
        data['List'] += [list_i] * len(l_ob.index)

    # NPROD (coded as ARTIC in scripts)
    data['ItemNum'] += range(1,65)
    data['ItemNum'] += range(1,65)
    data['Condition'] += ['ARTIC'] * 64 * 2
    nprod_stims = read_file('NProd/stimuli/nonwords.txt')
    nprod_stims = ['    '.join(s.upper().split(',')) for s in nprod_stims]
    data['Item'] += nprod_stims
    data['Item'] += nprod_stims
    data['List'] += [1] * 64
    data['List'] += [2] * 64

    for k, v in data.items():
        print(k, len(v))

    df = pd.DataFrame(data, columns=headers)
    df.to_csv('expt1-2/ProdLoc_materials.csv', index=False)

if __name__ == '__main__':
    main()
