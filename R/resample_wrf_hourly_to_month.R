#' resample_wrf_hourly_to_month
#'
#' Resample a netcdf4 file to new lat/lon coordinates based on
#' a given dataframe. Returns a long dataframe with lat lon and parameter from the netcdf chosen.
#' @param ncdf_path  Default = NULL. Path to netcdf file or folder containing '.nc' files.
#' @param target_grid Default = NULL. Path to target_grid file .csv or a dataframe
#' @param params Default = NULL. Params from the netcdf file to resample.
#' For Xanthos params= c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
#' @param aggregation_method Default = c("mean"). Aggregation method to aggregate param values over hours.
#' Can be a vector of the same length as params with either "sum" or "mean" corresponding to each param. If single value given then
#' the same method will be applied to all parameters.
#' For Xanthos params aggregation_method = c("sum","mean","mean","mean","mean","mean","mean","mean")
#' @param out_dir Default = "output". Output directory to save outputs if save = T.
#' @param save Default = FALSE. Whether to save files.
#' @param ncdf_resampled (Optional) Default = NULL. A resampled data set for WRF to Xanthos is available in the package as: im3components::data_ncdf_resampled_wrf_xanthos
#' @importFrom magrittr %>%
#' @source Method based on https://rpubs.com/markpayne/132500
#' @return Dataframe of resampled data
#' @export

