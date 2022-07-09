import pandas as pd

################################################################################
# CONSTANTS AND MAPS
################################################################################
SIG_LEVEL = 0.05
ROI_names = {
    "lang": ['IFGorb', 'IFG', 'MFG', 'AntTemp', 'PostTemp', 'AngG'],
    "MD": ['LH PostParietal', 'LH midParietal', 'LH antParietal', 'LH supFrontal',
           'LH Precentral A PrecG', 'LH Precentral B IFGop', 'LH midFrontal',
           'LH midFrontalOrb', 'LH insula', 'LH medialFrontal',
           'RH PostParietal', 'RH midParietal', 'RH antParietal', 'RH supFrontal',
           'RH Precentral A PrecG', 'RH Precentral B IFGop', 'RH midFrontal',
           'RH midFrontalOrb', 'RH insula', 'RH medialFrontal']
}
expt_names = {
    "expt1": "Experiment 1",
    "expt2": "Experiment 2",
    "expt3": "Experiment 3"
}
network_names = {
    "lang": "Language",
    "MD": "MD"
}
# captions = {
#     "Q1": "Q1: Does sentence production elicit a response in the language network?",
#     "Q2": "Q2: Does the language network's response to sentence production generalize across output modality?",
#     "Q3": "Q3: Does the language network respond to both lexical access and syntactic encoding?",
#     "Q3-control": "Q3 [CONTROL]: Is language production more demanding than (non)word production?"
# }
# labels = {x: "tab:" + x for x in captions.keys()}
# col_widths = {
#     "Q1": "14mm", "Q2": "20mm", "Q3": "15mm", "Q3-control": "15mm"
# }
col_widths = {
    "table1": "14mm", 
    "table2": "15mm", 
    "table3": "15mm",
    "si_table1": "20mm"
}
q_to_table = {
    "Q1": "table1",
    "Q2": "si_table1",
    "Q3": "table2",
    "Q3-control": "table3"
}
def pretty_cond_name(c):
    if "_" in c:
        x, y = c.split("_")
        return f"{x} ({y})"
    else:
        return c
def format_p(p, bold=False):
    p = "p<0.001" if p < 1e-3 else f"p={p:.3f}"
    if bold:
        return "$\\mathbf{" + p + "}$"
    else:
        return f"${p}$"

################################################################################
# PREDICTIONS
################################################################################

# Specify which contrasts we predict to be significant.
def positive(d):
    return d > 0
def negative(d):
    return d < 0
PREDICTIONS = {
    "table1": {
        "Experiment 1": {
            "sig": ["SProd-fixation","SProd-N", "SProd-VisEvSem"],
            "direction": positive,
            "nonsig": []
        },
        "Experiment 2": {
            "sig": ["SProd-fixation","SProd-N"],
            "direction": positive,
            "nonsig": []
        },
    },
    "si_table1": {
        "Experiment 3": {
            "sig": ["SProd (typed)-fixation","SProd (typed)-N", "SProd (typed)-VisEvSem"],
            "direction": positive,
            "nonsig": ["SProd (typed)-SProd"],
        },
    },
    "table2": {
        "Experiment 1": {
            "sig": ["WProd-NProd", "SProd-WProd"],
            "direction": positive,
            "nonsig": []
        },
        # "Experiment 2": {
        #     "sig": ["SProd-WProd"],
        #     "direction": positive,
        #     "nonsig": []
        # },
        # "Experiment 3": {
        #     "sig": ["WProd (typed)-NProd (typed)", "SProd (typed)-WProd (typed)"],
        #     "direction": positive,
        #     "nonsig": []
        # },
    },
    "table3": {
        "Experiment 1": {
            "sig": ["SProd-WProd", "SProd-NProd"],
            "direction": negative,
            "nonsig": []
        },
        "Experiment 2": {
            "sig": ["SProd-WProd"],
            "direction": negative,
            "nonsig": []
        },
        "Experiment 3": {
            "sig": ["SProd-WProd", "SProd-NProd"],
            "direction": negative,
            "nonsig": []
        }
    }
}
def format_cell(cell, p, d, table, contrast, expt):
    pred = PREDICTIONS[table][expt]
    if p < SIG_LEVEL:
        if contrast in pred["sig"]:
            # Shade green if significant in the predicted direction.
            if pred["direction"](d):
                return "\cellcolor{g}%s" % cell
            else:
            # Shade red if significant in the opposite direction.
                return "\cellcolor{r}%s" % cell
        elif contrast in pred["nonsig"]:
            # Shade blue if significant and not predicted to be significant.
            return "\cellcolor{b}%s" % cell
    return cell

################################################################################
# DATA PROCESSING
################################################################################

# Consistent data processing across questions.
def process(path, by_expt=False):
    df = pd.read_csv(path, float_precision="high")
    # Replace underscores with LaTeX-friendly formatting.
    df['cond1'] = df['cond1'].apply(pretty_cond_name)
    df['cond2'] = df['cond2'].apply(pretty_cond_name)
    df['contrast'] = df["cond1"] + " vs.\\newline " + df["cond2"]
    df['contrast_ugly'] = df["cond1"] + "-" + df["cond2"]
    if by_expt:
        df['expt'] = df['expt_data'].str.split('_', expand=True)[0]
        df['pretty_expt'] = df['expt'].map(expt_names)
    return df

