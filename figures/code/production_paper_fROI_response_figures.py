#!/usr/bin/env python
# coding: utf-8

# In[1]:


## Script for plotting results of the production localizer experiment in EvLab
# Figure 2, language network fROI responses to the conditions of language and production localizers
# Figure 3, MD network fROI responses to the conditions of MD and production localizers


# In[7]:


#dependencies
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.transforms as transforms
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
import matplotlib.patches as mpatches
import pandas as pd
import numpy as np
import statistics
import math


# In[8]:


#define helper filter functions

#function that filters a dataframe by specified values in a specified column of the dataframe
# example: dataframe containing columns subject_id, fROI, condition, effect_size
# calling filter_X(data, ['cond1','cond2'], 'condition') will return the dataframe with only the rows
# that have cond1 or cond2 as the condition
def filter_X(data, targets, name_in_data):
    if isinstance(targets, list): 
        filter = 0
        for target in targets:
            filter = filter | (data[name_in_data] == target)
        return (data[filter])
    else:
        raise TypeError("targets must be a list")

# function that filters a dataframe by the specified conditions in the Effect column for each expt (use filter_X for a 
# more general purpose filter function -- you can specify the column name to filter on there)
def filter_conditions(data, conditions):
    if(isinstance(conditions,dict)):
        tmp = []
        for expt in conditions:
            tmp = tmp + conditions[expt]
        
        conditions = np.unique(tmp)
        filter = 0
        for cond in conditions:
            filter = filter | (data.Effect == cond)
        return (data[filter])
    else:
        raise Exception('conditions should be a dictionary specifying the conditions to be retained for each expt')

# function that modifies experiment names -- this was very specific to the production paper, but could 
# potentially be used for other things. consolidated_expt is an experiment that is present in all of the 
# different experiments, for example, langloc. experiment_names is a list of experiments currently in the dataframe 
# and new_exp_names is a list of new names (parallel with experiment_names) -- critical_tasks is more labels 
# for the exp_names (kind of specific to production paper)
def modify_experiment_names(data, consolidated_expt, experiment_names, new_exp_names, critical_tasks):
    modified_data = data[0:0]
    for ind,exp in enumerate(experiment_names):
        if(consolidated_expt!=None):
            if(exp !=consolidated_expt):
                selected_data = data[(data.Expt==exp) & (data.CriticalTask==critical_tasks[ind])].copy()
            else:
                selected_data = data[(data.CriticalTask==critical_tasks[ind])].copy()
        else:
            selected_data = data[(data.CriticalTask==critical_tasks[ind])].copy()
            
        
        selected_data.loc[:,'Expt'] = new_exp_names[ind]
        modified_data = pd.concat([modified_data, selected_data])
    return(modified_data)

#wrapper function to filter and prep data for plotting figures for production paper
def prep_data(data, consolidated_expt, networks, hemispheres, ROIs, conditions, critical_tasks, experiment_names, new_exp_names):
    prepped_data = data
    prepped_data = filter_X(prepped_data, networks, 'Network')
    prepped_data = filter_X(prepped_data, hemispheres,'Hemisphere')
    prepped_data = filter_X(prepped_data, ROIs,'ROI')
    prepped_data = filter_conditions(prepped_data, conditions)
    
    prepped_data = modify_experiment_names(prepped_data, consolidated_expt, experiment_names, new_exp_names, critical_tasks)
    
    return (prepped_data)


#helper functions for plotting

