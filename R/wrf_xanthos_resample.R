#' wrf_xanthos_resample
#'
#' This function is a wrapper for resample_wrf_hourly_to_month() to meet the naming conventions of the
#' im3 project. It simply calls the generic resample_wrf_hourly_to_month() function.
#' Resample a netcdf4 file to new lat/lon coordinates based on
#' a given dataframe. Returns a long dataframe with lat lon and parameter from the netcdf chosen.
#' @param ncdf_path Default = NULL. Path to netcdf file or folder containing '.nc' files.
#' @param target_grid Default = NULL. Path to target_grid file .csv or a dataframe
#' @param params Default = NULL. Params from the netcdf file to resample.
#' For Xanthos params= c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
#' @param aggregation_method Default = c("sum"). Aggregation method to aggregate param values over hours.
#' @param out_dir Default = "output". Output directory to save outputs if save = T.
#' @param save Default = FALSE. Whether to save files.
#' @param ncdf_resampled Default = NULL. A pre-resampled dataset for WRF to a target grid.
#' A pre-resampled data set for WRF to the Xanthos grid is available in the package as: im3components::data_ncdf_resampled_wrf_xanthos
#' @importFrom magrittr %>%
#' @source Method based on https://rpubs.com/markpayne/132500
#' @return Dataframe of resampled data
#' @export

wrf_xanthos_resample <- function(ncdf_path = NULL,
                                 target_grid = NULL,
                                 params=NULL,
                                 aggregation_method = c("mean"),
                                 out_dir='output',
                                 save=FALSE,
                                 ncdf_resampled = NULL) {


  print("Starting wrf_xanthos_resample...")

  # Calling resample_wrf_hourly_to_month which is the generic function
  # which can be used with other non-Xanthos grids as well
  im3components::resample_wrf_hourly_to_month(
    ncdf_path = ncdf_path,
    target_grid = target_grid,
    params = params,
    aggregation_method = aggregation_method,
    out_dir= out_dir,
    save = save,
    ncdf_resampled = ncdf_resampled)-> wrf_data_resampled

  print("Finished wrf_xanthos_resample.")

  return(wrf_data_resampled)

  }
