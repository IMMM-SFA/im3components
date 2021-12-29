#' pop_gcam_process
#'
#' Script to process raw NCAR population data in format similar to existing input file: gcam-usa/NCAR_SSP2_pop_state
#' Raw data from: Jiang, Leiwen, et al. 2020 "Population scenarios for US states consistent with shared
#' socioeconomic pathways." Environmental Research Letters 15.9 (2020): 094097;
#' data: http://doi.org/10.5281/zenodo.3956703 ; Paper: https://iopscience.iop.org/article/10.1088/1748-9326/aba5b1/pdf
#' Raw data downloaded from: http://doi.org/10.5281/zenodo.3956703 and unzipped.
#' Relevant file: statepop-v0.1.0/IMMM-SFA-statepop-61c8fff/inputs/AllStatesProjection.csv
#' Also uses NCAR data from GCAM to get correct format. .input/gcamdata/inst/extdata/gcam-usa/NCAR_SSO2_pop_state.csv
#' Output file: NCAR_SSP_pop_state.csv
#' @param data_NCAR_raw  Default = im3components::data_NCAR_raw. Must be an R table.
#' Can replace with updated data set when available. See format of data head(im3components::data_NCAR_raw).
#' @param data_NCAR_gcam Default = im3components::data_NCAR_gcam. Must be an R table.
#' Can replace with updated data set when available. See format of data head(im3components::data_NCAR_gcam).
#' @importFrom magrittr %>%
#' @return NCAR_SSP_pop_state.csv
#' @export

pop_gcam_process <- function(data_NCAR_raw = im3components::data_NCAR_raw,
                        data_NCAR_gcam = im3components::data_NCAR_gcam) {

  #........................
  # Initialize
  #........................

  print("Starting pop_to_gcam...")
  NULL -> Pop_Type -> Population -> SSP -> STATE_NAME ->
    Scenario -> State -> State_FIPS -> Year

  #............................
  # Read in Data
  #...........................

  NCAR_raw <- data_NCAR_raw
  NCAR_gcam <- data_NCAR_gcam

  #............................
  # Process
  #...........................

  NCAR_SSP_pop_state <- NCAR_raw %>%
    dplyr::filter(Pop_Type == "total",
                  STATE_NAME != "Puerto_Rico") %>%
    dplyr::select(State = STATE_NAME, Year, SSP = Scenario, Population) %>%
    dplyr::mutate(SSP = as.numeric(as.character(gsub("ssp","",SSP))),
                  Population = round(Population),
                  State = gsub("_"," ",State),
                  State = dplyr::case_when(State=="DC"~"District of Columbia",
                                    TRUE ~ State)) %>%
    tidyr::spread(key="Year",value="Population") %>%
    dplyr::left_join(NCAR_gcam %>%
                       dplyr::select(State,State_FIPS) %>%
                       dplyr::distinct()); NCAR_SSP_pop_state

  #............................
  # Save as csv file
  #...........................

  data.table::fwrite(NCAR_SSP_pop_state, "NCAR_SSP_pop_state.csv")
  print(paste0("Output saved as: ", getwd(), "/NCAR_SSP_pop_state.csv"))

  #............................
  # Close Out
  #...........................

  print("Finished processing pop_to_gcam.")

}