#this function adds the expanded labels with n count below each group of bars corresponding to an experiment
def add_extended_labels(ax,data,network,label_dict,expt_order,font_size, x_pos):
    expts = expt_order
    num_expts = len(expts)
    
    n_dict = dict()
    for expt in expts:
        n_dict[expt] = len(np.unique(data[data.Expt==expt]['Subject']))
          
    label_y = -0.09
    n_y = label_y-0.04
    
    if((network=="lowlevel_speaking") | (network=="lowlevel_typing")):
        label_y = -0.12
        n_y = label_y-0.06
    
    #the x coords of this transformation are data, and the y coord are axes, so we can plot below the axes
    #https://matplotlib.org/tutorials/advanced/transforms_tutorial.html
    #trans = ax.get_xaxis_transform()
    
    for i in range(num_expts):
        x = x_pos[i]
        ax.annotate(text="n = " + str(n_dict[expts[i]]),
                    xy=(x,n_y), xycoords=('data','axes fraction'),
                    horizontalalignment='center', verticalalignment='bottom',
                    fontsize=font_size )
        
        ax.annotate(text=label_dict[expts[i]],
                     xy=(x,label_y), xycoords=('data','axes fraction'),
                    horizontalalignment='center', verticalalignment='bottom', fontsize=font_size)
               

# this function adds experiment specific icons underneath groups of bars corresponding to different experiments
def add_icons(ax,label_dict,expts, x_pos, shift):
    #read in images for plotting
    mouth_img = plt.imread('../images/mouth.png')
    keyboard_img = plt.imread('../images/keyboard.png')
    
    #make room for icons
    old_bottom = ax.get_ylim()[0]
    new_bottom = old_bottom-0.7
    ax.set_ylim(bottom=new_bottom)
    
    y = (new_bottom-old_bottom)/1.8
    num_expts = len(expts)
    for i in range(num_expts):
        label = label_dict[expts[i]]
        if(label!=''):
            x = x_pos[i]
            if("typing" in label):
                im = OffsetImage(keyboard_img,zoom=0.33)
            else:
                im = OffsetImage(mouth_img,zoom=0.55)
            ab=AnnotationBbox(im, (x,y), xycoords='data',frameon=False, box_alignment=(0.0,0.5))
            ax.add_artist(ab)

# this function adds an image to the figure in roughly the top right (changes according to which figure it is)             
def add_brain_image(ax,image_file, main_brain, network):
    brain_img = plt.imread(image_file)
    if(main_brain):
        im = OffsetImage(brain_img,zoom=1.1)
        y = 0.72
    else:
        im = OffsetImage(brain_img,zoom=1)
        y = 0.78
        
    legend = ax.get_legend()
        
    #different x position depending on whether there is a legend on plot
    if(legend==None):
        x = 0.6
    else:
        x = 0.45
        
    if(network =="lang"):
        x = x - 0.08
        
    if(network =="MD"):
        y = y + 0.05
        x = x - 0.15
        
    if(network == "lowlevel_speaking"):
        x = x + 0.15
        y = y - 0.21
        
    if(network == "lowlevel_typing"):
        x = x - 0.35
        y = y - 0.21

    
    ab=AnnotationBbox(im, (x,y), xycoords='axes fraction', frameon=False, box_alignment=(0.0,0.5))
    ax.add_artist(ab)

#this function generates a list of means and standard errors in a given expt order from the specified conditions in a dataset
def generate_bar_data(data,expt_order,conditions):
    
    if not isinstance(conditions,dict):
        raise TypeError("conditions must be a dictionary specifying the conditions for each expt")
        
    bar_means_list = []
    bar_errors_list = []
    for expt in expt_order:
        bar_means = []
        bar_errors = []
        for condition in conditions[expt]:
            current_data = data[(data.Expt==expt)&(data.Effect==condition)]["EffectSize"]
            n = len(current_data)
            mean = statistics.mean(current_data)
            SEM = statistics.stdev(current_data)/math.sqrt(n)
            
            bar_means.append(mean)
            bar_errors.append(SEM)
            
        bar_means_list.append(bar_means)
        bar_errors_list.append(bar_errors)
    
    return (bar_means_list, bar_errors_list)
            


# In[9]:


