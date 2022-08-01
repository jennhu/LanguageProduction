library('EMAtools')
library('lme4')
library('lmerTest')
library('plyr')
library('tidyverse')
library('tibble')
library('optimx')

################################################################################
# LOAD AND CLEAN RAW DATA
################################################################################

# LH lang network fROIs: 1-6; no restrictions on MD for now
# TODO: determine whether to just use LH for MD (ROI<=10)
# Ev said we might report full network results in paper and report LH and RH in SI?
fROIs <- list(lang=1:6, MD=1:20)
fROI_str <- list(lang="1-6", MD="1-20")

# Load all data from experiments 1, 2a, 2b, 3.
all_data <- read.csv("../data/fMRI_all_indiv_production_data.csv")
lang_data <- filter(all_data, Network=="lang" & ROI %in% fROIs$lang)
MD_data <- filter(all_data, Network=="MD" & ROI %in% fROIs$MD)

# Construct list of dfs for lang network, named by experiment and task.
dfs_lang <- list(
  expt1_prod=filter(lang_data, Expt=="E1" & CriticalTask=="ProdLoc_spoken"),
  expt1_langloc=filter(lang_data, Expt=="E1" & CriticalTask=="langloc"),
  expt1_prod_speakANDtype = filter(lang_data, Expt=="E1" & CriticalTask=="ProdLoc_spoken" & Speak_and_type==1),
  expt2_prod=filter(lang_data, Expt=="E2" & CriticalTask=="NameRead"), # new Exp2 = old Exp3
  expt2_langloc=filter(lang_data, Expt=="E2" & CriticalTask=="langloc"), # new Exp2 = old Exp3
  expt3_prod=filter(lang_data, Expt=="E3" & CriticalTask=="ProdLoc_typed"),
  expt3_langloc=filter(lang_data, Expt=="E1" & CriticalTask=="langloc" & Speak_and_type==1) # NOTE: same as old 2a langloc
)# Replace *Prod with *Prod_typed in typing experiment (3) for easy analysis.
dfs_lang$expt3_prod$Effect <- revalue(
  dfs_lang$expt3_prod$Effect, 
  c("SProd"="SProd_typed", "WProd"="WProd_typed", "NProd"="NProd_typed")
)

# Construct list of dfs for MD network, named by experiment and task.
dfs_MD_prod <- list(
  expt1_MD_prod=filter(MD_data, Expt=="E1" & CriticalTask=="ProdLoc_spoken"),
  expt2_MD_prod=filter(MD_data, Expt=="E2" & CriticalTask=="NameRead"),
  expt3_MD_prod=filter(MD_data, Expt=="E3" & CriticalTask=="ProdLoc_typed")
)

# Also get MD localizer contrasts for validation analyses.
dfs_MD_loc <- list(
  expt1_MD_loc=filter(MD_data, Expt=="E1" & CriticalTask=="spWM"),
  expt2_MD_loc=filter(MD_data, Expt=="E2" & CriticalTask=="spWM"), 
  expt3_MD_loc=filter(MD_data, Expt=="E1" & CriticalTask=="spWM" & Speak_and_type==1)
)

# Combine all data into `dfs`.
dfs <- c(dfs_lang, dfs_MD_prod, dfs_MD_loc)
names <- names(dfs)


for (ind in 1:length(dfs)) {
  name = names[ind]
  
  # add fixation condition for every participant. The EffectSize is 0, since the fixation baseline has already been 
  # subtracted out of all other conditions (coded as 'Effect')
  fixation_df <- dfs[[ind]]
  fixation_df['Effect'] <- "fixation"
  fixation_df['EffectSize'] <- 0
  fixation_df <- unique(fixation_df)
  dfs[[name]] = rbind(dfs[[name]], fixation_df)
  
  #make sure ROI is read as a factor, not an integer
  dfs[[name]]$ROI = factor(dfs[[name]]$ROI)
  
  #reorder levels of Effects
  #dfs[[name]]$Effect = factor(dfs[[name]]$Effect, levels=c("S","SProd","SProd_typed","WProd","WProd_typed","NProd","NProd_typed","N","SComp","WComp","VisEvSem","H","E","fixation"),ordered = TRUE)
  dfs[[name]]$Effect = factor(dfs[[name]]$Effect, levels=c("fixation","E","H","VisEvSem","WComp","SComp","N","NProd_typed","NProd","WProd_typed","WProd","SProd_typed","SProd","S"),ordered = TRUE)
}

################################################################################
# DEFINE LMER MODELS
################################################################################
options(contrasts = c("contr.sum","contr.poly"))


#did not converge in lmers_convergence_tracking.R
cond1_name = "SProd_typed"; cond1_src = "expt3_prod"
cond2_name = "fixation"; cond2_src = "expt3_prod"
fROI = 4
cond1 <- filter(dfs[[cond1_src]], Effect==cond1_name & ROI==fROI)
cond2 <- filter(dfs[[cond2_src]], Effect==cond2_name & ROI==fROI)
model_data <- rbind(cond1,cond2)

mixed.lmer <- lmer(EffectSize ~ Effect + (1|Subject), data=model_data)
cohen_d <- lme.dscore(mixed.lmer, model_data, type="lme4")

mixed.lmer.all <- allFit(mixed.lmer)
ss1 <- summary(mixed.lmer.all)
## all good, all values are the same for the different algorithms (see ss1 and ss2)


#did not converge in lmers_convergence_tracking.R
cond1_name = "SProd_typed"; cond1_src = "expt3_prod"
cond2_name = "fixation"; cond2_src = "expt3_prod"
fROI = 6
cond1 <- filter(dfs[[cond1_src]], Effect==cond1_name & ROI==fROI)
cond2 <- filter(dfs[[cond2_src]], Effect==cond2_name & ROI==fROI)
model_data <- rbind(cond1,cond2)

mixed.lmer <- lmer(EffectSize ~ Effect + (1|Subject), data=model_data)
cohen_d <- lme.dscore(mixed.lmer, model_data, type="lme4")

mixed.lmer.all <- allFit(mixed.lmer)
ss2 <- summary(mixed.lmer.all)
## all good, all values are the same for the different algorithms (see ss1 and ss2)

    
  
  

