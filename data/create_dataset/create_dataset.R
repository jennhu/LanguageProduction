library('plyr')
library('tidyverse')
library('tibble')

load <- function(mean_data, expt_id, network_id, localizer_contrast, task, speak_and_type, prefix) {
  if(mean_data){
    #load the summary mean effect size file
    message(sprintf("toolbox_output/%s_spm_ss_mROI_data.summaries.EffectSize.csv", prefix))
    data = read.csv(sprintf("toolbox_output/%s_spm_ss_mROI_data.summaries.EffectSize.csv", prefix))
  }else{
    message(sprintf("toolbox_output/%s_spm_ss_mROI_data.csv", prefix))
    data = read.csv(sprintf("toolbox_output/%s_spm_ss_mROI_data.csv", prefix))
    
  }
  
  #recoding some conditions
  data$Effect <- revalue(data$Effect, c("Artic"="NProd", "EvSem"="VisEvSem", "NEv"="SProd", "NOb"="WProd"))
  data <- data %>% subset(!(data$Effect == "ROb" | data$Effect == "REv")) #take out these conditions, we don't use them
  #add ROI names to the data
  if(network_id == "lang"){
    ROI_names = c('IFGorb', 'IFG', 'MFG', 'AntTemp', 'PostTemp', 'AngG')
    ROI_names = c(ROI_names,ROI_names)
    all_ROIs = c(1:12)
    left_ROIs = c(1:6)
  }
  if(network_id == "MD"){
    #slightly different structure for MD
    #recode the ROI to integers, to fit with the rest of the processing the rest of the data
    data$ROI <- as.factor(revalue(data$ROI, c('LH_postParietal'=1,'LH_midParietal'=2,'LH_antParietal'=3,'LH_supFrontal'=4,'LH_Precentral_A_precG'=5,
                                       'LH_Precentral_B_IFGop'=6, 'LH_midFrontal'=7, 'LH_midFrontalOrb'=8,'LH_insula'=9,'LH_medialFrontal'=10,
                                       'RH_postParietal'=11,'RH_midParietal'=12,'RH_antParietal'=13,'RH_supFrontal'=14,'RH_Precentral_A_precG'=15,
                                       'RH_Precentral_B_IFGop'=16, 'RH_midFrontal'=17, 'RH_midFrontalOrb'=18,'RH_insula'=19,'RH_medialFrontal'=20)))
    
    data$ROI <- as.numeric(levels(data$ROI))[data$ROI]
    
    ROI_names = c('PostParietal','midParietal','antParietal','supFrontal','Precentral_A_PrecG', 'Precentral_B_IFGop', 'midFrontal', 'midFrontalOrb','insula','medialFrontal')
    ROI_names = c(ROI_names,ROI_names)
    all_ROIs = c(1:20)
    left_ROIs = c(1:10)
    
  }
  if(network_id == "lowlevel_speaking"){
    ROI_names = c('1','3','4')
    all_ROIs = c(1,3,4)
    left_ROIs = c(1,3)
  }
  if(network_id == "lowlevel_typing"){
    ROI_names = c('30','10','23','27','5')
    all_ROIs = c(30,10,23,27,5)
    left_ROIs = c(30,10,23)
  }
  #filter out unwanted ROIs
  data <- data %>% filter(ROI %in% all_ROIs)
  
  #add identifying information
  data <- data %>% mutate(Expt = expt_id,
                          Network = network_id,
                          Localizer_contrast = localizer_contrast,
                          CriticalTask = task,
                          ROI_name = ROI_names[match(ROI,all_ROIs)],
                          Speak_and_type = speak_and_type,
                          Hemisphere = if_else(ROI %in% left_ROIs, "LH","RH"))

  
  return(data)
}

#2022-07-08 -HS editing for the reframing of the paper (reorganizing the experiments so that E1 has all spoken 6 condition participants, E2 has the nameread experiment, and E3 is typing)