#function to make a figure from given data -- assumes individual level data
def plot_data(ax,data, data_title,network, expt_order, conditions, xlim=None,ylim=None,main_brain=False,brain_image="",plot_legend=False,plot_labels=False,plot_icons=False):
    
    SMALL_SIZE = 40
    MEDIUM_SIZE = 50
    BIGGER_SIZE = 60

    plt.rc('font', size=MEDIUM_SIZE)          # controls default text sizes
    plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
    plt.rc('axes', labelsize=SMALL_SIZE)    # fontsize of the x and y labels
    plt.rc('xtick', labelsize=MEDIUM_SIZE)    # fontsize of the tick labels
    plt.rc('ytick', labelsize=MEDIUM_SIZE)    # fontsize of the tick labels
    plt.rc('legend', fontsize=MEDIUM_SIZE)    # legend fontsize
    plt.rc('figure', titlesize=BIGGER_SIZE)  # fontsize of the figure title
    plt.rc('font',**{'family':'sans-serif','sans-serif':['Arial']})

    #for plotting
    color_dict = {'SProd':'firebrick',
                 'WProd':'lightcoral',
                 'NProd':'mistyrose',
                 'SComp':'steelblue',
                 'WComp':'lightblue',
                 'VisEvSem':'seagreen',
                 'H':'dimgrey',
                 'E':'lightgrey',
                 'S':'dimgrey',
                 'N':'lightgrey'}
    tmp = []
    for expt in conditions:
        tmp = tmp + conditions[expt]
    all_conditions = tmp #extract all conditions
    
    conditions_for_legend = pd.unique(all_conditions)
    
    num_bars = len(all_conditions)
    
    colors_to_plot = [color_dict[x] for x in all_conditions]
    colors_to_plot.reverse() #so we can pop the colors off while plotting

    bar_alpha = 1
    make_bar_smaller = 2
    bar_width = (1/num_bars)/make_bar_smaller
    edgecolor = "black"
    linewidth = 4
    capsize = 0
    
    bar_means_all_expts, bar_errors_all_expts = generate_bar_data(data,expt_order,conditions)
    
    sliding_x_pos = 0
    space_between_expts = bar_width*1.5
    
    #will use these lists to put labels on x-axis in correct positions
    first_x_pos = [] #list to keep track of the x pos of the first condition in each expt
    last_x_pos = [] #list to keep track of the x pos of the last condition in each expt
    
    #outer loop goes through the different experiments, inner loop goes through each condition of each experiment
    # and plots each condition as a bar, sliding_x_pos keeps track of the x position of the current bar
    for expt_index,(expt_means,expt_errors) in enumerate(zip(bar_means_all_expts,bar_errors_all_expts)):
        for cond_index,(mean,error) in enumerate(zip(expt_means,expt_errors)):
            if(cond_index==0):
                first_x_pos.append(sliding_x_pos)
            ax.bar(x = sliding_x_pos,
                   height=mean,
                   width=bar_width,
                   color=colors_to_plot.pop(),
                   yerr=error, 
                   error_kw={'linewidth':linewidth, 'capsize':capsize, 'capthick':linewidth},
                   alpha=bar_alpha,
                   edgecolor = edgecolor,
                   linewidth=linewidth
                  )
            sliding_x_pos = sliding_x_pos + bar_width
        last_x_pos.append(sliding_x_pos) 
        sliding_x_pos = sliding_x_pos + space_between_expts

    #save the x_label_pos of each group of experiments (use this for extended labels and icons later)
    # the 2.7 is a constant that I had to manually play around with get the spacing right
    x_label_pos = [(last_x_pos[i]-first_x_pos[i])/2.7 + first_x_pos[i] for i in range(len(first_x_pos))]

    ax.set(title=data_title,
           ylabel='Percent BOLD signal change',
           xticks = x_label_pos,
           xticklabels= expt_order)
    
    if(ylim!=None):
        ax.set(ylim=ylim)
    if(xlim!=None):
        ax.set(xlim=xlim)
    
    legend_handles = [mpatches.Patch(color=color_dict[cond], label=cond) for cond in conditions_for_legend]

    legend_fontsize = 'x-small'
    legend_loc = 'upper right'
    legend_ncol = 1
    
    #different legend formatting in lowlevel region figures
    if((network == "lowlevel_speaking")| (network == "lowlevel_typing")):
        #legend_fontsize = 'xx-small'
        legend_ncol = 2
        
    if(network == "lowlevel_typing"):
        legend_loc = 'upper left'

    ax.legend(loc=legend_loc, 
              handles=legend_handles,
              ncol=legend_ncol, 
              fancybox=False, 
              shadow=True, 
              markerscale = 4, 
              fontsize = legend_fontsize)
    
    if(plot_legend==False):
        ax.get_legend().remove()
        
    if(len(brain_image)>0):
        add_brain_image(ax, brain_image, main_brain,network)
    label_dict = {'MD':'',
                 'LangLoc': '',
                 'E1':'(speaking)',
                 'E2a':'(speaking)',
                 'E2b':'(typing)',
                 'E3':'(speaking)'}
    if(plot_labels):
        add_extended_labels(ax,indiv_data, network,label_dict,expt_order,SMALL_SIZE,x_label_pos)
        
    left_shift = bar_width/2
    if(plot_icons):
        add_icons(ax,label_dict,expt_order, first_x_pos, left_shift)    


