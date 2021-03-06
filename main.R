# First load and install the following packages which we will need for data cleaning and analysis.

requiredPackages = c(
  'plyr',
  'tidyverse',
  'data.table',
  'pbapply', 
  'ggthemes',
  'splines',
  'parallel'
)
for (p in requiredPackages) {
  if (!require(p, character.only = TRUE))
    install.packages(p)
  library(p, character.only = TRUE)
}

# We will need several functions which can be found in \scripts\General analysis functions.R

source("./scripts/general_analysis_functions.R")

# The data for this analysis can be obtained by application to the Scientific Registry of Transplant Recipients
# We need to clean the data using the code in \scripts\data cleaning.R
# The data cleaning step will save a file called candidates_analysis.RData in the current directory
# which can be loaded later instead of repeating the data cleaning 

source("./scripts/data_cleaning.R")

# To view the data for a random sample of 5000 individuals:

candidates_analysis %>% 
  filter(patient_id %in% sample(unique(candidates_analysis$patient_id), 5000, replace=F)) %>% 
  View()

# Now we define the multiplicative increase in living donor utilization

q = 1 #non negative multiplicative factor

# We can estimate and plot the 'standard risk' and 'increased risk' graft utilization
# under this strategy
  
resultstransplant <- lapply(c("transplant_and_living_donor","transplant_and_deceased_donor"), function(i) 
    resultsfnctransplant(
      candidates_analysis,
      baseline_covariates = list("ns(baseline_MELD,knots=quantile(baseline_MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(baseline_MELD, probs=c(0.05,0.95)))", 
                                 "baseline_MELD_exception", "status1", "gender", "race", "year_of_listing",
                                 "ns(age,knots=quantile(age,probs=c(0.35,0.65)), Boundary.knots=quantile(age, probs=c(0.05,0.95)))", 
                                 "ns(height,knots=quantile(height,probs=c(0.35,0.65)), Boundary.knots=quantile(height, probs=c(0.05,0.95)))", 
                                 "ns(weight,knots=quantile(weight,probs=c(0.35,0.65)), Boundary.knots=quantile(weight, probs=c(0.05,0.95)))",
                                 "accept_incompatible_blood_type", "accept_extra_corporeal_liver", "accept_liver_segment",
                                 "accept_HBV_positive_donor", "accept_HCV_positive_donor",
                                 "patient_on_life_support", "functional_status", "primary_diagnosis", "spontaneous_bacterial_peritonitis",
                                 "history_of_PV_thrombosis", "history_of_TIPSS"),
      time_varying_covariates_transplant = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                                MELD_exception*
                                                ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
      time_varying_covariates_censoring = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                               MELD_exception*
                                               ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))",
                                               "post_transplant*
                                               ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
      transplant_var = i,
      living_donor_usage_factor = q,
      summary_only = F
      ))

# plot the 'standard risk' graft utilization

ggplot(data=resultstransplant[1] %>% as.data.frame(), 
       aes(x=days_since_start, y=num_grafts_used)) + geom_line(size=1.25) + 
  xlab("Days since waitlisted")  + ylab("Number of transplants") + 
  theme_tufte() + scale_x_continuous(breaks=seq(0, 3660, 300)) +
  ggtitle("(A) Utilization of 'living donor' grafts") +
  theme(axis.line.x = element_line(color="black", size = 0.5),
        axis.line.y = element_line(color="black", size = 0.5),
        text=element_text(size=18))

# plot the 'increased risk' graft utilization

ggplot(data=resultstransplant[2] %>% as.data.frame(), 
       aes(x=days_since_start, y=num_grafts_used)) + geom_line(size=1.25) + 
  xlab("Days since waitlisted")  + ylab("Number of transplants") + 
  theme_tufte() + scale_x_continuous(breaks=seq(0, 3660, 300)) +
  ggtitle("(B) Utilization of 'deceased donor' grafts") +
  theme(axis.line.x = element_line(color="black", size = 0.5),
        axis.line.y = element_line(color="black", size = 0.5),
        text=element_text(size=18))

