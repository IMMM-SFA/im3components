library(raster)
library(ncdf4)

args <- commandArgs(trailingOnly = TRUE)

idx <- as.numeric(args[[1]])

# existing urban file from Chen et al.; just for a template
ncfname <- '/pic/projects/im3/mcmanamay/inputs/demeter/harmonized_netcdf/LU_harmonized_ssp1_rcp26_gfdl_2005.nc'
nc1 <- nc_open(ncfname)
PFT31m <- ncvar_get(nc1, "PFT31")
PFT31<- raster(PFT31m, xmn=-180, xmx=180, ymn=-90, ymx=90, crs="+proj=longlat +datum=WGS84 +no_defs")


# pass in using where index is from slurm array id:   Rscript convert_select_1km_to_90p05.R 1
l <- list(	"ssp1_2010",	"ssp1_2020",	"ssp1_2030",	"ssp1_2040",	"ssp1_2050",	"ssp1_2060",	"ssp1_2070",	"ssp1_2080",	"ssp1_2090",	"ssp2_2010",	"ssp2_2020",	"ssp2_2030",	"ssp2_2040",	"ssp2_2050",	"ssp2_2060",	"ssp2_2070",	"ssp2_2080",	"ssp2_2090",	"ssp3_2010",	"ssp3_2020",	"ssp3_2030",	"ssp3_2040",	"ssp3_2050",	"ssp3_2060",	"ssp3_2070",	"ssp3_2080",	"ssp3_2090",	"ssp4_2010",	"ssp4_2020",	"ssp4_2030",	"ssp4_2040",	"ssp4_2050",	"ssp4_2060",	"ssp4_2070",	"ssp4_2080",	"ssp4_2090",	"ssp5_2010",	"ssp5_2020",	"ssp5_2030",	"ssp5_2040",	"ssp5_2050",	"ssp5_2060",	"ssp5_2070",	"ssp5_2080",	"ssp5_2090")

val <- l[[idx]]
ssp <- substr(val, 1, 4)
start_yr = as.numeric(substr(val, 6, 10))
through_yr = start_yr + 10

root_dir <- "/pic/projects/im3/mcmanamay/inputs/select"

# Jing Gao's data; https://www.ciesin.columbia.edu/data/lulc-1-km-downscaled-urban-land-extent-projection-base-year-ssp-2000-2100/
input_dir <- file.path(root_dir, '1km-downscaled-data-geotiff-preliminary-release', 'UrbanFraction_1km_GEOTIFF_Projections_SSPs1-5_2010-2100_v1')
output_dir <- file.path(root_dir, 'processed_to_0p05')

# calculate through year
through_yr <- start_yr + 10

# bring in 2080 and 2090 to calculate 2085 (mean(2080, 2090))
sname1 <- file.path(input_dir, paste0(ssp, "_", start_yr, ".tif"))
sname2 <- file.path(input_dir, paste0(ssp, "_", through_yr, ".tif"))

# load as rasters
s1 <- raster(sname1)
s2 <- raster(sname2)

# align select base with demeter base (multiplying by a factor of 6 to aggregate to demeter resolution)
s1.sum <- aggregate(x = s1, fact=6, fun=mean)
s1.sum <- projectRaster(s1.sum, PFT31, method="bilinear")

s2.sum <- aggregate(x = s2, fact=6, fun=mean)
s2.sum <- projectRaster(s2.sum, PFT31, method="bilinear")

# calculate half step
s1.5 <- (s1.sum + s2.sum)/2

# write outputs
if (start_yr == 2010) {
  writeRaster(s1.sum, file=file.path(output_dir, paste0("Select", "_", ssp, "_", start_yr, "_sum.tif")), datatype='FLT4S', format="GTiff")
}

writeRaster(s2.sum, file=file.path(output_dir, paste0("Select", "_", ssp, "_", through_yr, "_sum.tif")), datatype='FLT4S', format="GTiff")
writeRaster(s1.5, file=file.path(output_dir, paste0("Select", "_", ssp, "_", start_yr + 5, "_sum.tif")), datatype='FLT4S', format="GTiff")
