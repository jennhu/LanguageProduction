'''
    Name: viz.py
    Author: Jennifer Hu
    Purpose: Read JSON file with cleaned data and generate HTML file that
             allows you to visualize the stimuli and the MTurk productions.
'''
import argparse
import json

# number of images to display in each row of HTML file
NUM_COLS = 4

##################################################################################
## HTML HELPER FUNCTIONS
##################################################################################

def stim_link(stim, hit):
    return 'https://jennhu.scripts.mit.edu/hit{}/{}'.format(hit, stim)

def header_html(hit):
    return '<!DOCTYPE html>\n<h1 style=\'text-align:center\'>Responses for HIT {}</h1>\n'.format(hit)

def resp_html(data_dict, stim):
    responses = data_dict[stim]
    resp_html = '<br>'.join(responses)
    return '<p>' + resp_html + '</p>'

def row_html(data_dict, stim, hit):
    link = stim_link(stim, hit)
    img_style = 'style=\'max-height:70%; max-width:70%; margin:auto;\''
    resp = resp_html(data_dict, stim)
    return '\t<td valign=\'bottom\'><img src=\'{}\' alt=\'\' {}></img>{}</td>\n'\
           .format(link, img_style, resp)

def table_html(data_dict, hit):
    s = '<table style=\'width:100%; text-align:center;\'>\n'
    for i, (stim, responses) in enumerate(data_dict.items()):
        # first image in row
        if i % NUM_COLS == 0:
            s += '<tr>\n'
        s += row_html(data_dict, stim, hit)
        # last image in row
        if i % NUM_COLS == NUM_COLS - 1:
            s += '</tr>\n'
    s += '</table>\n'
    return s

def write_html(data_dict, hit, out):
    html_str = header_html(hit) + table_html(data_dict, hit) + '</html>'
    with open(out, "w") as f:
        f.write(html_str)

##################################################################################
## MAIN
##################################################################################

def main(data, hit, out):
    # read responses from .json data into dict
    json_path = '{}/hit{}.json'.format(data, hit)
    print('Reading data from {}...'.format(json_path))
    with open(json_path) as f:
        data_dict = json.load(f)

    # write .html file for visualization
    write_html(data_dict, hit, out)
    print('Wrote viz file to {}'.format(out))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str,
                        help='path to clean data file (will look for <data>/hit<hit>.json)')
    parser.add_argument('--hit', type=int, choices=[1,2,3,4],
                        help='HIT number (1-4)')
    parser.add_argument('--out', type=str,
                        help='path to .html file to write')
    args = parser.parse_args()

    main(**vars(args))
