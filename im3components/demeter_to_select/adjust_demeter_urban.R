library(raster)
library(ncdf4)
library(maptools) #
library(maps) #
library(rgdal)
library(dplyr)
library(tools)
library(tibble)


# from SLURM array id
args <- commandArgs(trailingOnly = TRUE)

idx <- as.numeric(args[[1]])

# input paths
select_input_dir <- "/pic/projects/im3/mcmanamay/inputs/select/processed_to_0p05"
demeter_input_dir <- "/pic/projects/im3/mcmanamay/inputs/demeter"

csv_filenames <- "/pic/projects/im3/mcmanamay/inputs/reference/IDX_Variable_List_FileNames.csv"
demeter_base_file <- file.path(demeter_input_dir, 'demeter_input_files', 'baselayerdata_region_basin_0.05deg.csv')

# output paths
demeter_output_dir <- "/pic/projects/im3/mcmanamay/outputs"
output_demeter_base_raster <- file.path(demeter_input_dir, 'demeter_input_files', 'baselayerdata_region_basin_0.05deg.tif')

# method from Chen et al.
demeter_method <- 'harmonized_netcdf'


# files to process
df_csv_select <- read.csv(csv_filenames)

# construct file names from index; [row, col]
select_file_name <- as.character(df_csv_select[idx, 1])
demeter_file_name <- as.character(df_csv_select[idx, 2])
select_file_path <- file.path(select_input_dir, select_file_name)
demeter_file_path <- file.path(demeter_input_dir, demeter_method, demeter_file_name)

# output summary file name
output_file_name <- paste0(tools::file_path_sans_ext(demeter_file_name), ".csv")
output_summary_file <- file.path(demeter_output_dir, output_file_name)

# read in datasets
s1 <- raster(select_file_path)
nc1 <- nc_open(demeter_file_path)

s1_area <- area(s1)

# create a list of PFTs
pfts = seq(from = 0, to = 32, by = 1)

PFT0m <- ncvar_get(nc1, "PFT0")
PFT1m <- ncvar_get(nc1, "PFT1")
PFT2m <- ncvar_get(nc1, "PFT2")
PFT3m <- ncvar_get(nc1, "PFT3")
PFT4m <- ncvar_get(nc1, "PFT4")
PFT5m <- ncvar_get(nc1, "PFT5")
PFT6m <- ncvar_get(nc1, "PFT6")
PFT7m <- ncvar_get(nc1, "PFT7")
PFT8m <- ncvar_get(nc1, "PFT8")
PFT9m <- ncvar_get(nc1, "PFT9")
PFT10m <- ncvar_get(nc1, "PFT10")
PFT11m <- ncvar_get(nc1, "PFT11")
PFT12m <- ncvar_get(nc1, "PFT12")
PFT13m <- ncvar_get(nc1, "PFT13")
PFT14m <- ncvar_get(nc1, "PFT14")
PFT15m <- ncvar_get(nc1, "PFT15")
PFT16m <- ncvar_get(nc1, "PFT16")
PFT17m <- ncvar_get(nc1, "PFT17")
PFT18m <- ncvar_get(nc1, "PFT18")
PFT19m <- ncvar_get(nc1, "PFT19")
PFT20m <- ncvar_get(nc1, "PFT20")
PFT21m <- ncvar_get(nc1, "PFT21")
PFT22m <- ncvar_get(nc1, "PFT22")
PFT23m <- ncvar_get(nc1, "PFT23")
PFT24m <- ncvar_get(nc1, "PFT24")
PFT25m <- ncvar_get(nc1, "PFT25")
PFT26m <- ncvar_get(nc1, "PFT26")
PFT27m <- ncvar_get(nc1, "PFT27")
PFT28m <- ncvar_get(nc1, "PFT28")
PFT29m <- ncvar_get(nc1, "PFT29")
PFT30m <- ncvar_get(nc1, "PFT30")
PFT31m <- ncvar_get(nc1, "PFT31")
PFT32m <- ncvar_get(nc1, "PFT32")

