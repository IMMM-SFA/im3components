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
                                         ncdf_resampled = NULL,
                                         pattern="*.nc") {

  # Initialize
  print("resample_wrf_hourly_to_month...")

  # Initialize Constants
  NULL->RAINC->RAINNC->RAINSH->PSFC->Q2->T2->U10->V10->lat->latid->lon->lonid->month->param->rh->
    time->unit->v->value->year

  # Check if ncdf_path is a folder or list of files
  if(dir.exists(ncdf_path)){
    ncdf_paths_original <- list.files(ncdf_path, pattern= pattern, full.names=TRUE, recursive=T)
  } else {
    if(is.character(class(ncdf_path))){
      ncdf_paths_original <- ncdf_path
    } else {
      stop(paste0("ncdf_path must be a path to a folder or vector of files paths to files with the pattern: ", pattern, "."))
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


  # For each file resample to target grid and aggregate
  resampled_df_comb <- tibble::tibble()
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
      dplyr::mutate(year = substr(time,1,4),
                    month = substr(time,6,7),
                    day = substr(time,9,10),
                    hour = substr(time,12,13)) %>%
      dplyr::filter(hour %in% c("00","23"))

    # Join to main table
    resampled_df_comb <-
      resampled_df_comb %>%
      dplyr::bind_rows(resampled_df_parse)
  }
  resampled_df_comb


  # Aggregate to month
  resampled_monthly_df <- tibble::tibble()
  counter_rain = 0

  for(i in 1:length(params)){

    param_i = params[i]
    aggregation_method_i = aggregation_method[i]

    resampled_monthly_df_i <- resampled_df_comb %>%
      dplyr::filter(param == param_i) %>%
      dplyr::select(-time)

    # Calculate min daily temperature if param T2 exists
    if(param_i == "T2"){
      resampled_monthly_df_i_grouped <- resampled_monthly_df_i %>%
                           dplyr::group_by(lon,lat,param,year,month,unit) %>%
                           dplyr::summarize(value = min(value,na.rm=T)) %>%
                           dplyr::mutate(param="T2min") %>%
                           dplyr::ungroup() %>%
        dplyr::bind_rows(resampled_monthly_df_i %>%
                           dplyr::group_by(lon,lat,param,year,month, unit) %>%
                           dplyr::summarize(value = mean(value,na.rm=T)) %>%
                           dplyr::ungroup())
    }


    # Calculate Accumulated Rain over months
    if(grepl("RAIN",param_i)){
      if(counter_rain==0){

        resampled_monthly_df_i_grouped <-  resampled_df_comb %>%
          dplyr::select(-time) %>%
          dplyr::filter(grepl("RAIN",param)) %>%
          dplyr::group_by(lon,lat,unit,year,month,day,hour) %>%
          dplyr::summarize(value=sum(value,na.rm=T))%>%
          dplyr::ungroup() %>%
          dplyr::mutate(param="RAIN") %>%
          tidyr::spread(key="hour",value="value")%>%
          dplyr::mutate(value = `23`-`00`)%>%
          dplyr::select(-`23`,-`00`)%>%
          dplyr::group_by(lon,lat,unit,year,param,month) %>%
          dplyr::summarize(value=sum(value,na.rm=T))%>%
          dplyr::ungroup(); resampled_monthly_df_i_grouped

        counter_rain = counter_rain+1 # Only calculate once
      }
    }


    if(!grepl("T2|RAIN",param_i)){

    if(tolower(aggregation_method_i) == "sum"){
      resampled_monthly_df_i_grouped <- resampled_monthly_df_i %>%
      dplyr::group_by(lon,lat,param,year,month, unit) %>%
      dplyr::summarize(value = sum(value,na.rm=T)) %>%
      dplyr::ungroup()
      }

    if(tolower(aggregation_method_i) == "mean"){
      resampled_monthly_df_i_grouped <- resampled_monthly_df_i %>%
      dplyr::group_by(lon,lat,param,year,month, unit) %>%
      dplyr::summarize(value = mean(value,na.rm=T)) %>%
      dplyr::ungroup()
    }

    }

    # Join to main table
    resampled_monthly_df <-
      resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_i_grouped) %>%
      dplyr::distinct()

    print(paste0("Aggregation to month for file: ", ncdf_path_i,
                 " for param: ", param_i,
                 " using aggregation method: ", aggregation_method_i, " completed."))

    if(param_i == "T2"){
    print(paste0("Aggregation to month for file: ", ncdf_path_i,
                 " for param: T2min",
                 " using aggregation method: ", aggregation_method_i, " completed."))}

    if(grepl("RAIN",param_i)){
      if(counter_rain==0){
      print(paste0("Aggregation to month for file: ", ncdf_path_i,
                   " for param: RAIN",
                   " using aggregation method: ", aggregation_method_i, " completed."))}
    }

  }
  resampled_monthly_df

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
      dplyr::ungroup() %>%
      dplyr::filter(param %in% c("Q2","T2","PSFC")) %>%
      dplyr::select(-unit) %>%
      tidyr::spread(key="param",value="value") %>%
      dplyr::mutate(value = 100 * Q2 / ( (pq0 / PSFC) * exp(a2 * (T2 - a3) / (T2 - a4)) ),
                    unit = "percent",
                    param= "rh") %>%
      dplyr::select(-PSFC,-Q2,-T2) %>%
      dplyr::ungroup()

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_rh)

  }

  # Wind Speed m/s
  # If v10 and u10 exist calculate using pythagoras
  if(all(c("V10","U10") %in% params)){

    print("Calculating new param 'v' Wind Speed (m s-1) from V10 and U10 for Xanthos.")

    resampled_monthly_df_v <- resampled_monthly_df %>%
      dplyr::ungroup() %>%
      dplyr::filter(param %in% c("V10","U10")) %>%
      tidyr::spread(key="param",value="value") %>%
      dplyr::mutate(value = sqrt(V10^2 + U10^2),
                    param="v")%>%
      dplyr::select(-V10,-U10) %>%
      dplyr::ungroup()

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_v)

  }

  # Temp deg C
  # If T2 is exists which is in K
  if(all(c("T2") %in% params)){

    print("Calculating new param 'tempDegC' temperature in Degree Celcius from T2 for Xanthos.")

    resampled_monthly_df_tdegc <- resampled_monthly_df %>%
      dplyr::ungroup() %>%
      dplyr::filter(param %in% c("T2")) %>%
      dplyr::mutate(value = value - 273.15)%>%
      dplyr::mutate(param = "tempDegC",
                    unit = "degC")

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_tdegc)

  }

  # Temp deg C
  # If T2min exists which is in K
  if(all(c("T2") %in% params)){

    print("Calculating new param 'tempDegCmin' min Daily temperature in Degree Celcius from T2 for Xanthos.")

    resampled_monthly_df_tdegcmin <- resampled_monthly_df %>%
      dplyr::ungroup() %>%
      dplyr::filter(param %in% c("T2min")) %>%
      dplyr::mutate(value = value - 273.15)%>%
      dplyr::mutate(param = "tempDegCmin",
                    unit = "degC")

    resampled_monthly_df <- resampled_monthly_df %>%
      dplyr::bind_rows(resampled_monthly_df_tdegcmin)

  }


  # Keep Unique
  resampled_monthly_df <- resampled_monthly_df %>%
    dplyr::distinct()

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