mean_data = TRUE
all_dfs_mean <- list(
                E1_lang_lang = load(mean_data,"E1","lang","S>N","langloc",0,'expt1_mROI_n15_langlocSNfROIs_langloc_wo_typingEFFECT_20201103'),
                E1_lang_prod = load(mean_data,"E1","lang","S>N","ProdLoc_spoken",0,'expt1_mROI_n15_langlocSNfROIs_ProdLoc_wo_typing_EFFECT_20201103'),
                E2_lang_lang = load(mean_data,"E1","lang","S>N","langloc",1,'expt2_mROI_n14_langlocSNfROIs_langloc_w_typingEFFECT_20201103'),
                E2_lang_prod = load(mean_data,"E1","lang","S>N","ProdLoc_spoken",1,'expt2a_mROI_n14_langlocSNfROIs_ProdLoc_w_typingEFFECT_20201103'),
                E2_lang_prod = load(mean_data,"E3","lang","S>N","ProdLoc_typed",1,'expt2b_mROI_n14_langlocSNfROIs_ProdLoc_typingEFFECT_20201103'),
                E3_lang_lang = load(mean_data,"E2","lang","S>N","langloc",0,'expt3_mROI_n12_lang_fROIs_lang_EFFECT_20201103'),
                E3_lang_prod = load(mean_data,"E2","lang","S>N","NameRead",0,'expt3_mROI_n12_lang_fROIs_nameread_EFFECT_20201103'),
                E1_MD_spWM = load(mean_data,"E1","MD","H>E","spWM",0,'expt1_mROI_n14_spWM_HEfROIs_spWM_wo_typing_EFFECT_20201103'),
                E1_MD_prod = load(mean_data,"E1","MD","H>E","ProdLoc_spoken",0,'expt1_mROI_n14_spWM_HEfROIs_ProdLoc_wo_typing_EFFECT_20201103'),
                E2_MD_spWM = load(mean_data,"E1", "MD","H>E","spWM",1, 'expt2_mROI_n14_spWM_HEfROIs_spWM_w_typingEFFECT_20201103' ),
                E2_MD_prod = load(mean_data,"E1","MD","H>E","ProdLoc_spoken",1,'expt2a_mROI_n14_spWM_HEfROIs_ProdLoc_w_typingEFFECT_20201103'),
                E2_MD_prod = load(mean_data,"E3","MD","H>E","ProdLoc_typed",1,'expt2b_mROI_n14_spWM_HEfROIs_ProdLoc_typingEFFECT_20201103'),
                E3_MD_spWM = load(mean_data,"E2","MD","H>E","spWM",0,'expt3_mROI_n11_spWM_HEfROIs_spWM_EFFECT_20201103'),
                E3_MD_prod = load(mean_data,"E2","MD","H>E","NameRead",0,'expt3_mROI_n11_spWM_HEfROIs_nameread_EFFECT_20201103'),
                E2_lowlevel_speaking_prodSpoken = load(mean_data,"E1","lowlevel_speaking","NProd>Fix","ProdLoc_spoken",1,'expt2_mROI_n14_ProdLoc_ArticfROIs_ProdLocEFFECT_20201103'),
                E2_lowlevel_speaking_prodTyped = load(mean_data,"E1","lowlevel_speaking","NProd>Fix","ProdLoc_typed",1,'expt2_mROI_n14_ProdLoc_ArticfROIs_ProdLoc_typingEFFECT_20201103'),
                E2_lowlevel_typing_prodSpoken = load(mean_data, "E3","lowlevel_typing","NProd>Fix","ProdLoc_spoken",1,'expt2_mROI_n14_ProdLoc_typing_ArticfROIs_ProdLocEFFECT_20201103'),
                E2_lowlevel_typing_prodTyped = load(mean_data, "E3","lowlevel_typing","NProd>Fix","ProdLoc_typed",1,'expt2_mROI_n14_ProdLoctyp_ArticfROIs_ProdLoctypEFFECT_20201103')
)
#2022-07-08 -HS editing for the reframing of the paper (reorganizing the experiments)