PFT0<- raster(PFT0m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT0m)
PFT1<- raster(PFT1m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT1m)
PFT2<- raster(PFT2m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT2m)
PFT3<- raster(PFT3m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT3m)
PFT4<- raster(PFT4m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT4m)
PFT5<- raster(PFT5m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT5m)
PFT6<- raster(PFT6m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT6m)
PFT7<- raster(PFT7m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT7m)
PFT8<- raster(PFT8m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT8m)
PFT9<- raster(PFT9m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT9m)
PFT10<- raster(PFT10m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT10m)
PFT11<- raster(PFT11m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT11m)
PFT12<- raster(PFT12m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT12m)
PFT13<- raster(PFT13m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT13m)
PFT14<- raster(PFT14m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT14m)
PFT15<- raster(PFT15m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT15m)
PFT16<- raster(PFT16m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT16m)
PFT17<- raster(PFT17m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT17m)
PFT18<- raster(PFT18m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT18m)
PFT19<- raster(PFT19m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT19m)
PFT20<- raster(PFT20m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT20m)
PFT21<- raster(PFT21m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT21m)
PFT22<- raster(PFT22m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT22m)
PFT23<- raster(PFT23m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT23m)
PFT24<- raster(PFT24m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT24m)
PFT25<- raster(PFT25m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT25m)
PFT26<- raster(PFT26m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT26m)
PFT27<- raster(PFT27m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT27m)
PFT28<- raster(PFT28m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT28m)
PFT29<- raster(PFT29m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT29m)
PFT30<- raster(PFT30m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT30m)
PFT31<- raster(PFT31m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT31m)
PFT32<- raster(PFT32m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT32m)

# adjust s1.sum for existing urban
s1d <- (s1 - PFT31/100)

# total fraction - urban
TF <- 100 - PFT31

# TODO:  ask Ryan about the difference in adjusting the total PFT versus doing this on a gridcell or region by region approach
# adjustign for increase or decrease proportionally in each PFT
PFT0 <- round((PFT0/100 - (PFT0/TF)*(s1d))*100)
PFT1 <- round((PFT1/100 - (PFT1/TF)*(s1d))*100)
PFT2 <- round((PFT2/100 - (PFT2/TF)*(s1d))*100)
PFT3 <- round((PFT3/100 - (PFT3/TF)*(s1d))*100)
PFT4 <- round((PFT4/100 - (PFT4/TF)*(s1d))*100)
PFT5 <- round((PFT5/100 - (PFT5/TF)*(s1d))*100)
PFT6 <- round((PFT6/100 - (PFT6/TF)*(s1d))*100)
PFT7 <- round((PFT7/100 - (PFT7/TF)*(s1d))*100)
PFT8 <- round((PFT8/100 - (PFT8/TF)*(s1d))*100)
PFT9 <- round((PFT9/100 - (PFT9/TF)*(s1d))*100)
PFT10 <- round((PFT10/100 - (PFT10/TF)*(s1d))*100)
PFT11 <- round((PFT11/100 - (PFT11/TF)*(s1d))*100)
PFT12 <- round((PFT12/100 - (PFT12/TF)*(s1d))*100)
PFT13 <- round((PFT13/100 - (PFT13/TF)*(s1d))*100)
PFT14 <- round((PFT14/100 - (PFT14/TF)*(s1d))*100)
PFT15 <- round((PFT15/100 - (PFT15/TF)*(s1d))*100)
PFT16 <- round((PFT16/100 - (PFT16/TF)*(s1d))*100)
PFT17 <- round((PFT17/100 - (PFT17/TF)*(s1d))*100)
PFT18 <- round((PFT18/100 - (PFT18/TF)*(s1d))*100)
PFT19 <- round((PFT19/100 - (PFT19/TF)*(s1d))*100)
PFT20 <- round((PFT20/100 - (PFT20/TF)*(s1d))*100)
PFT21 <- round((PFT21/100 - (PFT21/TF)*(s1d))*100)
PFT22 <- round((PFT22/100 - (PFT22/TF)*(s1d))*100)
PFT23 <- round((PFT23/100 - (PFT23/TF)*(s1d))*100)
PFT24 <- round((PFT24/100 - (PFT24/TF)*(s1d))*100)
PFT25 <- round((PFT25/100 - (PFT25/TF)*(s1d))*100)
PFT26 <- round((PFT26/100 - (PFT26/TF)*(s1d))*100)
PFT27 <- round((PFT27/100 - (PFT27/TF)*(s1d))*100)
PFT28 <- round((PFT28/100 - (PFT28/TF)*(s1d))*100)
PFT29 <- round((PFT29/100 - (PFT29/TF)*(s1d))*100)
PFT30 <- round((PFT30/100 - (PFT30/TF)*(s1d))*100)
PFT31 <- round(s1*100)
PFT32 <- round((PFT32/100 - (PFT32/TF)*(s1d))*100)


