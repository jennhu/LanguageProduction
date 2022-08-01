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
col_widths = {
    "table1": "14mm", 
    "table2": "15mm", 
    "table_si2": "17mm",
    "table_si3": "18mm",
    "table_si4": "15.7mm",
}
def pretty_cond_name(c):
    if "_" in c:
        x, y = c.split("_")
        return f"{x} ({y})"
    else:
        return c
def pretty_effect_name(e):
    d = {
        "TaskType": "Production vs. Comprehension",
        "StimType": "Sentences vs. Word lists",
        "TaskType:StimType": "Interaction"
    }
    return d[e]
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
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAIN-TEXT TABLES
    "table1": {
        "Experiment 1": {
            "sig": ["SProd-fixation", "SProd-Nonwords", "SProd-NProd", "SProd-VisEvSem"],
            "direction": positive,
            "nonsig": []
        }
    },
    "table2": {
        "Experiment 1": {
            "sig": ["SProd-WProd", "WProd-NProd"],
            "direction": positive,
            "nonsig": []
        }
    },
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SUPPLEMENTARY TABLES
    "table_si2": {
        "Experiment 2": {
            "sig": ["SProd-fixation","SProd-Nonwords"],
            "direction": positive,
            "nonsig": []
        },
        "Experiment 3": {
            "sig": ["SProd (typed)-fixation","SProd (typed)-Nonwords", 
                    "SProd (typed)-WProd (typed)", "SProd (typed)-NProd (typed)", 
                    "SProd (typed)-VisEvSem"],
            "direction": positive,
            "nonsig": []
        },
    },
    "table_si3": {
        "Experiment 2": {
            "sig": ["SProd-WProd"],
            "direction": positive,
            "nonsig": []
        },
        "Experiment 3": {
            "sig": ["SProd (typed)-WProd (typed)", "WProd (typed)-NProd (typed)"],
            "direction": positive,
            "nonsig": []
        }
    },
    "table_si4": {
        "Experiment 1": {
            "sig": [],
            "nonsig": []
        },
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
    try:
        # Replace underscores with LaTeX-friendly formatting.
        df['cond1'] = df['cond1'].apply(pretty_cond_name)
        df['cond2'] = df['cond2'].apply(pretty_cond_name)
        df['contrast'] = df["cond1"] + " vs.\\newline " + df["cond2"]
        df['contrast_ugly'] = df["cond1"] + "-" + df["cond2"]
    except:
        print(f"Skipping formatting for {path}")
    if by_expt:
        df['expt'] = df['expt_data'].str.split('_', expand=True)[0]
        df['pretty_expt'] = df['expt'].map(expt_names)
    return df

# Read in all data.
dfs = {
    table : {
        "sepfROIs": process(f"results/{table}_sepfROIs.csv", by_expt=True),
        "network": process(f"results/{table}_network.csv", by_expt=True)
    } for table in PREDICTIONS.keys()
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
    expt_names = sorted(PREDICTIONS[table].keys())
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

# Slightly modified code for Table SI-4
def tabular_str_si4(df, df_network, table, network="lang", tab="    ", col_width="14mm"):
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
    expt_names = sorted(PREDICTIONS[table].keys())
    for expt in expt_names:
        rows = df[df.pretty_expt==expt]
        effects = rows.effect.unique()
        tabular_header += "|*{%d}{p{%s}}" % (len(effects), col_width)
        if expt != expt_names[-1]:
            row_super += " & \multicolumn{%d}{c|}{\\textbf{%s}}" % (len(effects), expt)
        else:
            row_super += " & \multicolumn{%d}{cV{3}}{\\textbf{%s}}" % (len(effects), expt)
        row_header += " & ".join(pretty_effect_name(e) for e in effects)
        if expt != expt_names[-1]:
            row_header += " & "
    
    # Initialize list of row strings.
    row_strs = []

    # Get row str corresponding to entire network.
    row_str = tab + "\multirow{2}{*}{\\textbf{%s network}}" % network_names[network]
    for expt in expt_names:
        rows = df_network[df_network.pretty_expt==expt]
        effects = rows.effect.unique()
        for effect in effects:
            effect_rows = rows[rows.effect==effect]
            p = effect_rows.p_value.values[0]
            d = effect_rows.cohen_d.values[0]
            p_str = format_p(p, bold=True)
            d_str = "$\\mathbf{" + f"d={d:.3f}" + "}$" if not pd.isna(d) else "$\\mathbf{d=-}$"
            cell_str = f"{d_str}\\newline{p_str}"
            cell_str = format_cell(cell_str, p, d, table, effect, expt)
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
            effects = rows.effect.unique()
            for effect in effects:
                effect_rows = rows[(rows.effect==effect)&(rows.ROI==ROI)]
                p = effect_rows.p_value_fdr_corrected.values[0]
                d = effect_rows.cohen_d.values[0]
                p_str = format_p(p)
                d_str = f"$d={d:.3f}$" if not pd.isna(d) else "$d=-$"
                cell_str = f"{d_str}\\newline{p_str}"
                cell_str = format_cell(cell_str, p, d, table, effect, expt)
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

def make_table(table, **kwargs):
    # Get data corresponding to source for question of interest.
    df, df_network = dfs[table]["sepfROIs"], dfs[table]["network"]
    # Get tabular string, and embed it within a standalone document.
    fn = tabular_str if table != "table_si4" else tabular_str_si4
    tabular = fn(df, df_network, table, col_width=col_widths[table], **kwargs)
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

if __name__ == "__main__":
    # Generate tables for lang network analyses.
    for table_name in PREDICTIONS.keys():
        print(f"Making {table_name}")
        table_tex = make_table(table_name, network="lang")
        with open(f"tables/{table_name}.tex", "w") as f:
            f.write(table_tex)