library('EMAtools')
library('lme4')
library('lmerTest')
library('plyr')
library('tidyverse')
library('tibble')

################################################################################
# LOAD AND CLEAN RAW DATA
################################################################################

# LH lang network fROIs: 1-6; no restrictions on MD for now
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
  expt2a_prod=filter(lang_data, Expt=="E2" & CriticalTask=="ProdLoc_spoken"), 
  expt2a_langloc=filter(lang_data, Expt=="E2" & CriticalTask=="langloc"), 
  expt2b_prod=filter(lang_data, Expt=="E2" & CriticalTask=="ProdLoc_typed"), 
  expt2b_langloc=filter(lang_data, Expt=="E2" & CriticalTask=="langloc"), # NOTE: same as 2a langloc
  expt3_prod=filter(lang_data, Expt=="E3" & CriticalTask=="NameRead"), 
  expt3_langloc=filter(lang_data, Expt=="E3" & CriticalTask=="langloc")
)

# Replace *Prod with *Prod_typed in typing experiment (2b) for easy analysis.
dfs_lang$expt2b_prod$Effect <- revalue(
  dfs_lang$expt2b_prod$Effect, 
  c("SProd"="SProd_typed", "WProd"="WProd_typed", "NProd"="NProd_typed")
)

# Construct list of dfs for MD network, named by experiment and task.
dfs_MD_prod <- list(
  expt1_MD_prod=filter(MD_data, Expt=="E1" & CriticalTask=="ProdLoc_spoken"),
  expt2a_MD_prod=filter(MD_data, Expt=="E2" & CriticalTask=="ProdLoc_spoken"),
  expt2b_MD_prod=filter(MD_data, Expt=="E2" & CriticalTask=="ProdLoc_typed"),
  expt3_MD_prod=filter(MD_data, Expt=="E3" & CriticalTask=="NameRead")
)

# Also get MD localizer contrasts for validation analyses.
dfs_MD_loc <- list(
  expt1_MD_loc=filter(MD_data, Expt=="E1" & CriticalTask=="spWM"),
  expt2_MD_loc=filter(MD_data, Expt=="E2" & CriticalTask=="spWM"), # same for 2a and 2b
  expt3_MD_loc=filter(MD_data, Expt=="E3" & CriticalTask=="spWM")
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
  
  print(levels(dfs[[name]]$Effect))
  }

################################################################################
# DEFINE LMER MODELS
################################################################################
options(contrasts = c("contr.sum","contr.poly"))
# Fits the lmer and returns the p-value. 
fit_model <- function(model_data, model_type, plot=FALSE) {
  if (model_type == "network") {
    mixed.lmer <- lmer(EffectSize ~ Effect + (1|ROI) + (1|Subject), data=model_data)
  }
  else if (model_type == "separate_fROIs") {
    mixed.lmer <- lmer(EffectSize ~ Effect + (1|Subject), data=model_data)
  }
  else {
    stop("model_type should be `network` or `separate_fROIs`")
  }
  summary <- summary(mixed.lmer)
  p_value_idx <- 2
  p_value <- summary$coefficients[p_value_idx,5]
  cohen_d <- lme.dscore(mixed.lmer, model_data, type="lme4")$d
  
  if (plot) {
    plot(mixed.lmer)
    qqnorm(resid(mixed.lmer))
    qqline(resid(mixed.lmer))
  }
  return(list(p=p_value, cohen_d=cohen_d))
}

# Returns row for results table based on model run on network with 
# fixed effect for condition and random intercepts for fROI and participant:
# Effect size ~ condition + (1 | ROI) + (1 | ID)
run_network_model <- function(cond1_src, cond2_src,
                              cond1_name, cond2_name, network="lang") {
  
  cond1 <- filter(dfs[[cond1_src]], Effect==cond1_name)
  cond2 <- filter(dfs[[cond2_src]], Effect==cond2_name)
  model_data <- rbind(cond1, cond2)

  fit <- fit_model(model_data, "network")
  row <- tibble_row(
    cond1=cond1_name, cond2=cond2_name, 
    expt_data=sprintf("%s/%s", cond1_src, cond2_src),
    ROI=fROI_str[[network]], network=network, p_value=fit$p, cohen_d=fit$cohen_d
  )
  return(row)
}

