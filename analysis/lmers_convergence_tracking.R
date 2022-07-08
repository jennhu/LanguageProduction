library('EMAtools')
library('lme4')
library('lmerTest')
library('plyr')
library('tidyverse')
library('tibble')
library('optimx')

#testing convergence 
output_convergence_status <<- TRUE
optimizer <<- "" #just the default one other options -- #nloptwrap, bobyqa, nlminbwrap, "Nelder_Mead"
optCtrl <<- list() #use default other options -- #list(maxfun=2e4) #maxfun=2e4 ftol_abs=1e-12,xtol_abs=1e-12

add_param = ""
file_tag = paste(optimizer,add_param, sep="_")
filename = paste("convergence_tracking_outputs/convergence_tracking",file_tag,sep="_")
output_file <<- paste(filename,".csv",sep="")
if(output_convergence_status){
  #column headers for csv
  cat("network, fROI, cond1, cond1_src, cond2, cond2_src, warning_message\n", file=output_file, append = FALSE)
}


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
  expt1_prod_speakANDtype = filter(lang_data, Expt=="E1" & CriticalTask=="ProdLoc_spoken" & Speak_and_type==1),
  expt2_prod=filter(lang_data, Expt=="E2" & CriticalTask=="NameRead"), # new Exp2 = old Exp3
  expt2_langloc=filter(lang_data, Expt=="E2" & CriticalTask=="langloc"), # new Exp2 = old Exp3
  expt3_prod=filter(lang_data, Expt=="E3" & CriticalTask=="ProdLoc_typed"),
  expt3_langloc=filter(lang_data, Expt=="E1" & CriticalTask=="langloc" & Speak_and_type==1) # NOTE: same as old 2a langloc
)