#' resample_wrf_to_df
#'
#' Resample a netcdf4 file to new lat/lon coordinates based on
#' a given dataframe. Returns a long dataframe with lat lon and parameter from the netcdf chosen.
#' @param ncdf_path  Default = NULL. Path to netcdf file
#' @param target_grid Default = NULL. Path to target_grid file .csv or a dataframe
#' @param params Default = NULL. Params from the netcdf file to resample.
#' For Xanthos params= c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
#' @param out_dir Default = "output". Output directory to save outputs if save = T.
#' @param save Default = FALSE. Whether to save files.
#' @param ncdf_resampled Default = NULL. A resampled data set for WRF to Xanthos is available in the package as: im3components::data_ncdf_resampled_wrf_xanthos
#' @importFrom magrittr %>%
#' @source Method based on https://rpubs.com/markpayne/132500
#' @return Dataframe of resampled data
#' @export

resample_wrf_to_df <- function(ncdf_path = NULL,
                               target_grid = NULL,
                               params=NULL,
                               out_dir='output',
                               save=FALSE,
                               ncdf_resampled = NULL) {

  #........................
  # Initialize
  #........................

  print("Starting resample_wrf_to_df...")
  NULL ->V1->V2->V3->V4->V5->lat->lon->x->y->.

  # Check ncdf file path provided
  if(!file.exists(ncdf_path)){stop(paste0("ncdf_path provided does not exist: ", ncdf_path))}
  nc <- ncdf4::nc_open(ncdf_path)
  variables <- paste(attributes(nc$var)$names,collapse=", ")
  paste0("Variables available: ", variables) # Get Variable Names
  ncdf_lon <- raster::raster(ncdf_path, varname="XLONG",ncdf=TRUE) # Get Lat
  ncdf_lat <- raster::raster(ncdf_path, varname="XLAT",ncdf=TRUE) # Get Lon
  ncdf_time <-  ncdf4::ncvar_get(nc,"Times")
  # Add in missing times if any
  blank_name_indices = which(ncdf_time == "")
  if(length(blank_name_indices)>0){
  for(i in blank_name_indices){
    ncdf_time_i_less_1 <- ncdf_time[i-1]
    ncdf_time[i] <- gsub(" ","_",as.character(strptime(ncdf_time_i_less_1, format="%Y-%m-%d_%H:%M:%S")+1*60*60*1))
  }
  }

  # Check if params are in available variables
  if(!any(params %in% attributes(nc$var)$names)){
    stop(paste0("None of the chosen params: ", params, " are available in the netcdf file chosen."))
  }

  if(!all(params %in% attributes(nc$var)$names)){
    print(paste0("The following chosen params are not available in the netcdf file chosen:"))
    print(paste0(params[!params %in% attributes(nc$var)$names]))
    print(paste0("Resampling for available params:"))
    print(paste0(params[params %in% attributes(nc$var)$names]))
    params_available <- params[params %in% attributes(nc$var)$names]
  } else {
    params_available <- params
  }

  print(paste0("Resampling for chosen params: ", paste(params_available, collapse = ", ")))


  #........................
  # Create Resampling Grid
  #........................

  if(is.null(ncdf_resampled) | !all(c("lon","lat","x","y") %in% names(ncdf_resampled))){

    if(!all(c("lon","lat","x","y") %in% names(ncdf_resampled))){
      print("ncdf_resampled provided is not in correct format. Recalcualting based on the target grid.")
    }

    # Create a data frame with coordinates
    # x/y are just indices and represent different points on the target_grid with their own lat/lon
    ncdf_raster <- raster::raster(ncdf_path, varname="XLONG",ncdf=TRUE)
    ncdf_grid <- data.frame(sp::coordinates(ncdf_raster),
                            lon = as.vector(ncdf_lon),
                            lat = as.vector(ncdf_lat)) %>%
      tibble::as_tibble()

    # Get target target_grid & subset to ncdf_data extent
    if(class(target_grid)=="character"){
      if(!file.exists(target_grid)){
        stop(paste0("target_grid path provided does not exist: ",target_grid))
      } else {
        target_grid_x <- data.table::fread(target_grid, header=F) %>%
          tibble::as_tibble() %>%
          dplyr::select(lon=V2,lat=V3,gridid=V1,lonid=V4,latid=V5) %>%
          dplyr::filter(lon < max(as.vector(ncdf_lon)),
                        lon > min(as.vector(ncdf_lon)),
                        lat < max(as.vector(ncdf_lat)),
                        lat > min(as.vector(ncdf_lat)))
      }
    }

    if(any(grepl("data.frame|tbl|tbl_df",class(target_grid)))){
      target_grid_x <- target_grid
    }

    # Create Target Raster
    target_raster_x <- raster::rasterFromXYZ(target_grid_x)

    # Interpolate the "x" index onto the new lat/lon values from the target_raster_x
    print(paste0("Resampling ncdf x to target grid..."))
    resampled_x <- akima::interp(
      x=ncdf_grid$lon,
      y=ncdf_grid$lat,
      z=ncdf_grid$x,
      xo=raster::xFromCol(target_raster_x),
      yo=raster::yFromRow(target_raster_x))
    print(paste0("Resampling ncdf x to target grid complete."))

    # Interpolate the "y" index onto the new lat/lon values from the Xanthos Grid
    print(paste0("Resampling ncdf y to target grid..."))
    resampled_y <- akima::interp(
      x=ncdf_grid$lon,
      y=ncdf_grid$lat,
      z=ncdf_grid$y,
      xo=raster::xFromCol(target_raster_x),
      yo=raster::yFromRow(target_raster_x))
    print(paste0("Resampling ncdf y to target grid complete."))

    # Now expand target_grid and set the interpolated x and y index values of ncdf_grid
    ncdf_resampled <- expand.grid(lon=raster::xFromCol(target_raster_x),
                                  lat=raster::yFromRow(target_raster_x))
    ncdf_resampled$x <- as.vector(resampled_x$z)
    ncdf_resampled$y <- as.vector(resampled_y$z)
    ncdf_resampled <- ncdf_resampled %>%
      tibble::as_tibble()
  }

  # Create a spatial object with coordinates set as the indices from ncdf_grid
  ncdf_resampled_spatial <- ncdf_resampled %>%
    dplyr::mutate(x = ifelse(is.na(x),0,x),
                  y = ifelse(is.na(y),0,y))
  sp::coordinates(ncdf_resampled_spatial) <- ~x + y


  #..............................
  # Resample netcdf for each param
  #.............................

  resampled_dataframe <- tibble::tibble()

  for(param_i in params_available){

    unit_i = ncdf4::ncatt_get(nc, param_i)$units # Get Variable Units
    if(unit_i ==""){unit_i <- "none"}
    print(paste0("Starting resampling for param: ", param_i, " with units: ", unit_i))

    ncdf_brick_i <- raster::brick(ncdf_path, varname=param_i, ncdf=TRUE)

    # Now extract the values at the new locations with the xanthos lat/lon by bilinear interpolation
    # which uses the four nearest neighbours
    df_resampled_i <- ncdf_resampled %>%
      dplyr::bind_cols(raster::extract(ncdf_brick_i, ncdf_resampled_spatial, method="bilinear") %>%
                         tibble::as_tibble()) %>%
      dplyr::filter(stats::complete.cases(.))
    names(df_resampled_i) <- c(names(ncdf_resampled),ncdf_time)

    # Melt data into long format and add years, month, param and unit columns
    resampled_dataframe <-
      resampled_dataframe %>%
      dplyr::bind_rows(
        df_resampled_i %>%
          dplyr::select(-x,-y) %>%
          tidyr::gather(key = "time",value="value",-lon,-lat)%>%
          dplyr::mutate(param = param_i,
                        unit = unit_i)
        #dplyr::mutate(date=as.Date(date, format = "%Y-%m-%d_%H:%M:%S"),
        #              year = format(date,format="%Y"),
        #              month = format(date,format="%m"))
      )

    print(paste0("Finished processing parameter: ", param_i))
  }

  # Save data
  if(save){
    fname = paste0("resampled_",gsub(".nc",".csv",basename(ncdf_path)))
    if(!grepl("/",out_dir)){
      if(!dir.exists(out_dir)){
        dir.create(out_dir)
      }
    }

    data.table::fwrite(resampled_dataframe,
                       paste0(getwd(),"/",out_dir,"/", fname))
    print(paste0("File saved to: ", getwd(),"/",out_dir,"/", fname))
  }

  # Close out
  print("Finished resample_wrf_to_df.")

  return(resampled_dataframe)


}


