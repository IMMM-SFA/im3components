# Converting raw data into package data
library(usethis)
library(data.table)
library(magrittr)
library(ncdf4)
library(raster)
library(tibble)
library(akima)


# Create Resampling data for Xanthos and WRF
if(T){
ncdf_path = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-01_00-00-00.nc")
target_grid = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
params = c("RAINC")

# Check ncdf file path provided
nc <- ncdf4::nc_open(ncdf_path)
variables <- paste(attributes(nc$var)$names,collapse=", ")
paste0("Variables available: ", variables) # Get Variable Names
ncdf_lon <- raster::raster(ncdf_path, varname="XLONG") # Get Lat
ncdf_lat <- raster::raster(ncdf_path, varname="XLAT") # Get Lon
ncdf_time <-  ncdf4::ncvar_get(nc,"Times")

#........................
# Create Resampling Grid
#........................

  # Create a data frame with coordinates
  # x/y are just indices and represent different points on the target_grid with their own lat/lon
  ncdf_raster <- raster::raster(ncdf_path, varname="XLONG")
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

data_ncdf_resampled_wrf_xanthos <- ncdf_resampled
use_data(data_ncdf_resampled_wrf_xanthos, overwrite=T)


#.............
# Xanthos Coordinates
#..................

coordinates_xanthos_reference = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
data_coordinates_xanthos_reference <- data.table::fread(coordinates_xanthos_reference, header=F) %>% tibble::as_tibble() %>%
  dplyr::select(lon=V2,lat=V3,gridid=V1,lonid=V4,latid=V5); data_coordinates_xanthos_reference
use_data(data_coordinates_xanthos_reference, overwrite=T)