# Replace *Prod with *Prod_typed in typing experiment (3) for easy analysis.
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
  
  print(levels(dfs[[name]]$Effect))
}
################################################################################
# DEFINE LMER MODELS
################################################################################
options(contrasts = c("contr.sum","contr.poly"))
# Fits the lmer and returns the p-value. 
fit_model <- function(model_data, model_type, plot=FALSE) {
  
  #print_newline <<- TRUE
  withCallingHandlers(
    #saves all warnings and messages generated during the fitting of the model to the output, if specified
    warning = function(w){
      if(output_convergence_status){
        #print the warning message in the fail_message column of output file and go to new line
        cat(conditionMessage(w), file=output_file, append=TRUE)
        #print_newline <<- FALSE
      }
    },
    message = function(m){
      if(output_convergence_status){
        #print the warning message in the fail_message column of output file and go to new line
        #this is catching boundary (singular) fit messages
        # occurs when one or more of the variance is zero
        cat(substr(conditionMessage(m),0,23), file=output_file, append=TRUE)
        #print_newline <<- FALSE
      }
      
    },
    #fitting the model happens while the warning and message handlers are active
    if (model_type == "network") {
      
      if(nchar(optimizer)==0){
        mixed.lmer <- lmer(EffectSize ~ Effect + (1|ROI) + (1|Subject), data=model_data)
      }else{
        mixed.lmer <- lmer(EffectSize ~ Effect + (1|ROI) + (1|Subject), data=model_data, 
                           control = lmerControl(optimizer = optimizer, optCtrl = optCtrl))
      }
      
    }
    else if (model_type == "separate_fROIs") {
  
      if(nchar(optimizer)==0){
        mixed.lmer <- lmer(EffectSize ~ Effect + (1|Subject), data=model_data)
      }else{
        mixed.lmer <- lmer(EffectSize ~ Effect + (1|Subject), data=model_data,
                           control = lmerControl(optimizer = optimizer, optCtrl = optCtrl))
      }
      
    }
    else {
      stop("model_type should be `network` or `separate_fROIs`")
    }
  )
  if(output_convergence_status){
    #go to new line once fitting of model is finished
    cat("\n",file=output_file,append=TRUE)
  }
  summary <- summary(mixed.lmer)
  #print(summary)
  # TODO: Figure out correct way to get p-values from fixation models.
  # the second line of results (idx =2) shows the results relative to the second line, so comparing the
  #two conditions -- I think this is right - HS
  p_value_idx <- 2
  p_value <- summary$coefficients[p_value_idx,5]
  cohen_d <- lme.dscore(mixed.lmer, model_data, type="lme4")$d
  
  if (plot) {
    plot(mixed.lmer)
    qqnorm(resid(mixed.lmer))
    qqline(resid(mixed.lmer))
  }
  #TODO: include beta values in an R output for the OSF page
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
  
  if(network == "lang")
    fROI = "1-6"
  else if(network == "MD")
    fROI = "1-20"
  if(output_convergence_status){
    output_status(cond1_src, cond2_src, cond1_name, cond2_name, network, fROI)
  }
  
  #print_newline <<- TRUE
  fit <- fit_model(model_data, "network")
  # tryCatch({
  #   fit <- fit_model(model_data, "network")
  # }, warning = function(w){
  #   if(output_convergence_status){
  #     #print the warning message in the fail_message column of output file and go to new line
  #     cat(paste(conditionMessage(w), "\n"), file=output_file, append=TRUE)
  #     print_newline <<- FALSE
  #   }
  # })
  # if(output_convergence_status & print_newline){
  #   #successfully converged, go to new line
  #   cat("\n",file=output_file,append=TRUE)
  # }
  p_value = fit$p
  cohen_d = fit$cohen_d
  row <- tibble_row(
    cond1=cond1_name, cond2=cond2_name, 
    expt_data=sprintf("%s/%s", cond1_src, cond2_src),
    ROI=fROI_str[[network]], network=network, p_value=p_value, cohen_d=cohen_d
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
    
    if(output_convergence_status){
      output_status(cond1_src, cond2_src, cond1_name, cond2_name, network, fROI)
    }
    
    cond1 <- filter(dfs[[cond1_src]], Effect==cond1_name & ROI==fROI)
    cond2 <- filter(dfs[[cond2_src]], Effect==cond2_name & ROI==fROI)
    model_data <- rbind(cond1,cond2)
    
    #print_newline <<- TRUE
    fit <- fit_model(model_data, "separate_fROIs")
    # tryCatch({
    #   fit <- fit_model(model_data, "separate_fROIs")
    # }, warning = function(w){
    #   if(output_convergence_status){
    #     #print the warning message in the fail_message column of output file and go to new line
    #     cat(paste(conditionMessage(w), "\n"), file=output_file, append=TRUE)
    #     print_newline <<- FALSE
    #   }
    # })
    # if(output_convergence_status & print_newline){
    #   #successfully converged, go to new line
    #   cat("\n",file=output_file,append=TRUE)
    # }
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

output_status <- function(cond1_src, cond2_src, 
                          cond1_name, cond2_name, network, fROI){
  cond1 <- paste(cond1_name, cond1_src, sep=", ")
  cond2 <- paste(cond2_name, cond2_src, sep=", ")
  both_conds <- paste(cond1, cond2, sep=", ")
  both_conds_fROI <- paste(fROI, both_conds, sep=", ")
  model <- paste(network, both_conds_fROI, sep=", ")
  cat(paste(model,", "),file=output_file,append=TRUE)
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

#data: Expt1, 2, 3 langloc & spWM (note: same for old 2a and 2b)

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
    # expt_data=sprintf("%s/%s", cond1_src, cond2_src),
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
langloc_data <- dfs_lang[names(dfs_lang) %in% c("expt1_langloc", "expt2_langloc")] # new 3 already included in 1
langloc_data <- bind_rows(langloc_data)
lang_sepfROI_results <- validate_fROIs(langloc_data, "S", "N", "lang")

# hard vs. easy spatial working memory (MD) ----
md_data <- dfs_MD_loc[names(dfs_MD_loc) %in% c("expt1_MD_loc", "expt2_MD_loc")] # new 3 already included in 1
md_data <- bind_rows(md_data)
md_sepfROI_results <- validate_fROIs(md_data, "H", "E", "MD")

write_csv(lang_sepfROI_results, "results/validation_lang.csv")
write_csv(md_sepfROI_results, "results/validation_md.csv")

################################################################################
# Q1: Does sentence production elicit a response in the language network?
################################################################################

#data: Expt1, 2 production & Expt1, 2 langloc
Q1_network_results <- initialize_tbl("network")
Q1_sepfROI_results <- initialize_tbl("separate_fROIs")

# SProd vs. fixation ----
cond1_name = "SProd"; cond2_name = "fixation"
for (expt in c("expt1", "expt2")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}

# SProd vs. nonwords (langloc) ----- 
cond1_name = "SProd"; cond2_name = "N"
for (expt in c("expt1", "expt2")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "langloc", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}

# SProd vs. VisEvSem ------ 
cond1_name = "SProd"; cond2_name = "VisEvSem"
for (expt in c("expt1")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name)
  Q1_network_results <- add_row(Q1_network_results, result$network)
  Q1_sepfROI_results <- bind_rows(Q1_sepfROI_results, result$separate_fROIs)
}

####################################################################################################
# Q2: Does the language network’s response to sentence production generalize across output modality?
####################################################################################################

# data: Expt 1,3 production & Expt1,3 langloc (subjects with both spoken and typed)
Q2_network_results <- initialize_tbl("network")
Q2_sepfROI_results <- initialize_tbl("separate_fROIs")

# SProd_typed vs. fixation ----
result <- fit_all_models("expt3_prod", "expt3_prod", "SProd_typed", "fixation")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_typed vs nonwords (langloc) ----
result <- fit_all_models("expt3_prod", "expt3_langloc", "SProd_typed", "N")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_typed vs VisEvSem ----
result <- fit_all_models("expt3_prod", "expt3_prod", "SProd_typed", "VisEvSem")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

# SProd_spoken vs. SProd_typed ----
result <- fit_all_models("expt3_prod", "expt1_prod_speakANDtype", "SProd_typed", "SProd")
Q2_network_results <- add_row(Q2_network_results, result$network)
Q2_sepfROI_results <- bind_rows(Q2_sepfROI_results, result$separate_fROIs)

####################################################################################################
# Q3: Does the language network respond to both lexical access and syntactic encoding?
####################################################################################################

# data: Expt1, 3 production, Expt 2
Q3_network_results <- initialize_tbl("network")
Q3_sepfROI_results <- initialize_tbl("separate_fROIs")

# WProd vs NProd ----
for (expt in c("expt1", "expt3")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  if (expt=="expt3") {
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
for (expt in c("expt1", "expt2", "expt3")) {
  cond1_src = paste(expt, "prod", sep="_")
  cond2_src = paste(expt, "prod", sep="_")
  if (expt=="expt3") {
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
for (expt in c("expt1", "expt2", "expt3")) {
  cond1_src = paste(expt, "MD_prod", sep="_")
  cond2_src = paste(expt, "MD_prod", sep="_")
  # Don't need to add *_typed for expt3 for MD data
  cond1_name = "SProd"; cond2_name = "WProd"
  result <- fit_all_models(cond1_src, cond2_src, cond1_name, cond2_name, network="MD")
  Q3_network_results <- add_row(Q3_network_results, result$network)
  Q3_sepfROI_results <- bind_rows(Q3_sepfROI_results, result$separate_fROIs)
  # Also compare SProd and NProd for Exp. 1 & 3 only.
  if (expt != "expt2") {
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