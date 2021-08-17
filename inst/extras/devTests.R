# Test functions and scripts

library(im3components)

#...........................
# wrf_xanthos_resample
#..........................

if(T){

ncdf_path_i = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-01_00-00-00.nc")
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-08_01-00-00.nc")
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_1979-01-01_00-00-00.nc")
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData")
target_grid_i = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
params_i = c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
out_dir_i='output'
save_i = T
ncdf_resampled_i = im3components::data_ncdf_resampled_wrf_xanthos
aggregation_method_i = c("mean","mean","mean","mean","mean","mean","mean","mean")

im3components::resample_wrf_hourly_to_month(
  ncdf_path = ncdf_path_i,
  target_grid = target_grid_i,
  params = params_i,
  aggregation_method = aggregation_method_i,
  out_dir= out_dir_i,
  save = save_i,
  ncdf_resampled = ncdf_resampled_i)->a

# Plot Map to View Data
library(dplyr); library(rmap)
a
a1 <- a%>%dplyr::filter(param=="RAINC")%>%unique()%>%dplyr::rename(x=month)
a2 <- a1%>%dplyr::distinct() %>% dplyr::filter(value!=0); a2
rmap::map(a2,
          save=F,
          legendSingleValue = T,
          overLayer=rmap::mapCountriesUS52,
          overLayerLwd = 0.5,
          palette = "pal_wet",
          theme=ggplot2::theme_gray())

# Test internal wrf_xanthos_resample functions:
# im3components::resample_wrf_to_df(
#   ncdf_path = ncdf_path_i,
#   target_grid = target_grid_i,
#   params = params_i,
#   out_dir= out_dir_i,
#   save = save_i,
#   ncdf_resampled = ncdf_resampled_i)->x
}


# Projections of ncdf data and Xanthos
if(T){
library(ncdf4)
library(raster)
library(tibble)
library(ggplot2)
library(ggrepel)

# Initialize ------------------------------------------------------------
ncdf_path = paste0("wrfout_d01_2009-01-01_00-00-00.nc")
target_grid = "xanthos_coordinates.csv"
param_i="LU_INDEX"


# Original ncdf ------------------------------------------------------------
nc <- ncdf4::nc_open(ncdf_path)
variables <- paste(attributes(nc$var)$names,collapse=", "); variables
ncdf_lon <- raster::raster(ncdf_path, varname="XLONG") # Get Lat
ncdf_lat <- raster::raster(ncdf_path, varname="XLAT") # Get Lon
ncdf_raster <- raster::raster(ncdf_path, varname=param_i); ncdf_raster
ncdf_brick <- raster::brick(ncdf_path, varname=param_i); ncdf_brick

# Target Grid ------------------------------------------------------------
ncdf_grid <- data.frame(coordinates(ncdf_raster),
                        lon = as.vector(ncdf_lon),
                        lat = as.vector(ncdf_lat),
                        value = values(ncdf_brick$X169)) %>%
  tibble::as_tibble(); ncdf_grid

target_grid_i <- data.table::fread(target_grid, header=F) %>%
  tibble::as_tibble() %>%
  dplyr::select(lon=V2,lat=V3,gridid=V1,lonid=V4,latid=V5)

usBasinsAlt = c(229,23,227,232,233,228,218,223,220,
                222,217,221,224,219,230,226,225,231,221)

labels_df = rmap::mapGCAMBasins@data %>%
  tibble::as_tibble() %>%
  dplyr::bind_cols(coordinates(rmap::mapGCAMBasins) %>%
                     tibble::as_tibble() %>% dplyr::rename(lon=V1,lat=V2))%>%
  dplyr::filter(subRegionAlt %in% usBasinsAlt)

map_df = argus::mapGCAMBasinsdf %>%
  dplyr::filter(subRegionAlt %in% usBasinsAlt)

ggplot() +
  theme_bw() +
  coord_sf(xlim = c(-140,-60), ylim = c(20,60)) +
  geom_point(data = ncdf_grid %>% dplyr::filter(value>0),
             aes(x = lon, y = lat, color=value, group = NULL),
             size = 0.1, alpha=1) +
  scale_colour_viridis_c() +
  geom_point(data = target_grid_i,
             aes(x = lon, y = lat, group = NULL), color="pink",
             size = 0.7, alpha=1) +
  geom_polygon(data=argus::mapUS49df, aes(x = long, y = lat, group = group),
               colour = "black", lwd=1,fill=NA) +
  geom_polygon(data=map_df, aes(x = long, y = lat, group = group),
               colour = "red", lwd=1,fill=NA) +
  ggrepel::geom_label_repel(data=labels_df, aes(x = lon, y = lat, group = subRegion, label =subRegion),
                            colour = "black", size=4, alpha=0.8)


# Try to convert to another projection and plot
# https://epsg.io/102009
# ncdf_crs = "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
# ncdf_crs = "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs"
# https://epsg.io/4326
# target_crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
# df_i = target_grid_i %>% dplyr::select(lon,lat) %>% head(10)
# xy = df_i; xy
# spdf <- SpatialPointsDataFrame(coords = xy, data = df_i,
#                                proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
# spdfx <- spTransform(spdf,CRSobj=CRS("+proj=longlat +datum=NAD27 +no_defs"))
# plot(spdf,size=1)
# plot(spdfx,col="red", pch=19, size=0.5, add=T)
#
# df <- as.data.frame(spdf);df
# dfx<- as.data.frame(spdfx);dfx
# target_grid_i

# ON NERSC
# library(im3components)
# ncdf_path = paste0("/global/cfs/cdirs/m2702/gsharing/CONUS_PGW_WRF_1979_Sample")
# target_grid = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
# params = c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
# out_dir='output_wrf_to_xanthos_process_R_sample'
# save = T
# ncdf_resampled= im3components::data_ncdf_resampled_wrf_xanthos
# aggregation_method = "mean"

}


#...........................
# xanthos_gcam_create_xml
#..........................

if(T){

  xanthos_runoff_csv_i = "C:/Z/models/00tests/xanthosGlobalRuns/Basin_runoff_km3peryear_pm_abcd_mrtm_noresm1-m_rcp8p5_1950_2099.csv"
  gcamdata_folder_i = "C:/Z/models/GCAMVersions/gcam-usa-im3/input/gcamdata"
  out_dir_i = "C:/Z/models/00tests/"

  xanthos_gcam_create_xml (xanthos_runoff_csv = xanthos_runoff_csv_i,
                           gcamdata_folder = gcamdata_folder_i,
                           out_dir = out_dir_i)

}

#.......................
# reticulate
#.......................
#install.packages('Rcpp')
#install.packages("reticulate")
# library(Rcpp)
# library(reticulate)
# np <- import("numpy",convert=FALSE)

base_npy_list = list("C:/Z/models/00tests/xanthos_im3_test/example/input/climate/pr_gpcc_watch_monthly_mmpermth_1971_2001.npy")
target_npy_list = list("C:/Z/models/00tests/xanthos_im3_test/example/input/climate/pr_gpcc_watch_monthly_mmpermth_1971_2001.npy")
base_year_month_start_i = "1971_01"
target_year_month_start_i = "1979_01"
out_dir_i = "output"

for(i in 1:length(base_npy_list)){

  base_npy_i = base_npy_list[[i]]
  target_npy_i = target_npy_list[[i]]

im3components::xanthos_npy_expand(
  base_npy =base_npy_i,
  base_year_month_start = base_year_month_start_i,
  target_npy = target_npy_i,
  target_year_month_start = target_year_month_start_i,
  out_dir = out_dir_i
)
}
