print("Running wrf_to_xanthos_preprocess.R ...")

# Initialize
library(im3components)

# Parallel Arguments from Command Line
# Where args[1] is a list of files to be read
# Where args[2] is a count number
args <- commandArgs(trailingOnly = TRUE)
ncdf_path_i <- args[1:(length(args)-1)]
out_dir_i=paste0('output_wrf_to_xanthos_process_ssp5_hot_near_R_',args[length(args)])
print(paste0("Running files from args[1]: ", paste(ncdf_path_i,collapse=", ")))
print(paste0("Saving to from args[length(args)]: ", out_dir_i))

# Internal Arguments
target_grid_i = "C:/Z/models/xanthos/example/input/reference/coordinates.csv"
params_i = c("RAINC","Q2","PSFC","T2","GLW","SWDOWN","V10","U10")
save_i = T
ncdf_resampled_i = im3components::data_ncdf_resampled_wrf_xanthos
aggregation_method_i = "mean"


# Run script
im3components::resample_wrf_hourly_to_month(
  ncdf_path = ncdf_path_i,
  target_grid = target_grid_i,
  params = params_i,
  aggregation_method = aggregation_method_i,
  out_dir= out_dir_i,
  save = save_i,
  ncdf_resampled = ncdf_resampled_i)