dname <- "land class percentage"
lat<- ncvar_get(nc1, "latitude")
long <- ncvar_get(nc1, "longitude")

x <- ncdim_def("Longitude", "decimal degrees", long)
y <- ncdim_def("Latitude", "decimal degrees", lat)

PFT0_def <- ncvar_def("PFT0", "Percentage", list(x,y), longname=dname, prec="integer")
PFT1_def <- ncvar_def("PFT1", "Percentage", list(x,y), longname=dname, prec="integer")
PFT2_def <- ncvar_def("PFT2", "Percentage", list(x,y), longname=dname, prec="integer")
PFT3_def <- ncvar_def("PFT3", "Percentage", list(x,y), longname=dname, prec="integer")
PFT4_def <- ncvar_def("PFT4", "Percentage", list(x,y), longname=dname, prec="integer")
PFT5_def <- ncvar_def("PFT5", "Percentage", list(x,y), longname=dname, prec="integer")
PFT6_def <- ncvar_def("PFT6", "Percentage", list(x,y), longname=dname, prec="integer")
PFT7_def <- ncvar_def("PFT7", "Percentage", list(x,y), longname=dname, prec="integer")
PFT8_def <- ncvar_def("PFT8", "Percentage", list(x,y), longname=dname, prec="integer")
PFT9_def <- ncvar_def("PFT9", "Percentage", list(x,y), longname=dname, prec="integer")
PFT10_def <- ncvar_def("PFT10", "Percentage", list(x,y), longname=dname, prec="integer")
PFT11_def <- ncvar_def("PFT11", "Percentage", list(x,y), longname=dname, prec="integer")
PFT12_def <- ncvar_def("PFT12", "Percentage", list(x,y), longname=dname, prec="integer")
PFT13_def <- ncvar_def("PFT13", "Percentage", list(x,y), longname=dname, prec="integer")
PFT14_def <- ncvar_def("PFT14", "Percentage", list(x,y), longname=dname, prec="integer")
PFT15_def <- ncvar_def("PFT15", "Percentage", list(x,y), longname=dname, prec="integer")
PFT16_def <- ncvar_def("PFT16", "Percentage", list(x,y), longname=dname, prec="integer")
PFT17_def <- ncvar_def("PFT17", "Percentage", list(x,y), longname=dname, prec="integer")
PFT18_def <- ncvar_def("PFT18", "Percentage", list(x,y), longname=dname, prec="integer")
PFT19_def <- ncvar_def("PFT19", "Percentage", list(x,y), longname=dname, prec="integer")
PFT20_def <- ncvar_def("PFT20", "Percentage", list(x,y), longname=dname, prec="integer")
PFT21_def <- ncvar_def("PFT21", "Percentage", list(x,y), longname=dname, prec="integer")
PFT22_def <- ncvar_def("PFT22", "Percentage", list(x,y), longname=dname, prec="integer")
PFT23_def <- ncvar_def("PFT23", "Percentage", list(x,y), longname=dname, prec="integer")
PFT24_def <- ncvar_def("PFT24", "Percentage", list(x,y), longname=dname, prec="integer")
PFT25_def <- ncvar_def("PFT25", "Percentage", list(x,y), longname=dname, prec="integer")
PFT26_def <- ncvar_def("PFT26", "Percentage", list(x,y), longname=dname, prec="integer")
PFT27_def <- ncvar_def("PFT27", "Percentage", list(x,y), longname=dname, prec="integer")
PFT28_def <- ncvar_def("PFT28", "Percentage", list(x,y), longname=dname, prec="integer")
PFT29_def <- ncvar_def("PFT29", "Percentage", list(x,y), longname=dname, prec="integer")
PFT30_def <- ncvar_def("PFT30", "Percentage", list(x,y), longname=dname, prec="integer")
PFT31_def <- ncvar_def("PFT31", "Percentage", list(x,y), longname=dname, prec="integer")
PFT32_def <- ncvar_def("PFT32", "Percentage", list(x,y), longname=dname, prec="integer")