# In[10]:


data_title = 'a. Average fROI response in the lang network'
networks = ['lang'] #which network to include in data
hemispheres = ["LH"] #which hemisphere to include in data
ROIs = [i for i in range(1,6+1)]


#read in the csv with all data
#this csv is in long format
all_indiv_data = pd.read_csv('../../data/fMRI_all_indiv_production_data.csv')

experiment_names = ["langloc","E1","E2","E2","E3"]
new_exp_names = ["LangLoc","E1","E2a","E2b","E3"] #one to one correspondence with above list, replacement names

conditions = {"LangLoc": ["S","N"],
             "E1": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"],
             "E2a": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"],
             "E2b": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"],
             "E3": ["SProd","WProd"]}

criticalTasks = ["langloc","ProdLoc_spoken","ProdLoc_spoken","ProdLoc_typed","NameRead"] #target criticalTasks in the expts
consolidated_expt = "langloc" #expt that has consolidated data across all the experiments

#create layout for the full figure
lang_fig = plt.figure(figsize=(90,54),constrained_layout=False)
gs1 = lang_fig.add_gridspec(nrows=7, ncols=6, left=0.05, right=0.48, wspace=0.4, hspace = 0.8)
lang_fig_ax1 = lang_fig.add_subplot(gs1[0:3,1:5])

indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

plot_data(ax=lang_fig_ax1,
         data=indiv_data, 
         data_title=data_title,
         network = 'lang',
         expt_order = new_exp_names,
         conditions = conditions,
         brain_image = "../images/lang_LH.png",
         main_brain = True,
         plot_legend=True,
         plot_labels=True,
         plot_icons=True,
         ylim=(0,3.1))

col_idx= [0,2,4]
row_idx= [3,5]
alphabet_labels = ['b','c','d','e','f','g']
ROIs = 0
for row in row_idx:
    for col in col_idx:
        ROIs= ROIs+1
        if ROIs<=3:
            ylim=(-0.5,6.09)
        else:
            ylim=(-1.3,3)
        lang_fig_ax = lang_fig.add_subplot(gs1[row:row+2,col:col+2])
        indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, [ROIs], conditions, criticalTasks, experiment_names, new_exp_names)
        #get name of ROI for plotting and to get correct brain image
        ROI_name = "".join(pd.unique(indiv_data.ROI_name))
        data_title=alphabet_labels[ROIs-1]+'. '+ROI_name
        brain_image="../images/lang_L"+ROI_name+".png"
        plot_data(ax=lang_fig_ax,
                 data=indiv_data, 
                 data_title=data_title,
                 network = 'lang',
                 expt_order = new_exp_names,
                 conditions = conditions,
                 brain_image = brain_image,
                 ylim=ylim)
        
plt.savefig("../figures/lang_fig.tiff", bbox_inches = 'tight')  


# In[12]:


data_title = 'a. Average fROI response in the MD network'
networks = ['MD'] #which network to include in data
hemispheres = ["LH","RH"] #which hemisphere to include in data
ROIs = [i for i in range(1,20+1)]