#' xanthos_gcam_create_xml
#'
#' This function creates xmls for GCAM from raw xanthos outputs
#' a given dataframe. Returns a long dataframe with lat lon and parameter from the netcdf chosen.
#' @param xanthos_runoff_csv Default = NULL. Path to xanthos basin runoff .csv outputs file.
#' @param gcamdata_folder Default = NULL. Path to gcamdatafolder.
#' @param out_dir Default = NULL. Path to folder to save outputs in.
#' @importFrom magrittr %>%
#' @source Method based on https://rpubs.com/markpayne/132500
#' @return xml
#' @export

xanthos_gcam_create_xml <- function(xanthos_runoff_csv = NULL,
                                    gcamdata_folder = NULL,
                                    out_dir = NULL) {


  print("Starting xanthos_gcam_create_xml...")

  # Initialize
  NULL -> Basin_name -> GCAM_basin_ID -> GCAM_region_ID -> GLU -> ISO ->
    basin_id -> basin_name -> bind_rows -> id -> iso -> maxSubResource ->
    name -> region -> renewresource -> sub.renewable.resource -> water_type ->
    year


  # Read in xanthos output file and region files
  gcamdatafolder = gcamdata_folder
  dfraw <- data.table::fread(xanthos_runoff_csv,header=TRUE)

  # Prepare the Data by GCAM Basin Region
  if(T){
    # From .input/gcamdata/R/zchunk_L201.water_resources_constrained
    GCAM_region_names <- data.table::fread(paste(gcamdatafolder,"/inst/extdata/common/GCAM_region_names.csv",sep=""),header=TRUE)
    iso_GCAM_regID <- data.table::fread(paste(gcamdatafolder,"/inst/extdata/common/iso_GCAM_regID.csv",sep=""),header=TRUE)
    basin_to_country_mapping <- data.table::fread(paste(gcamdatafolder,"/inst/extdata/water/basin_to_country_mapping.csv",sep=""),header=TRUE)
    basin_ids <- data.table::fread(paste(gcamdatafolder,"/inst/extdata/water/basin_ID.csv",sep=""),header=TRUE)
    water_mapping_R_GLU_B_W_Ws_share <- data.table::fread(paste(gcamdatafolder,"/outputs/L103.water_mapping_R_GLU_B_W_Ws_share.csv",sep=""),header=TRUE)
    water_mapping_R_B_W_Ws_share <- data.table::fread(paste(gcamdatafolder,"/outputs/L103.water_mapping_R_B_W_Ws_share.csv",sep=""),header=TRUE)

    # Basin_to_country_mapping table include only one set of dplyr::distinct basins
    # that are mapped to a single country with largest basin share.
    # Assign GCAM region name to each basin.
    # Basin with overlapping GCAM regions assign to region with largest basin area.
    basin_to_country_mapping %>%
      dplyr::rename(iso = ISO) %>%
      dplyr::mutate(iso = tolower(iso)) %>%
      dplyr::left_join(iso_GCAM_regID, by = "iso") %>%
      # ^^ non-restrictive join required (NA values generated for unmapped iso)
      # basins without gcam region mapping excluded (right join)
      # Antarctica not assigned
      dplyr::right_join(GCAM_region_names, by = "GCAM_region_ID") %>%
      dplyr::rename(basin_id = GCAM_basin_ID,
             basin_name = Basin_name) %>%
      dplyr::select(GCAM_region_ID, region, basin_id) %>%
      dplyr::arrange(region) ->
      RegionBasinHome

    # identify basins without gcam region mapping (dplyr::anti_join)
    basin_to_country_mapping %>%
      dplyr::rename(iso = ISO) %>%
      dplyr::mutate(iso = tolower(iso)) %>%
      dplyr::left_join(iso_GCAM_regID, by = "iso") %>%
      #not all iso included in basin mapping
      # ^^ non-restrictive join required (NA values generated for unmapped iso)
      dplyr::anti_join(GCAM_region_names, by = "GCAM_region_ID") ->
      BasinNoRegion

    # create full set of region/basin combinations
    # some basins overlap multiple regions
    # Use left join to ensure only those basins in use by GCAM regions are included
    bind_rows(water_mapping_R_GLU_B_W_Ws_share %>%
                dplyr::rename(basin_id = GLU),
              water_mapping_R_B_W_Ws_share) %>%
      dplyr::select(GCAM_region_ID, basin_id, water_type) %>%
      dplyr::filter(water_type == "water withdrawals") %>%
      dplyr::distinct() %>%
      dplyr::left_join(basin_ids, by = "basin_id") %>%
      tibble::as_tibble()%>%
      # ^^ non-restrictive join required (NA values generated for unused basins)
      gcamdata::left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID") %>%
      dplyr::mutate(water_type = "water withdrawals",
             resource = paste(basin_name, water_type, sep="_")) %>%
      dplyr::arrange(region, basin_name) ->
      L201.region_basin

    # create unique set of region/basin combination with
    # basin contained by home region (region with largest basin area)
    L201.region_basin %>%
      dplyr::inner_join(RegionBasinHome, by = c("basin_id","GCAM_region_ID","region")) %>%
      dplyr::arrange(region, basin_name) ->
      L201.region_basin_home

    # Re-format to format for ./input/gcamdata/outputs/L201.GrdRenwRsrcMax_runoff.csv which include
    # region, renewresource, sub.renewable.resource, year, maxSubResource

    df <- L201.region_basin_home %>%
      dplyr::left_join(dfraw %>%
                         tidyr::gather(key="year",value="maxSubResource",-id,-name) %>%
                         dplyr::filter(year %in% c(1975,1990,seq(2005,2100,by=5))) %>%
                         dplyr::rename(basin_id=id),by="basin_id") %>%
      dplyr::mutate(sub.renewable.resource="runoff")%>%
      dplyr::select(id=basin_id,region=region,renewresource=basin_name, sub.renewable.resource, year,maxSubResource);

    df %>% dplyr::filter(is.na(renewresource), year==1975)
    df %>% dplyr::filter(year==1975) %>% nrow()
    df %>% dplyr::filter(region=="USA",year==1975)%>%dplyr::arrange(renewresource)
    df %>% dplyr::filter(region=="China",year==1975)%>%dplyr::arrange(renewresource)
    df %>% dplyr::filter(region=="Southeast Asia",year==1975)%>%dplyr::arrange(renewresource)
    df %>% dplyr::filter(renewresource=="Hong-Red River")%>%dplyr::arrange(renewresource)
    df$year%>%unique()
  }

  # Save as xml
  if(T){
    # Use header: GrdRenewRsrcMaxNoFillOut from .\input\gcamdata\inst\extdata\mi_headers\ModelInterface_headers

    if(is.null(out_dir)){
      out_dirx <- dirname(xanthos_runoff_csv)
    } else if (dir.exists(out_dir)){
      out_dirx  <- out_dir
    } else {
      print(paste0("out_dir provided does not exist: ", out_dir))
      print(paste0("Saving in : ", dirname(xanthos_runoff_csv)))
      out_dirx <- dirname(xanthos_runoff_csv)
    }


    fname <- paste0(out_dirx,"/",gsub(".csv",".xml",basename(xanthos_runoff_csv))); fname

    gcamdata::create_xml(fname) %>%
      gcamdata::add_xml_data(df, "GrdRenewRsrcMaxNoFillOut")%>%
      gcamdata::run_xml_conversion()

    print(paste0("File saved as ",fname))
  }


  print("Finished xanthos_gcam_create_xml.")

  invisible(df)

}