# output file path
output_ncdf_file <- file.path(demeter_output_dir, demeter_file_name)

ncout <- nc_create(output_ncdf_file, list(PFT0_def,	PFT1_def,	PFT2_def,	PFT3_def,	PFT4_def,	PFT5_def,	PFT6_def,	PFT7_def,
                              PFT8_def,	PFT9_def,	PFT10_def,	PFT11_def,	PFT12_def,	PFT13_def,	PFT14_def,
                              PFT15_def,	PFT16_def,	PFT17_def,	PFT18_def,	PFT19_def,	PFT20_def,	PFT21_def,
                              PFT22_def,	PFT23_def,	PFT24_def,	PFT25_def,	PFT26_def,	PFT27_def,	PFT28_def,
                              PFT29_def,	PFT30_def,	PFT31_def,	PFT32_def),force_v4=TRUE)

# attempt as size reduction
# TODO:  confirm with Dan et al. about need 0-100 integer percent or as-is as float64
PFT0 <- as.single(PFT0)
PFT1 <- as.single(PFT1)
PFT2 <- as.single(PFT2)
PFT3 <- as.single(PFT3)
PFT4 <- as.single(PFT4)
PFT5 <- as.single(PFT5)
PFT6 <- as.single(PFT6)
PFT7 <- as.single(PFT7)
PFT8 <- as.single(PFT8)
PFT9 <- as.single(PFT9)
PFT10 <- as.single(PFT10)
PFT11 <- as.single(PFT11)
PFT12 <- as.single(PFT12)
PFT13 <- as.single(PFT13)
PFT14 <- as.single(PFT14)
PFT15 <- as.single(PFT15)
PFT16 <- as.single(PFT16)
PFT17 <- as.single(PFT17)
PFT18 <- as.single(PFT18)
PFT19 <- as.single(PFT19)
PFT20 <- as.single(PFT20)
PFT21 <- as.single(PFT21)
PFT22 <- as.single(PFT22)
PFT23 <- as.single(PFT23)
PFT24 <- as.single(PFT24)
PFT25 <- as.single(PFT25)
PFT26 <- as.single(PFT26)
PFT27 <- as.single(PFT27)
PFT28 <- as.single(PFT28)
PFT29 <- as.single(PFT29)
PFT30 <- as.single(PFT30)
PFT31 <- as.single(PFT31)
PFT32 <- as.single(PFT32)