conditions = {"MD": ["H","E"],
             "E1": ["SProd","WProd", "NProd"],
             "E2a": ["SProd","WProd", "NProd"],
             "E2b": ["SProd","WProd","NProd"],
             "E3": ["SProd","WProd"]}

#read in the csv with all data
all_indiv_data = pd.read_csv('../../data/fMRI_all_indiv_production_data.csv')

experiment_names = ["MD","E1","E2","E2","E3"]
new_exp_names = ["MD","E1","E2a","E2b","E3"] #one to one correspondence with above list, replacement names

criticalTasks = ["spWM","ProdLoc_spoken","ProdLoc_spoken","ProdLoc_typed","NameRead"] #target criticalTasks in the expts
consolidated_expt = "MD" #expt that has consolidated data across all the experiments

#create layout for the full figure
MD_fig = plt.figure(figsize=(80,40),constrained_layout=False)
gs1 = MD_fig.add_gridspec(nrows=7, ncols=6, left=0.05, right=0.48, wspace=0.4,hspace = 1.6)
MD_fig_ax1 = MD_fig.add_subplot(gs1[0:4,1:5])
MD_fig_ax2 = MD_fig.add_subplot(gs1[4:7,:-3 ])
MD_fig_ax3 = MD_fig.add_subplot(gs1[4:7,3:])

ylim = (0, 3.6)
indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

plot_data(ax=MD_fig_ax1,
         data=indiv_data, 
         data_title=data_title,
         network = "MD",
         expt_order = new_exp_names,
         conditions = conditions,
         brain_image = "../images/MD_RH.png",
         main_brain = True,
         plot_legend=True,
         plot_labels=True,
         plot_icons=True,
         ylim=None)



ylim = (0,3.5)
hemispheres = ["LH"]
data_title = "b. LH MD network"

indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

plot_data(ax=MD_fig_ax2,
         data=indiv_data,
         data_title=data_title,
         network = "MD",
         expt_order = new_exp_names,
         conditions = conditions,
         plot_legend = True,
         ylim=ylim)

hemispheres = ["RH"]
data_title = "c. RH MD network"

indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

plot_data(ax=MD_fig_ax3,
         data=indiv_data, 
         data_title=data_title,
         network = "MD",
         expt_order = new_exp_names,
         conditions = conditions,
         plot_legend=True,
         ylim=ylim)


plt.savefig("../figures/MD_fig.tiff", bbox_inches = 'tight')  #bbox_inches tight gets rid of unnecessary white space on borders


# In[13]:


data_title = 'Average fROI response in the low-level speaking regions'
networks = ['lowlevel_speaking'] #which network to include in data
hemispheres = ["LH","RH"] #which hemisphere to include in data
ROIs = [1,3,4]


#read in the csv with all data
all_indiv_data = pd.read_csv('../../data/fMRI_all_indiv_production_data.csv')

experiment_names = ["E2","E2"]
new_exp_names = ["E2a","E2b"] #one to one correspondence with above list, replacement names

conditions = {"E2a": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"],
             "E2b": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"]
             }

criticalTasks = ["ProdLoc_spoken","ProdLoc_typed"] #target criticalTasks in the expts
consolidated_expt = None #expt that has consolidated data across all the experiments

#create layout for the full figure
fig = plt.figure(figsize=(50,12.5),constrained_layout=True)
gs1 = fig.add_gridspec(nrows=2, ncols=6, left=0.05, right=0.48, wspace=0.05)
#fig_ax1 = fig.add_subplot(gs1[0:3,1:5])

#indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

#plot_data(ax=fig_ax1,
#         data=indiv_data, 
#         data_title=data_title,
#         network = 'lowlevel_speaking',
#         expt_order = new_exp_names,
#         conditions = conditions,
#         main_brain = True,
#         plot_legend=True,
#         plot_labels=True,
#         plot_icons=True)

col_idx= [0,2,4]
row_idx= [0]

ylim = (0,5.3)

