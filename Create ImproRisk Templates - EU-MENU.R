
##### This script creates the templates for ImproRisk ####

# It creates 2 templates: 
# a) General Population - consumption of pregnant women is removed
# b) Pregnant women
# 
# You need the following:
# a) a vector of the pregnant women EFSA ids (ORSUBCODE) 
#    named `preg_women_ids`
#    !#read_rds("preg_women_ids.rds")!
# b) SUBJECTS.xlsx file
# c) CONSUMPTION MAPPED file from fdx2 to fdx1 for all subjects


# Load the PACKAGES #### 
# [install the packages if not on your machine
# via install.pagkages("package_name")]

library(tidyverse)
library(readxl)
library(writexl)

# we need the consumption data
consumption_mapped = readxl::read_xlsx("Consumption_EUMENU_mapped_fdx2_fdx1 ALL SUBJECTS.xlsx")

# and the pregnant women ids. We have them save in an RDS object
preg_women_ids = read_rds("preg.rds")

# get the ids of subjects that have only one 1 day in the survey
ids_to_remove = 
  consumption_mapped %>% 
  group_by(ORSUBCODE) %>% 
  summarise(days_in_survey = max(DAY)) %>%
  filter(days_in_survey<2) %>% pull(ORSUBCODE)


# remove subjects with less than 2 days in the survey
consumption_mapped = 
  consumption_mapped %>% 
  filter(!ORSUBCODE %in% ids_to_remove)

# To get the Lot1 and Lot2 ids do the following
  Lot1_ids = consumption_mapped %>%
    filter(str_detect(SURVEY, "Lot1")) %>%
    pull(ORSUBCODE) %>% unique()
  
  Lot2_ids = consumption_mapped %>%
    filter(str_detect(SURVEY, "Lot2")) %>%
    pull(ORSUBCODE) %>% unique()

# Create the Consumption Worksheets ####

  # FULL - no pregannt women
  consumption_wksh = consumption_mapped %>% 
    #remove the consumption of pregnant women
    filter(!ORSUBCODE %in% preg_women_ids ) %>% 
    #select and rename the columns we need
    select("SUBJECTID" = ORSUBCODE, 
           DAY, 
           "AMOUNTOFFOOD" = AMOUNTFRAW, 
           "FOODatL4" = fdx1_name) %>% 
    arrange(SUBJECTID) %>% 
    # create a serial id column
    rowid_to_column(var = "SERIAL")
    
  
  # by Lot
  consumption_wksh_Lot1 = consumption_wksh %>% 
    filter(SUBJECTID %in% Lot1_ids) %>% 
    # create a serial column
    mutate("SERIAL" = seq_len(nrow(.)))
  
  consumption_wksh_Lot2 = consumption_wksh %>% 
    filter(SUBJECTID %in% Lot2_ids) %>% 
    mutate("SERIAL" = seq_len(nrow(.)))


# Create the Subjects worksheet ####

  # read the subjects data from EU Menu files
  subjects = read_xlsx( "SUBJECTS.xlsx") %>% 
    # and remove the ids with only one day in the survey
    filter(!ORSUBCODE %in% ids_to_remove)
  
  # We need to create the 
  # EFSA population (age) groups
  # ----------------------#
  # Infants, <1
  # Toddlers, 1-3
  # Other children, 3-10
  # Adolescents, 10-18
  # Adults, 18-65
  # Elderly, 65-75
  # Very elderly, 75+ 
  # NOTE! EU MENU covers only up to 75.All subjects > 75 will be categorised to "Elderly"
  
  # Full Subject Worksheet
  subjects_wksh = subjects %>% 
    #remove the consumption of pregnant women
    filter(!ORSUBCODE %in% preg_women_ids ) %>% 
    # keep the info we need
    select(ORSUBCODE,
           # If you managed to add the AREA in the SUBJECTS data then add it here
           # AREA
           WEIGHT,
           GENDER,
           AGE) %>% 
    arrange(ORSUBCODE) %>% 
    # IF you have no weight coefficients then add the following line as well
    # ELSE see WCOEFF calculation later in the script
    # add_column(WCOEFF = 1) %>%  
    #
    # split the AGE into the population classes by EFSA
    mutate(POP_CLASS = cut (AGE, 
                            breaks = c(-Inf, 1, 3, 10, 18, 65, Inf),
                            labels = c("Infants", "Toddlers", "Other children", "Adolescents", "Adults",
                                       "Elderly"),
                            #closed brackets on the left Not on the right
                            right = FALSE,
                            ordered_result = TRUE
    )
    ) %>% 
    # Change the G1 and G2" in GENDER , into MALE and FEMALE
    mutate(GENDER = if_else(GENDER == "G1", "MALE", "FEMALE")) %>% 
    # Keeep and/or rename the columns according to ImproRisk guidelines
    select("SUBJECTID" = ORSUBCODE, 
           GENDER, 
           AGE, 
           WEIGHT,
           POP_CLASS,
           #AREA
           ) 