# Returns rows for results table based on model run on language network with 
# fixed effect for condition and random intercept for participant:
# Effect size ~ condition + (1 | ID)
run_separate_fROIs_model <- function(cond1_src, cond2_src, 
                                     cond1_name, cond2_name, network="lang") {
  raw_p_values <- list()
  effect_sizes <- list()
  for (fROI in fROIs[[network]]) {
    cond1 <- filter(dfs[[cond1_src]], Effect==cond1_name & ROI==fROI)
    cond2 <- filter(dfs[[cond2_src]], Effect==cond2_name & ROI==fROI)
    model_data <- rbind(cond1,cond2)

    fit <- fit_model(model_data, "separate_fROIs")
    raw_p_values <- append(raw_p_values, fit$p)
    effect_sizes <- append(effect_sizes, fit$cohen_d)
  }
  #FDR-correction
  adjusted_p_values <- p.adjust(raw_p_values, method="fdr")
  rows <- tibble(
    cond1=cond1_name,
    cond2=cond2_name, 
    expt_data=sprintf("%s/%s", cond1_src, cond2_src),
    ROI=fROIs[[network]], 
    p_value_uncorrected=unlist(raw_p_values), 
    p_value_fdr_corrected=adjusted_p_values,
    cohen_d=unlist(effect_sizes)
  )
  return(rows)
}

# Wrapper function that is actually called during the rest of the script.
# Simply use $network and $separate_fROIs on the result to get the
# relevant rows to add to the table.
fit_all_models <- function(...) {
  network_row <- run_network_model(...)
  separate_fROIs_rows <- run_separate_fROIs_model(...)
  result <- list(network=network_row, separate_fROIs=separate_fROIs_rows)
  return(result)
}

################################################################################
# HELPER FUNCTIONS
################################################################################

initialize_tbl <- function(model_type) {
  if (model_type == "network") {
    t <- tibble(cond1=character(), cond2=character(),
                expt_data=character(), ROI=character(),
                network=character(), p_value=double(),
                cohen_d=double())
  }
  else if (model_type == "separate_fROIs") {
    t <- tibble(cond1=character(), cond2=character(),
                expt_data=character(), ROI=integer(),
                p_value_uncorrected=double(), p_value_fdr_corrected=double(),
                cohen_d=double())
  }
  else {
    stop("model_type should be `network` or `separate_fROIs`")
  }
  return(t)
}

################################################################################
# SANITY CHECK: Validation of language and MD fROIs
################################################################################

#data: Expt1, 2a/2b, 3 langloc & spWM (note: same for 2a and 2b)

validate_fROIs <- function(loc_data, cond1_name, cond2_name, network) {
  raw_p_values <- list()
  effect_sizes <- list()
  for (fROI in fROIs[[network]]) {
    cond1 <- filter(loc_data, Effect==cond1_name & ROI==fROI)
    cond2 <- filter(loc_data, Effect==cond2_name & ROI==fROI)
    model_data <- rbind(cond1, cond2)
    fit <- fit_model(model_data, "separate_fROIs")
    raw_p_values <- append(raw_p_values, fit$p)
    effect_sizes <- append(effect_sizes, fit$cohen_d)
  }
  #FDR-correction
  adjusted_p_values <- p.adjust(raw_p_values, method="fdr")
  rows <- tibble(
    cond1=cond1_name,
    cond2=cond2_name, 
    expt_data=sprintf("%s/%s", cond1_src, cond2_src),
    ROI=fROIs[[network]], 
    p_value_uncorrected=unlist(raw_p_values), 
    p_value_fdr_corrected=adjusted_p_values,
    cohen_d=unlist(effect_sizes)
  )
  max_p <- max(rows$p_value_fdr_corrected)
  min_d <- min(abs(rows$cohen_d))
  print(sprintf(
    "Validation of %s fROIs: all p<%e; all |d|>%f", network, max_p, min_d
  ))
  return(rows)
}

# sentences vs. nonwords (langloc) ----- 
langloc_data <- dfs_lang[names(dfs_lang) %in% c("expt1_langloc", "expt2a_langloc", "expt3_langloc")]
langloc_data <- bind_rows(langloc_data)
lang_sepfROI_results <- validate_fROIs(langloc_data, "S", "N", "lang")