ROI_idx = 0
for row in row_idx:
    for col in col_idx:
        if(ROI_idx<len(ROIs)):
            fig_ax = fig.add_subplot(gs1[row:row+2,col:col+2])
            indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, [ROIs[ROI_idx]], conditions, criticalTasks, experiment_names, new_exp_names)
            #get name of ROI for plotting and to get correct brain image
            #print(indiv_data)
            ROI_name = "".join(pd.unique(indiv_data.ROI_name))
            brain_image = "../images/lowlevel_speaking_fROI_"+ROI_name+".png"
            ROI_name=""
            #hemi = "".join(pd.unique(indiv_data.Hemisphere))
            #ROI_name = ROI_name+ " ("+hemi+")"
            plot_data(ax=fig_ax,
                     data=indiv_data, 
                     data_title=ROI_name,
                     network = 'lowlevel_speaking',
                     brain_image = brain_image,
                     expt_order = new_exp_names,
                     conditions = conditions,
                     plot_labels = True,
                     plot_legend=True,
                     ylim=ylim)
        ROI_idx= ROI_idx+1
    
plt.savefig("../figures/lowlevel_speaking_fig.tiff", bbox_inches = 'tight')  


# In[14]:


data_title = 'Average fROI response in the low-level typing regions'
networks = ['lowlevel_typing'] #which network to include in data
hemispheres = ["LH","RH"] #which hemisphere to include in data
ROIs = [30,10,23,27,5]


#read in the csv with all data
all_indiv_data = pd.read_csv('../../data/fMRI_all_indiv_production_data.csv')

experiment_names = ["E2","E2"]
new_exp_names = ["E2a","E2b"] #one to one correspondence with above list, replacement names

conditions = {"E2a": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"],
             "E2b": ["SProd","WProd","NProd","VisEvSem","SComp","WComp"]
             }

criticalTasks = ["ProdLoc_spoken","ProdLoc_typed"] #target criticalTasks in the expts
consolidated_expt = None #expt that has consolidated data across all the experiments

#create layout for the full figure
fig = plt.figure(figsize=(50,25),constrained_layout=True)
gs1 = fig.add_gridspec(nrows=4, ncols=6, left=0.05, right=0.48, wspace=0.05)
#fig_ax1 = fig.add_subplot(gs1[0:3,1:5])

#indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, ROIs, conditions, criticalTasks, experiment_names, new_exp_names)

#plot_data(ax=fig_ax1,
#         data=indiv_data, 
#         data_title=data_title,
#         network = 'lowlevel_typing',
#         expt_order = new_exp_names,
#         conditions = conditions,
#         main_brain = True,
#         plot_legend=True,
#         plot_labels=True,
#         plot_icons=True)

col_idx= [0,2,4]
row_idx= [0,2]

ylim=(-0.8,5.3)
ROI_idx = 0
for row in row_idx:
    for col in col_idx:
        if(row>0):
            col = col+1 #shift second row of plots over so they are centered
        if(ROI_idx<len(ROIs)):
            fig_ax = fig.add_subplot(gs1[row:row+2,col:col+2])
            indiv_data = prep_data(all_indiv_data, consolidated_expt,networks, hemispheres, [ROIs[ROI_idx]], conditions, criticalTasks, experiment_names, new_exp_names)
            #get name of ROI for plotting and to get correct brain image
            #print(indiv_data)
            ROI_name = "".join(pd.unique(indiv_data.ROI_name))
            #hemi = "".join(pd.unique(indiv_data.Hemisphere))
            #ROI_name = ROI_name+ " ("+hemi+")"
            brain_image = "../images/lowlevel_typing_fROI_"+ROI_name+".png"
            ROI_name = ""
            plot_data(ax=fig_ax,
                     data=indiv_data, 
                     data_title=ROI_name,
                     brain_image = brain_image,
                     network = 'lowlevel_typing',
                     expt_order = new_exp_names,
                     conditions = conditions,
                     plot_labels = True,
                     plot_legend=True,
                     ylim=ylim)
        ROI_idx= ROI_idx+1
        
plt.savefig("../figures/lowlevel_typing_fig.tiff", bbox_inches = 'tight')  


# In[ ]:





# In[ ]:




