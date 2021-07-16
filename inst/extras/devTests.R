# Test functions and scripts

library(im3components)

#...........................
# wrf_xanthos_resample
#..........................

if(T){
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-01_00-00-00.nc")
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData/wrfout_d01_2009-01-08_01-00-00.nc")
target_grid_i = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
params_i = c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
out_dir_i='output'
save_i = T
ncdf_resampled_i = im3components::data_ncdf_resampled_wrf_xanthos
ncdf_path_i = paste0("C:/Z/models/xanthosWRFData")
aggregation_method_i = c("mean","mean","mean","mean","mean","mean","mean","mean")

im3components::wrf_xanthos_resample(
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
}