# put data in NetCDF file
ncvar_put(ncout,PFT0_def,PFT0)
ncvar_put(ncout,PFT1_def,PFT1)
ncvar_put(ncout,PFT2_def,PFT2)
ncvar_put(ncout,PFT3_def,PFT3)
ncvar_put(ncout,PFT4_def,PFT4)
ncvar_put(ncout,PFT5_def,PFT5)
ncvar_put(ncout,PFT6_def,PFT6)
ncvar_put(ncout,PFT7_def,PFT7)
ncvar_put(ncout,PFT8_def,PFT8)
ncvar_put(ncout,PFT9_def,PFT9)
ncvar_put(ncout,PFT10_def,PFT10)
ncvar_put(ncout,PFT11_def,PFT11)
ncvar_put(ncout,PFT12_def,PFT12)
ncvar_put(ncout,PFT13_def,PFT13)
ncvar_put(ncout,PFT14_def,PFT14)
ncvar_put(ncout,PFT15_def,PFT15)
ncvar_put(ncout,PFT16_def,PFT16)
ncvar_put(ncout,PFT17_def,PFT17)
ncvar_put(ncout,PFT18_def,PFT18)
ncvar_put(ncout,PFT19_def,PFT19)
ncvar_put(ncout,PFT20_def,PFT20)
ncvar_put(ncout,PFT21_def,PFT21)
ncvar_put(ncout,PFT22_def,PFT22)
ncvar_put(ncout,PFT23_def,PFT23)
ncvar_put(ncout,PFT24_def,PFT24)
ncvar_put(ncout,PFT25_def,PFT25)
ncvar_put(ncout,PFT26_def,PFT26)
ncvar_put(ncout,PFT27_def,PFT27)
ncvar_put(ncout,PFT28_def,PFT28)
ncvar_put(ncout,PFT29_def,PFT29)
ncvar_put(ncout,PFT30_def,PFT30)
ncvar_put(ncout,PFT31_def,PFT31)
ncvar_put(ncout,PFT32_def,PFT32)




ncatt_put(ncout,0, "coordinate_system", "WGS84")
ncatt_put(ncout,0, "creation_date", "02-Jun-2021")
ncatt_put(ncout,0, "Demeter_version", "Demeter V2 and Demeter-Select Integration, Updated from: Vernon, C.R. and M. Chen. (2020, March 17). crvernon/demeter: v1.chen (Version v1.chen). Zenodo. http://doi.org/10.5281/zenodo.3713378")
ncatt_put(ncout, 0, "GCAM_version", "Calvin, Katherine, Patel, Pralit, Clarke, Leon, Asrar, Ghassem, Bond-Lamberty, Ben, Yiyun Cui, Ryna, â€¦ Wise, Marshall. (2020, March 17). crvernon/gcam-core: gcam-v4.3.chen (Version gcam-v4.3.chen). Zenodo. http://doi.org/10.5281/zenodo.3713432")
ncatt_put(ncout, 0, "inputs", "Chen, Min, & Vernon, Chris R. (2020). Demeter Inputs for Chen et al. 2020 [Data set]. Zenodo. http://doi.org/10.5281/zenodo.3713486; Gao, J., and M. Pesaresi. 2020. Global 1-km Downscaled Urban Land Extent Projection and Base Year Grids by SSP Scenarios, 2000-2100 (Preliminary Release). Palisades, NY: NASA Socioeconomic Data and Applications Center (SEDAC). https://doi.org/10.7927/1z4r-ez63")



##### calculate land cover change::  these ARE FROM THE ORIGINAL, change to single load
## converting to Raster then to adjust the PFT 31 to find land cover change delta
PFT0m <- ncvar_get(nc1, "PFT0")
PFT1m <- ncvar_get(nc1, "PFT1")
PFT2m <- ncvar_get(nc1, "PFT2")
PFT3m <- ncvar_get(nc1, "PFT3")
PFT4m <- ncvar_get(nc1, "PFT4")
PFT5m <- ncvar_get(nc1, "PFT5")
PFT6m <- ncvar_get(nc1, "PFT6")
PFT7m <- ncvar_get(nc1, "PFT7")
PFT8m <- ncvar_get(nc1, "PFT8")
PFT9m <- ncvar_get(nc1, "PFT9")
PFT10m <- ncvar_get(nc1, "PFT10")
PFT11m <- ncvar_get(nc1, "PFT11")
PFT12m <- ncvar_get(nc1, "PFT12")
PFT13m <- ncvar_get(nc1, "PFT13")
PFT14m <- ncvar_get(nc1, "PFT14")
PFT15m <- ncvar_get(nc1, "PFT15")
PFT16m <- ncvar_get(nc1, "PFT16")
PFT17m <- ncvar_get(nc1, "PFT17")
PFT18m <- ncvar_get(nc1, "PFT18")
PFT19m <- ncvar_get(nc1, "PFT19")
PFT20m <- ncvar_get(nc1, "PFT20")
PFT21m <- ncvar_get(nc1, "PFT21")
PFT22m <- ncvar_get(nc1, "PFT22")
PFT23m <- ncvar_get(nc1, "PFT23")
PFT24m <- ncvar_get(nc1, "PFT24")
PFT25m <- ncvar_get(nc1, "PFT25")
PFT26m <- ncvar_get(nc1, "PFT26")
PFT27m <- ncvar_get(nc1, "PFT27")
PFT28m <- ncvar_get(nc1, "PFT28")
PFT29m <- ncvar_get(nc1, "PFT29")
PFT30m <- ncvar_get(nc1, "PFT30")
PFT31m <- ncvar_get(nc1, "PFT31")
PFT32m <- ncvar_get(nc1, "PFT32")