resample_wrf_hourly_to_month <- function(ncdf_path = NULL,
                                         target_grid = NULL,
                                         params=NULL,
                                         aggregation_method = c("mean"),
                                         out_dir='output',
                                         save=FALSE,
                                         ncdf_resampled = NULL) {

  # Initialize
  print("resample_wrf_hourly_to_month...")

  # Initialize Constants
  NULL->PSFC->Q2->T2->U10->V10->lat->latid->lon->lonid->month->param->rh->
  time->unit->v->value->year

  # Check if ncdf_path is a folder or list of files
  if(dir.exists(ncdf_path)){
    ncdf_paths_original <- list.files(ncdf_path, pattern="^wrfout_*", full.names=TRUE, recursive=T)
  } else {
    if(is.character(class(ncdf_path))){
      ncdf_paths_original <- ncdf_path
    } else {
      stop(paste0("ncdf_path must be a path to a folder or vector of files with paths to files starting with 'wrfout'."))
    }
  }

  # Check that ncdf_files provided exist
  ncdf_paths <- ncdf_paths_original
  for(ncdf_path_i in ncdf_paths_original){
    if(!file.exists(ncdf_path_i)){
      print(paste0("ncdf_path file provided: ", ncdf_path_i, " does not exist. Ignoring file."))
      ncdf_paths <- ncdf_paths[!grepl(paste0(ncdf_path_i, collapse = "|"), ncdf_paths)]
    }
  }

  # Check aggregation method inputs
  if(length(aggregation_method)>1 & length(aggregation_method) != length(params)){
    print(paste0("Length of aggregation_method is not equal to length of params provided."))
    print(paste0("Using the first entry of aggregation_method: ", aggregation_method[1], " as the method for all params."))
    aggregation_method <- rep(tolower(aggregation_method[1]), length(params))
  }

  if(length(aggregation_method)==1){
    aggregation_method <- rep(tolower(aggregation_method[1]), length(params))
  }

  if(all(!grepl("sum|mean",aggregation_method,ignore.case=T))){
    print(paste0("aggregation_method provided: ", paste(aggregation_method,collapse=", "), " is not one of 'sum' or 'mean'. Using 'sum' for all params."))
    aggregation_method <- rep("sum", length(params))
  }


  # For each file resample to target grid and aggregate to monthly
  resampled_monthly_df <- tibble::tibble()
  for(ncdf_path_i in ncdf_paths){

    print(paste0("Starting aggregation to month for file: ", ncdf_path_i, "..."))

  # Resample to target_grid
  resampled_df <- im3components::resample_wrf_to_df(
    ncdf_path = ncdf_path_i,
    target_grid = target_grid,
    params = params,
    out_dir= out_dir,
    save = F,
    ncdf_resampled = ncdf_resampled
    )

  # Parse out Month, year, hour
  resampled_df_parse <- resampled_df %>%
    # Using time POSIXct but much slower
    # dplyr::mutate(time = as.POSIXct(time,format='%Y-%m-%d_%H:%M:%S'),
    #               year = format(time, format = "%Y"),
    #               month = format(time, format = "%m"))
    # Using gsub since we know format and much faster
    dplyr::mutate(year = substr(time,1,4),
                  month = substr(time,6,7))

  # Aggregate to month
  for(i in 1:length(params)){

    param_i = params[i]
    aggregation_method_i = aggregation_method[i]

    resampled_monthly_df_i <- resampled_df_parse %>%
      dplyr::filter(param == param_i) %>%
      dplyr::select(-time)%>%
      dplyr::group_by(lon,lat,param,year,month, unit)

    # Join to main table
    resampled_monthly_df <-
      resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_i)

    if(tolower(aggregation_method_i) == "sum"){
      resampled_monthly_df <- resampled_monthly_df %>%
        dplyr::group_by(lon,lat,param,year,month, unit) %>%
        dplyr::summarize(value = sum(value,na.rm=T))}

    if(tolower(aggregation_method_i) == "mean"){
      resampled_monthly_df <- resampled_monthly_df %>%
        dplyr::group_by(lon,lat,param,year,month, unit) %>%
        dplyr::summarize(value = mean(value,na.rm=T))}

    print(paste0("Aggregation to month for file: ", ncdf_path_i,
                 " for param: ", param_i,
                 " using aggregation method: ", aggregation_method_i, " completed."))

  }
  }

  # Calculate Xanthos specific Params

  # Relative humidity
  # If Q2, T2 and PSFC exist calculate Relative Humididty
  # https://www.mcs.anl.gov/~emconsta/relhum.txt
  if(all(c("Q2","T2","PSFC") %in% params)){

    print("Calculating new param 'rh' relative humidity (percent) from Q2, T2 and PSFC for Xanthos.")

    # Constants from https://www.mcs.anl.gov/~emconsta/relhum.txt
    pq0 = 379.90516
    a2 = 17.2693882
    a3 = 273.16
    a4 = 35.86

    resampled_monthly_df_rh <- resampled_monthly_df %>%
      dplyr::filter(param %in% c("Q2","T2","PSFC")) %>%
      dplyr::select(-unit) %>%
      tidyr::spread(key="param",value="value") %>%
      dplyr::mutate(rh = Q2 / ( (pq0 / PSFC) * exp(a2 * (T2 - a3) / (T2 - a4)) ),
                    unit = "percent") %>%
      dplyr::select(-PSFC,-Q2,-T2) %>%
      dplyr::rename(param=rh) %>%
      dplyr::mutate(param = "rh")

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_rh)

  }

  # Wind Speed m/s
  # If v10 and u10 exist calculate using pythagoras
  if(all(c("V10","U10") %in% params)){

    print("Calculating new param 'v' Wind Speed (m s-1) from V10 and U10 for Xanthos.")

    resampled_monthly_df_v <- resampled_monthly_df %>%
      dplyr::filter(param %in% c("V10","U10")) %>%
      tidyr::spread(key="param",value="value") %>%
      dplyr::mutate(v = sqrt(V10^2 + U10^2))%>%
      dplyr::select(-V10,-U10) %>%
      dplyr::rename(param=v) %>%
      dplyr::mutate(param = "v")

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_v)

  }

  # Temp deg C
  # If T2 is exists whic is in K
  if(all(c("T2") %in% params)){

    print("Calculating new param 'tempDegC' temperature in Degree Celcius from T2 for Xanthos.")

    resampled_monthly_df_tdegc <- resampled_monthly_df %>%
      dplyr::filter(param %in% c("T2")) %>%
      dplyr::mutate(value = value - 273.15)%>%
      dplyr::mutate(param = "tempDegC",
                    unit = "degC")

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_tdegc)

  }


  # Save data
  if(save){

     if(!grepl("/",out_dir)){
      if(!dir.exists(out_dir)){
        dir.create(out_dir)
      }
     }

    for(param_i in unique(resampled_monthly_df$param)){

      resampled_monthly_df_param <- resampled_monthly_df %>%
        dplyr::filter(param==param_i) %>%
        dplyr::mutate(year_month=paste0(year,"_",month)) %>%
        dplyr::ungroup() %>%
        dplyr::select(-year,-month)

      # Save in Xanthos format
      resampled_monthly_df_xanthos <- im3components::data_coordinates_xanthos_reference %>%
        dplyr::left_join(resampled_monthly_df_param %>%
                           tidyr::spread(key="year_month",value="value")) %>%
        dplyr::select(-lonid,-latid)

      from_i = min(resampled_monthly_df_param$year_month); from_i
      to_i = max(resampled_monthly_df_param$year_month); to_i
      unit_i = unique(resampled_monthly_df_param$unit)

      fname = paste0("resampled_wrf_to_xanthos_monthly_",param_i,"_",unit_i,"_",from_i,"_to_",to_i,".csv")
      data.table::fwrite(resampled_monthly_df_xanthos,
                         paste0(getwd(),"/",out_dir,"/", fname))
      print(paste0("File saved to: ", getwd(),"/",out_dir,"/", fname))
    }
  }

  # Close Out
  print("Completed resample_wrf_hourly_to_month.")
  return(resampled_monthly_df)

  }
