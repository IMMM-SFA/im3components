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

  if(grepl("data.frame|tbl|tbl_df",class(target_grid))){
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