# Read in all data.
dfs = {
    q : {
        "sepfROIs": process(f"results/{q}_sepfROIs.csv", by_expt=True),
        "network": process(f"results/{q}_network.csv", by_expt=True)
    } for q in ["Q1", "Q2", "Q3"]
}

################################################################################
# GENERAL TABLE FUNCTIONS
################################################################################

def tabular_str(df, df_network, table, network="lang", tab="    ", col_width="14mm"):
    # Filter df depending on network of interest.
    if network == "lang":
        df = df[~df.expt_data.str.contains("MD")]
        df_network = df_network[~df_network.expt_data.str.contains("MD")]
    else:
        df = df[df.expt_data.str.contains("MD")]
        df_network = df_network[df_network.expt_data.str.contains("MD")]
    # Initialize header strings.
    tabular_header = tab + "\\begin{tabular}{V{3}c"
    row_super = tab
    row_header = tab + "fROI & "
    # Update header strings.
    expt_names = sorted(PREDICTIONS[table].keys()) #sorted(df.pretty_expt.unique())
    for expt in expt_names:
        rows = df[df.pretty_expt==expt]
        contrasts = rows.contrast.unique()
        tabular_header += "|*{%d}{p{%s}}" % (len(contrasts), col_width)
        if expt != expt_names[-1]:
            row_super += " & \multicolumn{%d}{c|}{\\textbf{%s}}" % (len(contrasts), expt)
        else:
            row_super += " & \multicolumn{%d}{cV{3}}{\\textbf{%s}}" % (len(contrasts), expt)
        row_header += " & ".join(contrasts)
        if expt != expt_names[-1]:
            row_header += " & "
    
    # Initialize list of row strings.
    row_strs = []

    # Get row str corresponding to entire network.
    row_str = tab + "\multirow{2}{*}{\\textbf{%s network}}" % network_names[network]
    for expt in expt_names:
        rows = df_network[df_network.pretty_expt==expt]
        contrasts = rows.contrast_ugly.unique()
        for contrast in contrasts:
            contrast_rows = rows[(rows.contrast_ugly==contrast)]
            p = contrast_rows.p_value.values[0]
            d = contrast_rows.cohen_d.values[0]
            p_str = format_p(p, bold=True)
            d_str = "$\\mathbf{" + f"d={d:.3f}" + "}$" if not pd.isna(d) else "$\\mathbf{d=-}$"
            cell_str = f"{d_str}\\newline{p_str}"
            cell_str = format_cell(cell_str, p, d, table, contrast, expt)
            row_str += f" & {cell_str}"
    row_str += "\\\\\hline"
    row_strs.append(row_str)

    # Individual ROI results.
    for ROI in sorted(df.ROI.unique()):
        row_str = tab
        try:
            ROI_name = "\multirow{2}{*}{%s}" % ROI_names[network][ROI-1]
            row_str += ROI_name
        except:
            row_str += "\multirow{2}{*}{%s}" % str(ROI)
        for expt in expt_names:
            rows = df[df.pretty_expt==expt]
            contrasts = rows.contrast_ugly.unique()
            for contrast in contrasts:
                contrast_rows = rows[(rows.contrast_ugly==contrast)&(rows.ROI==ROI)]
                p = contrast_rows.p_value_fdr_corrected.values[0]
                d = contrast_rows.cohen_d.values[0]
                p_str = format_p(p)
                d_str = f"$d={d:.3f}$" if not pd.isna(d) else "$d=-$"
                cell_str = f"{d_str}\\newline{p_str}"
                cell_str = format_cell(cell_str, p, d, table, contrast, expt)
                row_str += f" & {cell_str}"
        row_str += "\\\\"
        row_strs.append(row_str)

    # Finish up header strings.
    tabular_header += "V{3}} \\hlineB{3}"
    row_super += "\\\\"
    row_header += " \\\\\hline"
    row_str = f"\n".join(row_strs) + "\\hlineB{3}"
    tab_str = "\n".join([
        tabular_header, row_super, row_header, row_str, tab + "\end{tabular}"
    ])
    return tab_str

def make_table(q, **kwargs):
    # Get data corresponding to source for question of interest.
    table = q_to_table[q]
    q_src = q.split("-")[0]
    df, df_network = dfs[q_src]["sepfROIs"], dfs[q_src]["network"]
    # Get tabular string, and embed it within a standalone document.
    tabular = tabular_str(df, df_network, table, col_width=col_widths[table], **kwargs)
    doc = """\\documentclass[margin=0.1cm]{standalone}
\\usepackage[utf8]{inputenc}
\\usepackage{times}
\\usepackage{newtxmath}
\\usepackage[table]{xcolor}
\\definecolor{g}{RGB}{197, 217, 191}
\\definecolor{r}{RGB}{238, 196, 196}
\\definecolor{b}{RGB}{196, 227, 238}
\\usepackage{boldline} 
\\usepackage{multirow}
\\begin{document}
\\scriptsize
\\renewcommand{\\arraystretch}{1.5}
%s
\\end{document}""" % tabular
    return doc

################################################################################
# MAKE TABLES
################################################################################

# Generate tables for lang network analyses.
for q in ["Q1", "Q2", "Q3", "Q3-control"]:
    table = make_table(q, network="lang" if q != "Q3-control" else "MD")
    with open(f"tables/{q_to_table[q]}.tex", "w") as f:
        f.write(table)

# Separately make table for control MD network analyses.
# q = "Q3-control"
# table = make_table(q, network="MD")
# with open(f"tables/Q4.tex", "w") as f:
#     f.write(table)