# Now, we estimate the survival under this strategy

results <- resultsfnc(
  candidates_analysis,
  baseline_covariates = list("ns(baseline_MELD,knots=quantile(baseline_MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(baseline_MELD, probs=c(0.05,0.95)))", 
                             "baseline_MELD_exception", "status1", "gender", "race", "year_of_listing",
                             "ns(age,knots=quantile(age,probs=c(0.35,0.65)), Boundary.knots=quantile(age, probs=c(0.05,0.95)))", 
                             "ns(height,knots=quantile(height,probs=c(0.35,0.65)), Boundary.knots=quantile(height, probs=c(0.05,0.95)))", 
                             "ns(weight,knots=quantile(weight,probs=c(0.35,0.65)), Boundary.knots=quantile(weight, probs=c(0.05,0.95)))",
                             "accept_incompatible_blood_type", "accept_extra_corporeal_liver", "accept_liver_segment",
                             "accept_HBV_positive_donor", "accept_HCV_positive_donor",
                             "patient_on_life_support", "functional_status", "primary_diagnosis", "spontaneous_bacterial_peritonitis",
                             "history_of_PV_thrombosis", "history_of_TIPSS"),
  time_varying_covariates_transplant = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                            MELD_exception*
                                            ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
  time_varying_covariates_censoring = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                           MELD_exception*
                                           ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))",
                                           "post_transplant*
                                           ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
  living_donor_usage_factor = q,
  summary_only = F
)

# and plot the survival curves

ggplot(data=results, 
       aes(x=days_since_start, y=CI)) + geom_line(size=1.25) + 
  xlab("Days since waitlisted")  + ylab("Cumulative incidence of death") + 
  theme_tufte() + scale_x_continuous(breaks=seq(0, 3660, 300)) +
  theme(axis.line.x = element_line(color="black", size = 0.5),
        axis.line.y = element_line(color="black", size = 0.5),
        text=element_text(size=18))

# An estimate of the 95% confidence interval for 10-year survival can be obtained using a percentile bootstrap

bootstrap_results <-
  pbreplicate(
    500,
    bootstrapfnc(
      candidates_analysis,
      baseline_covariates = list("ns(baseline_MELD,knots=quantile(baseline_MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(baseline_MELD, probs=c(0.05,0.95)))", 
                                 "baseline_MELD_exception", "status1", "gender", "race", "year_of_listing",
                                 "ns(age,knots=quantile(age,probs=c(0.35,0.65)), Boundary.knots=quantile(age, probs=c(0.05,0.95)))", 
                                 "ns(height,knots=quantile(height,probs=c(0.35,0.65)), Boundary.knots=quantile(height, probs=c(0.05,0.95)))", 
                                 "ns(weight,knots=quantile(weight,probs=c(0.35,0.65)), Boundary.knots=quantile(weight, probs=c(0.05,0.95)))",
                                 "accept_incompatible_blood_type", "accept_extra_corporeal_liver", "accept_liver_segment",
                                 "accept_HBV_positive_donor", "accept_HCV_positive_donor",
                                 "patient_on_life_support", "functional_status", "primary_diagnosis", "spontaneous_bacterial_peritonitis",
                                 "history_of_PV_thrombosis", "history_of_TIPSS"),
      time_varying_covariates_transplant = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                                MELD_exception*
                                                ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
      time_varying_covariates_censoring = list("ns(MELD,knots=quantile(MELD,probs=c(0.35,0.65)), Boundary.knots=quantile(MELD, probs=c(0.05,0.95)))*
                                               MELD_exception*
                                               ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))",
                                               "post_transplant*
                                               ns(days_since_start, knots = c(60,120,360,720,1620), Boundary.knots = c(30,3600))"),
      living_donor_usage_factor = q,
      summary_only = T
      )
    )

# get the 2.5th and 97.5th percentiles

bootstrap_results %>% quantile(., c(0.025,0.975))