#' xanthos_npy_expand
#'
#' This function expands a base npy file to match the dimensions of a given npy file.
#' Used to expand example xanthos climate data to run with wrf data for the US.
#' @param base_npy Default = NULL. Base .npy file to expand
#' @param base_year_month_start Default = NULL
#' @param target_npy Default = NULL. Target .npy file to expand to.
#' @param target_year_month_start Default = NULL
#' @param end_year Default = NUll. Last year to process data till. If NULL will use last complete year.
#' @param out_dir Default = NULL. Path to folder to save outputs in.
#' @importFrom magrittr %>%
#' @export

xanthos_npy_expand <- function(base_npy = NULL,
                               base_year_month_start=NULL,
                               target_npy = NULL,
                               target_year_month_start = NULL,
                               end_year = NULL,
                               out_dir = NULL) {


  print("Starting xanthos_npy_expand...")

  # Check that files exist
  if(!file.exists(base_npy)){stop(paste0("base_npy file provided does not exist: ", base_npy))}
  if(!file.exists(target_npy)){stop(paste0("target_npy file provided does not exist: ", target_npy))}

  # Read in .npy files using reticulate
  np <- reticulate::import("numpy",convert=FALSE)
  base_npyx <- np$load(base_npy)
  base_npyr <- reticulate::py_to_r(base_npyx)
  base_df <- tibble::as_tibble(base_npyr)
  target_npyx <- np$load(target_npy)
  target_npyr <- reticulate::py_to_r(target_npyx)
  target_df <- tibble::as_tibble(target_npyr)
  is.na(target_df)<-sapply(target_df, is.infinite)

  # Make sure base_npy and target_npy have same number of rows
  if(nrow(base_df)!=nrow(target_df)){stop("base_npy and target_npy must have same number of rows.")}

  # Create base names
  base_start_year <- as.integer(unlist(strsplit(base_year_month_start,"_"))[[1]]); base_start_year
  base_end_year <- base_start_year + round(ncol(base_df)/12); base_end_year
  base_names <- sort(outer(as.character(c(base_start_year:base_end_year)),
                            c("_01","_02","_03","_04","_05","_06","_07","_08","_09","_10","_11","_12"),
                            FUN="paste0"))[1:ncol(base_df)]; base_names

  # Create target names
  target_start_year <- as.integer(unlist(strsplit(target_year_month_start,"_"))[[1]]); target_start_year
  target_end_year <- target_start_year + round(ncol(target_df)/12); target_end_year
  target_names <- sort(outer(as.character(c(target_start_year:target_end_year)),
                           c("_01","_02","_03","_04","_05","_06","_07","_08","_09","_10","_11","_12"),
                           FUN="paste0"))[1:ncol(target_df)]; target_names
  target_end_year_month_orig = target_names[length(target_names)]; target_end_year_month_orig

  # Remove last year if not complete with all months
  if(!any(grepl(paste0(target_end_year,"_12"),target_names))){
    target_names <- target_names[!grepl(target_end_year,target_names)]
    target_df <- target_df[,1:length(target_names)]
    print("Removing final year because it does not have all 12 months.")
  }


  # Assign names to base_npy
  names(base_df)  <- base_names
  names(target_df) <- target_names

  # Subset base_df based on available columns in target_npy
  base_df_subset <- base_df[,names(base_df) %in% target_names]

  # Expand cols of base_df to repeat final year_month till end of target_year_name
  missing_names <- target_names[!target_names %in% base_names]; missing_names
  base_df_expand <- base_df_subset
  base_df_expand_10yrmean <- base_df_expand %>%
    mutate(id=1:n()) %>%
    tidyr::gather(key="key",value="value", -id) %>%
    dplyr::filter(key %in% base_names[max(1,(length(base_names)-12*10), na.rm=T):length(base_names)]) %>%
    dplyr::group_by(id)%>%
    dplyr::summarize(value=mean(value,na.rm=T)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-id);
  base_df_expand_10yrmean
  for(name_i in missing_names){
  base_df_expand <- base_df_expand %>%
    dplyr::bind_cols(base_df_expand_10yrmean %>%
                       magrittr::set_colnames(name_i))
  }
  base_df_expand[,c((ncol(base_df_expand)-5):ncol(base_df_expand))]

  # Check that ncol in target_df and base_df_expand is the same
  if(ncol(target_df)!=ncol(base_df_expand)){stop(paste0("target_df and base_df_expand must have the same number of cols."))}
  if(nrow(target_df)!=nrow(base_df_expand)){stop(paste0("target_df and base_df_expand must have the same number of rows."))}

  # Create out_df with na data from target_df replaced with base_df_subset data
  out_df <- purrr::map2_dfc(target_df, base_df_expand, dplyr::coalesce)

  # Save as npy
  if(T){

    if(is.null(out_dir)){
      out_dirx <- dirname(target_npy)
    } else if (dir.exists(out_dir)){
      out_dirx  <- out_dir
    } else {
      dir.create(out_dir)
      out_dirx <- out_dir
    }

    fname <- paste0(out_dirx,"/",gsub(".npy","_us_global.npy",basename(target_npy))); fname
    if(!grepl(target_end_year,target_names)){
      if(grepl(target_end_year,fname)){
        fname <- gsub(target_end_year_month_orig,paste0((target_end_year-1),"_12"),fname)
      }
    }
    np$save(fname, as.matrix(out_df))
    print(paste0("File saved as ",fname))
  }


  print("Finished xanthos_npy_expand.")

  invisible(list(base_df=base_df, target_df=target_df,out_df=out_df))

}