# hard vs. easy spatial working memory (MD) ----
md_data <- dfs_MD_loc[names(dfs_MD_loc) %in% c("expt1_MD_loc", "expt2a_MD_loc", "expt3_MD_loc")]
md_data <- bind_rows(md_data)
md_sepfROI_results <- validate_fROIs(md_data, "H", "E", "MD")

write_csv(lang_sepfROI_results, "results/validation_lang.csv")
write_csv(md_sepfROI_results, "results/validation_md.csv")

################################################################################
# Q1: Does sentence production elicit a response in the language network?
################################################################################

#data: Expt1, 2a, 3 production & Expt1, 2a, 3 langloc
Q1_network_results <- initialize_tbl("network")
Q1_sepfROI_results <- initialize_tbl("separate_fROIs")

# SProd vs. fixation ----
cond1_name = "SProd"; cond2_name = "fixation"
for (expt in c("expt1", "expt2a", "expt3")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}

# SProd vs. nonwords (langloc) ----- 
cond1_name = "SProd"; cond2_name = "N"
for (expt in c("expt1", "expt2a", "expt3")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "langloc", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}

# SProd vs. VisEvSem ------ 
cond1_name = "SProd"; cond2_name = "VisEvSem"
for (expt in c("expt1", "expt2a")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}
    
####################################################################################################
# Q2: Does the language network’s response to sentence production generalize across output modality?
####################################################################################################

# data: Expt2a,2b production & Expt2a,2b langloc
Q2_network_results <- initialize_tbl("network")
Q2_sepfROI_results <- initialize_tbl("separate_fROIs")

# SProd_typed vs. fixation ----
result <- fit_all_models("expt2b_prod", "expt2b_prod", "SProd_typed", "fixation")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_typed vs nonwords (langloc) ----
result <- fit_all_models("expt2b_prod", "expt2b_langloc", "SProd_typed", "N")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_typed vs VisEvSem ----
result <- fit_all_models("expt2b_prod", "expt2b_prod", "SProd_typed", "VisEvSem")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_spoken vs. SProd_typed ----
result <- fit_all_models("expt2b_prod", "expt2a_prod", "SProd_typed", "SProd")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)
    
####################################################################################################
# Q3: Does the language network respond to both lexical access and syntactic encoding?
####################################################################################################

# data: Expt1, 2a, 2b production, Expt 3
Q3_network_results <- initialize_tbl("network")
Q3_sepfROI_results <- initialize_tbl("separate_fROIs")

# WProd vs NProd ----
for (expt in c("expt1", "expt2a", "expt2b")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  if (expt=="expt2b") {
    cond1_name = "WProd_typed"; cond2_name = "NProd_typed"
  }
  else {
    cond1_name = "WProd"; cond2_name = "NProd"
  }
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q3_network_results <- add_row(Q3_network_results, result$network)
  Q3_sepfROI_results <- bind_rows(Q3_sepfROI_results, result$separate_fROIs)
}

# SProd vs. WProd ----
for (expt in c("expt1", "expt2a", "expt2b", "expt3")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  if (expt=="expt2b") {
    cond1_name = "SProd_typed"; cond2_name = "WProd_typed"
  }
  else {
    cond1_name = "SProd"; cond2_name = "WProd"
  }
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q3_network_results <- add_row(Q3_network_results, result$network)
  Q3_sepfROI_results <- bind_rows(Q3_sepfROI_results, result$separate_fROIs)
}

# MD network data ----
for (expt in c("expt1", "expt2a", "expt2b", "expt3")) {
  cond1_src = paste(expt, "MD_prod", sep="_")
  cond2_src = paste(expt, "MD_prod", sep="_")
  # Don't need to add *_typed for expt2b for MD data
  cond1_name = "SProd"; cond2_name = "WProd"
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name, network="MD")
  Q3_network_results <- add_row(Q3_network_results, result$network)
  Q3_sepfROI_results <- bind_rows(Q3_sepfROI_results, result$separate_fROIs)
  # Also compare SProd and NProd for Exp. 1 & 2 only.
  if (expt != "expt3") {
    cond1_name = "SProd"; cond2_name = "NProd"
    result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name, network="MD")
    Q3_network_results <- add_row(Q3_network_results, result$network)
    Q3_sepfROI_results <- bind_rows(Q3_sepfROI_results, result$separate_fROIs)
  }
}

################################################################################
# PROCESSING FINAL RESULTS
################################################################################

