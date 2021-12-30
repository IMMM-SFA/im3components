#!/bin/bash
# This is the script for the pre-process for the WRF data. 
# Step 1: delete the overlap inforamtion, i.e., the last time step in each file (ncks);
# Step 2: split the files with two-month information, to make sure each file only contain one-month information (ncks);
# Step 3: Concatenate variables across the same month, i.e., each file has one full month data (ncrcat). 

mon=( 01 02 03 04 05 06 07 08 09 10 11 12 01)
nday=(31 28 31 30 31 30 31 31 30 31 30 31 31)
date=(29 26 26 30 28 25 30 27 24 29 26 24 29)

path1=/global/cscratch1/sd/wangly/wrfout/ori/  # directory for input: the origional WRF data
path2=/global/cscratch1/sd/wangly/wrfout/mon/  # directory for output: one file for each month

cd $path1
mkdir old
for year in `seq -w 1980 2004`
do
  now=$(date +"%T")
  echo "Current time : $now"
  let yrm=${year}%4
  echo "${year}"
  for (( i=0;i<=11;i++))
  do
    echo "${mon[$i]}"
    let year2=${year}+1
    let fhour1=(${nday[$i]}-${date[$i]}+1)*24-2
    let fhour2=(${nday[$i]}-${date[$i]}+1)*24-1
    fhour3=167
    if [ $yrm -eq 0 ]
    then
      if [ $i -eq 1 ]
      then 
        fhour2=95 
      fi
      if [ $i -eq 2 ] 
      then 
	date[$i]=25
	let fhour1=(${nday[$i]}-${date[$i]}+1)*24-2
	let fhour2=(${nday[$i]}-${date[$i]}+1)*24-1
        fhour3=191 
      fi
    else
      if [ $i -eq 1 ]
      then 
        fhour2=71
      fi
      if [ $i -eq 2 ] 
      then 
	date[$i]=26
	let fhour1=(${nday[$i]}-${date[$i]}+1)*24-2
	let fhour2=(${nday[$i]}-${date[$i]}+1)*24-1
        fhour3=167
      fi
    fi	  
    ii=i+1
    mv wrfout_d01_${year}-${mon[$i]}-${date[$i]}_01:00:00 old
    ncks -d Time,0,${fhour1} old/wrfout_d01_${year}-${mon[$i]}-${date[$i]}_01:00:00 wrfout_d01_${year}-${mon[$i]}-${nday[$i]}_01:00:00 # Step 1
    if [ $i -lt 11 ]
    then
      ncks -d Time,${fhour2},${fhour3} old/wrfout_d01_${year}-${mon[$i]}-${date[$i]}_01:00:00 wrfout_d01_${year}-${mon[$ii]}-01_00:00:00 # Step 2
    else
      ncks -d Time,191,191 old/wrfout_d01_${year}-${mon[$i]}-${date[$i]}_01:00:00 wrfout_d01_${year2}-${mon[$ii]}-01_00:00:00
    fi	
    ncrcat ${path1}wrfout_d01_${year}-${mon[$i]}-* ${path2}wrfout_d01_${year}-${mon[$i]}.nc # Step 3
  done
done

echo "Done!"
now=$(date +"%T")
echo "Current time : $now"