# Create the weight Coefficients ----------------------------------------####

  # get the number of  participants in the food surey 
  # by gender and population class
  sample_counts = subjects_wksh %>% 
    group_by(GENDER, POP_CLASS) %>% 
    count() %>% 
    rename(sample = n)
  
  # The population counts in a table
  # Get these for the recent sensus data
  # This is an example from CYPRUS
  # A table in a wide format
  pop_counts = tribble(
    ~ GENDER, ~ Infants, ~ Toddlers, ~ 'Other children', ~ Adolescents, ~ Adults, ~ Elderly,
    "MALE", 4813, 9546, 34561, 37646, 267006, 36004, 
    "FEMALE", 4346, 8996, 32725, 36308, 284132, 39027
  )
  
  
  #turn the pop_coubts into a long format
  pop_counts = pop_counts %>% 
    gather(POP_CLASS, pop , - GENDER) %>% 
    mutate(POP_CLASS = factor(POP_CLASS, 
                              levels = levels(sample_counts$POP_CLASS), 
                              ordered = T))
  
  # A table of the weighting coeffcients 
  weight_factors = pop_counts %>% 
    left_join(sample_counts) %>% 
    # A sime division of population/ sample. ROunded to no decimal places
    mutate( WCOEFF = round(pop/sample, 0)) %>% 
    select(GENDER, POP_CLASS, WCOEFF)
  
  
  # Add the weighting facros in the SUBJECT WORKSHEET
  subjects_wksh = subjects_wksh %>% 
    left_join(select(weight_factors,
                     GENDER, POP_CLASS, WCOEFF
                     )
              )
  
# >Split file By LOTS ####
  
  subjects_wksh_Lot1 = subjects_wksh %>% filter(SUBJECTID %in% Lot1_ids)
  subjects_wksh_Lot2 = subjects_wksh %>% filter(SUBJECTID %in% Lot2_ids)


# Write the Templates as Excel files on disk

  # Full Dataset
  writexl::write_xlsx( x = list("Consumption" = consumption_wksh,
                                "Subjects" = subjects_wksh), 
                       #file name. include the number of subjects
                       paste0("Subjects_Consumption_EUMENU ALL SUBJECTS (N=",
                              nrow(subjects_wksh),
                              ").xlsx"))
  
  # Lot 1 
  writexl::write_xlsx( x = list("Consumption" = consumption_wksh_Lot1,
                                "Subjects" = subjects_wksh_Lot1), 
                       #file name. include the number of subjects
                       paste0("Subjects_Consumption_EUMENU Lot1 (N=",
                              nrow(subjects_wksh_Lot1),
                              ").xlsx"))
  # and Lot 2 Dataset
  writexl::write_xlsx( x = list("Consumption" = consumption_wksh_Lot2,
                                "Subjects" = subjects_wksh_Lot2), 
                       #file name. include the number of subjects
                       paste0("Subjects_Consumption_EUMENU Lot2 (N=",nrow(subjects_wksh_Lot2),").xlsx"))


# Create a template for Pregnat Women ####
  
  # Note that you need a vector of pregnant women EFSA ids (the ORSUBCODE)
  # named `preg_women_ids`
  
  # Consumption worksheet
  preg_consumption_wksh = consumption_mapped %>%
    # filter the pregnant women only
    filter(ORSUBCODE %in% preg_women_ids) %>% 
    #select coumns we need and rename some
    select("SUBJECTID" = ORSUBCODE, 
           DAY, 
           "AMOUNTOFFOOD" = AMOUNTFRAW, 
           "FOODatL4" = fdx1_name) %>% 
    arrange(SUBJECTID) %>% 
    rowid_to_column(var = "SERIAL")
  
  # Subject worksheet 
  preg_subject_wksh = subjects %>% 
    # filter the pregnant women only
    filter(ORSUBCODE %in% preg_women_ids) %>% 
    # keep the relevant columns
    # THE ORDER IS IMPORTANT
    select(ORSUBCODE,
           # If you managed to add the AREA in the SUBJECTS data then add it here
           # AREA
           WEIGHT,
           AGE) %>% 
    arrange(ORSUBCODE) %>% 
    # since this for preganant women only, the WCOEFF will be 1
    add_column(WCOEFF = 1) %>% 
    
    add_column(POP_CLASS = "Pregnant Women") %>% 
    mutate(GENDER = "FEMALE") %>% 
    # order the columns, rename
    select("SUBJECTID" = ORSUBCODE, 
           GENDER, 
           AGE, 
           WEIGHT,
           POP_CLASS, 
           # AREA, 
           WCOEFF) 
  
  # write the dataset on disk as an excel file
  write_xlsx( x = list("Consumption" = preg_consumption_wksh,
                          "Subjects" = preg_subject_wksh), 
                 #file name. include the number of subjects
                 paste0("Subjects_Consumption_EUMENU Pregnant Women (N=",
                        nrow(preg_subject_wksh),
                        ").xlsx"))