#individual, not mean data
mean_data = FALSE;
all_dfs_indiv <- list(
  E1_lang_lang = load(mean_data,"E1","lang","S>N","langloc",0,'expt1_mROI_n15_langlocSNfROIs_langloc_wo_typingEFFECT_20201103'),
  E1_lang_prod = load(mean_data,"E1","lang","S>N","ProdLoc_spoken",0,'expt1_mROI_n15_langlocSNfROIs_ProdLoc_wo_typing_EFFECT_20201103'),
  E2_lang_lang = load(mean_data,"E1","lang","S>N","langloc",1,'expt2_mROI_n14_langlocSNfROIs_langloc_w_typingEFFECT_20201103'),
  E2_lang_prod = load(mean_data,"E1","lang","S>N","ProdLoc_spoken",1,'expt2a_mROI_n14_langlocSNfROIs_ProdLoc_w_typingEFFECT_20201103'),
  E2_lang_prod = load(mean_data,"E3","lang","S>N","ProdLoc_typed",1,'expt2b_mROI_n14_langlocSNfROIs_ProdLoc_typingEFFECT_20201103'),
  E3_lang_lang = load(mean_data,"E2","lang","S>N","langloc",0,'expt3_mROI_n12_lang_fROIs_lang_EFFECT_20201103'),
  E3_lang_prod = load(mean_data,"E2","lang","S>N","NameRead",0,'expt3_mROI_n12_lang_fROIs_nameread_EFFECT_20201103'),
  E1_MD_spWM = load(mean_data,"E1","MD","H>E","spWM",0,'expt1_mROI_n14_spWM_HEfROIs_spWM_wo_typing_EFFECT_20201103'),
  E1_MD_prod = load(mean_data,"E1","MD","H>E","ProdLoc_spoken",0,'expt1_mROI_n14_spWM_HEfROIs_ProdLoc_wo_typing_EFFECT_20201103'),
  E2_MD_spWM = load(mean_data,"E1", "MD","H>E","spWM",1, 'expt2_mROI_n14_spWM_HEfROIs_spWM_w_typingEFFECT_20201103' ),
  E2_MD_prod = load(mean_data,"E1","MD","H>E","ProdLoc_spoken",1,'expt2a_mROI_n14_spWM_HEfROIs_ProdLoc_w_typingEFFECT_20201103'),
  E2_MD_prod = load(mean_data,"E3","MD","H>E","ProdLoc_typed",1,'expt2b_mROI_n14_spWM_HEfROIs_ProdLoc_typingEFFECT_20201103'),
  E3_MD_spWM = load(mean_data,"E2","MD","H>E","spWM",0,'expt3_mROI_n11_spWM_HEfROIs_spWM_EFFECT_20201103'),
  E3_MD_prod = load(mean_data,"E2","MD","H>E","NameRead",0,'expt3_mROI_n11_spWM_HEfROIs_nameread_EFFECT_20201103'),
  E2_lowlevel_speaking_prodSpoken = load(mean_data,"E1","lowlevel_speaking","NProd>Fix","ProdLoc_spoken",1,'expt2_mROI_n14_ProdLoc_ArticfROIs_ProdLocEFFECT_20201103'),
  E2_lowlevel_speaking_prodTyped = load(mean_data,"E1","lowlevel_speaking","NProd>Fix","ProdLoc_typed",1,'expt2_mROI_n14_ProdLoc_ArticfROIs_ProdLoc_typingEFFECT_20201103'),
  E2_lowlevel_typing_prodSpoken = load(mean_data, "E3","lowlevel_typing","NProd>Fix","ProdLoc_spoken",1,'expt2_mROI_n14_ProdLoc_typing_ArticfROIs_ProdLocEFFECT_20201103'),
  E2_lowlevel_typing_prodTyped = load(mean_data, "E3","lowlevel_typing","NProd>Fix","ProdLoc_typed",1,'expt2_mROI_n14_ProdLoctyp_ArticfROIs_ProdLoctypEFFECT_20201103')
)

big_data_mean = dplyr::bind_rows(all_dfs_mean)
big_data_indiv = dplyr::bind_rows(all_dfs_indiv)

write_csv(big_data_mean, "../fMRI_all_production_data_summaryMeanEffectSize.csv")
write_csv(big_data_indiv, "../fMRI_all_indiv_production_data.csv")