# Save all resulting tables to CSV files.
write_csv(Q1_network_results, "results/Q1_network.csv")
write_csv(Q2_network_results, "results/Q2_network.csv")
write_csv(Q3_network_results, "results/Q3_network.csv")
write_csv(Q1_sepfROI_results, "results/Q1_sepfROIs.csv")
write_csv(Q2_sepfROI_results, "results/Q2_sepfROIs.csv")
write_csv(Q3_sepfROI_results, "results/Q3_sepfROIs.csv")

################################################################################
# CORRELATION BETWEEN TYPING OUTPUT AND LANG NETWORK RESPONSES
################################################################################

# First, check whether SProd>WProd effects are stable within individuals.
SProd <- filter(dfs[["expt2b_prod"]], Effect=="SProd_typed")
WProd <- filter(dfs[["expt2b_prod"]], Effect=="WProd_typed")
SProd$WProd_EffectSize <- WProd$EffectSize[match(SProd$Subject, WProd$Subject)]
SProd$SProd_minus_WProd_EffectSize <- SProd$EffectSize - SProd$WProd_EffectSize

# Next, check reliability of typing measure.
typ <- read.csv("../data/all_SPROD_annotated_data_20201210.csv")
typ <- filter(typ, Response!="Unintelligible", Response!="0") 
typ[typ=="NA" | typ=="?" | typ=="Unknown" | typ=="Incomplete"] <- 0
typ[is.na(typ)] <- 0
typ$Number_well_formed_elements <- 
  as.numeric(typ$Subject_is_Well_Formed) + 
  as.numeric(typ$Verb_is_Well_Formed) + 
  as.numeric(typ$Post.Verb_is_Well_Formed)
# Get by-subject means for typing measure, within EVEN and ODD runs (or trials).
typ_means.e <- typ %>% 
  filter(Run %% 2 == 0) %>%
  group_by(SubjID) %>%
  summarise(num_well_formed=mean(Number_well_formed_elements))
typ_means.o <- typ %>% 
  filter(Run %% 2 == 1) %>%
  group_by(SubjID) %>%
  summarise(num_well_formed=mean(Number_well_formed_elements))
test <- cor.test(typ_means.e$num_well_formed, typ_means.o$num_well_formed, method="pearson")
print(sprintf("p=%f, Pearson r=%f", test$p.value, test$estimate))

# Get by-subject means for typing measure (across all runs).
typ_means <- typ %>%
  group_by(SubjID) %>%
  summarise(num_well_formed=mean(Number_well_formed_elements))
typ_means$even <- typ_means.e$num_well_formed[match(typ_means$SubjID, typ_means.e$SubjID)]
typ_means$odd <- typ_means.o$num_well_formed[match(typ_means$SubjID, typ_means.o$SubjID)]

# Plot even vs. odd, as a sanity check.
ggplot(data=typ_means, aes(x=even, y=odd)) +
  geom_point() +
  geom_smooth(method=lm) +
  labs(x="# well-formed elements (EVEN runs)", y="# well-formed elements (ODD runs)")

# Finally, check relationship between typing measure and SProd>WProd effect size.
# NOTE: Subject and SubjID are coded slightly differently, so chop off the prefix and suffix.
SProd$SubjID <- substring(SProd$Subject, 5, 21)
# Get means across ROIs.
roi_means <- SProd %>%
  group_by(SubjID) %>%
  summarise(SProd_minus_WProd_EffectSize=mean(SProd_minus_WProd_EffectSize))
roi_means$mean_num_well_formed <- typ_means$num_well_formed[match(roi_means$SubjID, typ_means$SubjID)]
# Check whether there is a correlation.
test <- cor.test(roi_means$mean_num_well_formed, roi_means$SProd_minus_WProd_EffectSize, method="pearson")
print(sprintf("p=%f, Pearson r=%f", test$p.value, test$estimate))
# Plot typing well-formedness vs. SProd>WProd effect.
ggplot(data=roi_means, aes(x=mean_num_well_formed, y=SProd_minus_WProd_EffectSize)) +
  geom_point(size=3) +
  geom_smooth(method=lm) +
  labs(x="# well-formed elements", y="SProd - WProd effect size") +
  theme_classic(base_size = 20)
# Save figure.
ggsave("../figures/figures/wellformed_vs_SProd-WProd.pdf", width=5, height=4)