PFT0<- raster(PFT0m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT0m)
PFT1<- raster(PFT1m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT1m)
PFT2<- raster(PFT2m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT2m)
PFT3<- raster(PFT3m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT3m)
PFT4<- raster(PFT4m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT4m)
PFT5<- raster(PFT5m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT5m)
PFT6<- raster(PFT6m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT6m)
PFT7<- raster(PFT7m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT7m)
PFT8<- raster(PFT8m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT8m)
PFT9<- raster(PFT9m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT9m)
PFT10<- raster(PFT10m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT10m)
PFT11<- raster(PFT11m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT11m)
PFT12<- raster(PFT12m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT12m)
PFT13<- raster(PFT13m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT13m)
PFT14<- raster(PFT14m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT14m)
PFT15<- raster(PFT15m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT15m)
PFT16<- raster(PFT16m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT16m)
PFT17<- raster(PFT17m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT17m)
PFT18<- raster(PFT18m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT18m)
PFT19<- raster(PFT19m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT19m)
PFT20<- raster(PFT20m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT20m)
PFT21<- raster(PFT21m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT21m)
PFT22<- raster(PFT22m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT22m)
PFT23<- raster(PFT23m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT23m)
PFT24<- raster(PFT24m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT24m)
PFT25<- raster(PFT25m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT25m)
PFT26<- raster(PFT26m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT26m)
PFT27<- raster(PFT27m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT27m)
PFT28<- raster(PFT28m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT28m)
PFT29<- raster(PFT29m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT29m)
PFT30<- raster(PFT30m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT30m)
PFT31<- raster(PFT31m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT31m)
PFT32<- raster(PFT32m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")
rm(PFT32m)


# TODO: Error: object 's1_area' not found

# DIFFERENCE BEGINS HERE

PFT0 <- (PFT0/TF)*s1d*s1_area
PFT1 <- (PFT1/TF)*s1d*s1_area
PFT2 <- (PFT2/TF)*s1d*s1_area
PFT3 <- (PFT3/TF)*s1d*s1_area
PFT4 <- (PFT4/TF)*s1d*s1_area
PFT5 <- (PFT5/TF)*s1d*s1_area
PFT6 <- (PFT6/TF)*s1d*s1_area
PFT7 <- (PFT7/TF)*s1d*s1_area
PFT8 <- (PFT8/TF)*s1d*s1_area
PFT9 <- (PFT9/TF)*s1d*s1_area
PFT10 <- (PFT10/TF)*s1d*s1_area
PFT11 <- (PFT11/TF)*s1d*s1_area
PFT12 <- (PFT12/TF)*s1d*s1_area
PFT13 <- (PFT13/TF)*s1d*s1_area
PFT14 <- (PFT14/TF)*s1d*s1_area
PFT15 <- (PFT15/TF)*s1d*s1_area
PFT16 <- (PFT16/TF)*s1d*s1_area
PFT17 <- (PFT17/TF)*s1d*s1_area
PFT18 <- (PFT18/TF)*s1d*s1_area
PFT19 <- (PFT19/TF)*s1d*s1_area
PFT20 <- (PFT20/TF)*s1d*s1_area
PFT21 <- (PFT21/TF)*s1d*s1_area
PFT22 <- (PFT22/TF)*s1d*s1_area
PFT23 <- (PFT23/TF)*s1d*s1_area
PFT24 <- (PFT24/TF)*s1d*s1_area
PFT25 <- (PFT25/TF)*s1d*s1_area
PFT26 <- (PFT26/TF)*s1d*s1_area
PFT27 <- (PFT27/TF)*s1d*s1_area
PFT28 <- (PFT28/TF)*s1d*s1_area
PFT29 <- (PFT29/TF)*s1d*s1_area
PFT30 <- (PFT30/TF)*s1d*s1_area
PFT31 <- (PFT31/TF)*s1d*s1_area
PFT32 <- (PFT32/TF)*s1d*s1_area
urb <- s1*s1_area

# baser is a raster created from CLM of the grids with the regional codes and basin codes

# Demeter base layer
base <- read.csv(file=demeter_base_file, header=TRUE)

# this would generate a raster from the CSV file but it has already been done
base_xy <- cbind(base$Loncoord, base$Latcoord)
baser <- rasterize(base_xy, PFT0, field=base$fid, fun='last', crs=" +proj=longlat +datum=WGS84 +no_defs")
# writeRaster(baser,file=output_demeter_base_raster, format="GTiff")
extent(baser) <- extent(PFT0)

#baser <- raster(output_demeter_base_raster)


# add's GCAM regions and basins
s1_comp <- stack(baser, PFT0, PFT1,PFT2,PFT3,PFT4,PFT5,PFT6,PFT7, PFT8, PFT9, PFT10,PFT11,PFT12,PFT13,PFT14,PFT15,
                 PFT16,PFT17, PFT18, PFT19, PFT20,PFT21,PFT22, PFT23, PFT24,PFT25, PFT26, PFT27, PFT28, PFT29,
                 PFT30, PFT31, PFT32, urb, s1d)


rm(PFT0, PFT1,PFT2,PFT3,PFT4,PFT5,PFT6,PFT7, PFT8, PFT9, PFT10, PFT11,PFT12,PFT13,PFT14,PFT15,
   PFT16,PFT17, PFT18, PFT19, PFT20,PFT21,PFT22, PFT23, PFT24,PFT25, PFT26, PFT27, PFT28, PFT29,
   PFT30, PFT31, PFT32)


s1_comp.db <- as.data.frame(s1_comp)
s1_comp.db$fid <- s1_comp.db$layer.1

regbas <- cbind(base$fid, base$region_id, base$basin_id)
colnames(regbas) <- c("fid", "region_id", "basin_id")

s1_new <- merge(regbas, s1_comp.db, by="fid", all.x=TRUE)

urb_s1_calc <- s1_new %>%
  group_by(region_id, basin_id) %>%
  summarize(PFT0=sum(layer.2), PFT1=sum(layer.3),	PFT2=sum(layer.4),	PFT3=sum(layer.5),	PFT4=sum(layer.6),	PFT5=sum(layer.7),
            PFT6=sum(layer.8),	PFT7=sum(layer.9),	PFT8=sum(layer.10),	PFT9=sum(layer.11),	PFT10=sum(layer.12),
            PFT11=sum(layer.13),	PFT12=sum(layer.14),	PFT13=sum(layer.15),	PFT14=sum(layer.16),	PFT15=sum(layer.17),
            PFT16=sum(layer.18),	PFT17=sum(layer.19),	PFT18=sum(layer.20),	PFT19=sum(layer.21),	PFT20=sum(layer.22),
            PFT21=sum(layer.23), PFT22=sum(layer.24), PFT23=sum(layer.25), PFT24=sum(layer.26), PFT25=sum(layer.27), PFT26=sum(layer.28),
            PFT27=sum(layer.29), PFT28=sum(layer.30), PFT29=sum(layer.31), PFT30=sum(layer.32), PFT31=sum(layer.33), PFT32=sum(layer.34),
            urban_land=sum(layer.35), urb_delta=sum(layer.36))

# add scenario column to the data frame
urb_s1_calc <- urb_s1_calc %>%
  tibble::add_column(scenario = demeter_file_name, .before = 'region_id')

# write output as a CSV file
write.csv(urb_s1_calc, file = output_summary_file, row.names = FALSE)

