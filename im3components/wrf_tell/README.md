## Running the wrf_to_tell Scripts on NERSC
>
Bleep boo bleep boo.
>
## To run the wrf_tell_counties.py step:
1. Download the python scripts by making a local clone of the wrf_tell_ba branch of the im3components repository: https://github.com/IMMM-SFA/im3components:

2. From within the wrf_tell folder, find the “launch_counties.sl” slurm script. Open the script in your favorite text editor and make the following changes:
>
   a. Update the “-A” account flag to m2702 (IM3’s NERSC account number)
   b. Update the “-t” time flag to 15 hrs (a conservative estimate of the processing time for a 40-year period run of this processing step). Note that you can get through the queue faster if you break this step down into decade increments. Each decade takes around 3 hours to run. To run on a single decade instead of all the WRF output files in each directory change the last line of the slurm script to “…/wrfout_d01_2040*”
   c. Update the “--job-name” flag to something consistent with the period being processed
   d. Update the “--mail-user” flag to your email address
   e. The “--p” queue flag is set to “regular” by default. If you want to do a quick run to make sure the script is working properly you can set this to “debug” and drop the runtime down to something small (e.g., 5-10 minutes).
   f. Set the paths in the srun section:
      i.  “--shapefile-path” should point to the county boundaries shapefile
      ii. “--weights-file-path” should point to the grid_cell_to_county_weight.parquet file
      iii. “--output_directory” should point to where you want to store the output files (see the tables below)
      iv. The final line of the slurm script should point to the directory where the WRF output files are stored (see the tables below)


