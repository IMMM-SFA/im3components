#' data_ncdf_resampled_wrf_xanthos
#'
#' @source IM3 WRF data set and Xanthos reference data
#' @format R tibble
#' @examples
#' \dontrun{
#'  library(im3components);
#'  im3components::ncdf_resampled_wrf_xanthos
#' }
"data_ncdf_resampled_wrf_xanthos"

#' data_coordinates_xanthos_reference
#'
#' @source Xanthos reference coordinates for 67420 cells. Original in xanthos/example/input/reference/coordinates.csv
#' @format R tibble
#' @examples
#' \dontrun{
#'  library(im3components);
#'  im3components::coordinates_xanthos_reference
#' }
"data_coordinates_xanthos_reference"

#' data_NCAR_raw
#'
#' Raw data from Jiang et al. 2020 for population by US state. Sources in details below.
#'
#' - Raw data from: Jiang, Leiwen, et al. 2020 "Population scenarios for US states consistent with shared
#' socioeconomic pathways." Environmental Research Letters 15.9 (2020): 094097;
#' - Paper: https://iopscience.iop.org/article/10.1088/1748-9326/aba5b1/pdf
#' - Raw data downloaded from: http://doi.org/10.5281/zenodo.3956703 and unzipped.
#' - Relevant file: statepop-v0.1.0/IMMM-SFA-statepop-61c8fff/inputs/AllStatesProjection.csv
#'
#' @source Jiang et al. 2020, Raw Data: http://doi.org/10.5281/zenodo.3956703
#' @format R tibble
#' @examples
#' \dontrun{
#'  library(im3components);
#'  im3components::data_NCAR_raw
#' }
"data_NCAR_raw"

#' data_NCAR_gcam
#'
#' Exisitng NCAR popultation data by US state from GCAM for SSP2.
#'
#' Available at: ./input/gcamdata/inst/extdata/gcam-usa/NCAR_SSO2_pop_state.csv
#'
#' @source GCAM data system: ./input/gcamdata/inst/extdata/gcam-usa/NCAR_SSO2_pop_state.csv
#' @format R tibble
#' @examples
#' \dontrun{
#'  library(im3components);
#'  im3components::data_NCAR_gcam
#' }
"data_NCAR_gcam"

