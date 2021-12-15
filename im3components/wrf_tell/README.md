# Running wrf_tell Scripts on NERSC
>
This page contains instructions for running the sequence of processing scripts that convert the meteorology from IM3's climate simulations using the Weather Research and Forecasting (WRF) model into input files ready for use in the Total ELectricity Load (TELL) model. The first step in the processing chain, wrf_tell_counties.py, spatially averages the gridded meteorology output from WRF into county-mean values. The output of that processing step is a series of .csv files (one for every hour processed) with the county-mean value of six meteorological variables: T2, Q2, U10, V10, SWDOWN, and GLW. The second step, wrf_tell_balancing_authorities.py, then takes these county-level hourly values and population-weights them into an annual time-series for each of the balancing authorities used in the TELL model. As the WRF data is currently stored on NERSC this processing chain is currently configured to work on that platform. For each step in the processing chain there is an associated slurm script that will launch the processing step on NERSC.
>
## To run the wrf_tell_counties.py step:
1. Download the python scripts by making a local clone of the wrf_tell_ba branch of the im3components repository.

2. Find the “launch_counties.sl” slurm script in the wrf_tell folder. Open the script in your favorite text editor and make the following changes:
  * Set the “-A” account flag to m2702 (IM3’s NERSC account number)
  * Set the “-t” time flag to 15 hrs (a conservative estimate of the processing time for a 40-year period run of this processing step). Note that you can get through the NERSC queue faster if you break this step down into decadal increments. Each decade takes around 3 hours to run. To run this first processing step on a single decade instead of all the WRF output files in a given directory change the last line of the slurm script to, for example, “…/wrfout_d01_2040*”
  * Set the “--job-name” flag to something consistent with the period being processed.
  * Set the “--mail-user” flag to your email address.
  * The “--p” queue flag is set to “regular” by default. If you want to do a quick run to make sure the script is working properly you can set this to “debug” and drop the runtime down to something small (e.g., 5-10 minutes). This will run the script using NERSC's debug queue which is much faster. Note that there is a hard 30-minute runtime limit on the debug queue.
  * Set the paths in the srun section:
    * “--shapefile-path” should point to the county boundaries shapefile
    * “--weights-file-path” should point to the grid_cell_to_county_weight.parquet file
    * “--output_directory” should point to where you want to store the output files (see the tables below)
    * The final line of the slurm script should point to the directory where the WRF output files are stored (see the tables below)
  * After these changes the “launch_counties.sl” script should look something like this:

![Lauch Counties](images/launch_counties_completed.png)

3. Make sure your changes are saved. Log on to NERSC and upload all the files from the wrf_tell folder to a folder on your scratch user directory on NERSC (e.g., my scratch user directory is /global/cscratch1/sd/cburley/). You should also upload the “tl_2020_us_county.shp” file to the same directory as the code needs this shapefile to run.

4. Execute the following commands from your scratch directory on NERSC where you will submit the job (you shouldn’t run jobs from your home directory on NERSC):
```
module load python
sbatch launch_counties.sl
```

5. You can check the status of your job by running the command ```squeue --me```. You should also get email confirmations when the job starts, ends, or fails.

![Input Directories](images/directories_one.png)

