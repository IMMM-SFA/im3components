;***********************************************
begin
;************************************************
; The input data is the monthly WRF data produced by the pre-process script "pre_process.sh", which is located in in_dir;
; The output directory is out_dir, it needs NLDAS2 forcing for CLM5 as input and then the script will replace the NLDAS2 forcing with the WRF data.
;************************************************
  varlist1 = (/ "PSFC", "GLW", "T2", "SWDOWN","Q2","U10","RAINNC"/)
  varlist2 = (/ "PSRF", "FLDS", "TBOT", "FSDS","QBOT","WIND","PRECTmms"/) 
  nvar = dimsizes(varlist1)

  ; mask file
  fmask = addfile("/global/cscratch1/sd/wangly/inputdata/cesm_inputdata/share/domains/domain.lnd.conus_0.125_simyr2000.nc","r")
  maskout = fmask->mask
  lat_out = fmask->yc(:,0)
  lon_out = fmask->xc(0,:)
  nlat_out = dimsizes(lat_out)
  nlon_out = dimsizes(lon_out)
  print("output nlat = " + tostring(nlat_out))
  print("output nlon = " + tostring(nlon_out))

  ; input and output file name
  in_dir = "/global/cscratch1/sd/wangly/wrfout/mon/"              ; change in_dir!!!
  out_dir = "/global/cscratch1/sd/wangly/wrfout/forcing/"         ; change out_dir!!!
  infilenames = systemfunc("ls " + in_dir + "wrfout_d01_*")       ; change infilenames!!!
  outfilenames = systemfunc("ls " + out_dir + "*")                ; change infilenames!!!
  nfiles = dimsizes(infilenames)
  print("input file number: " + tostring(nfiles))
  print("")
 
  do ifile = 0, nfiles-1
   
    infile = addfile(infilenames(ifile), "r")
    print(tostring(outfilenames(ifile)))
    lon2d = infile->XLONG(0,:,:)
    lat2d = infile->XLAT(0,:,:)
    lon2d = lon2d+360

    outfile = addfile(outfilenames(ifile), "w")
    time  = outfile->time
    ntime = dimsizes(time)

    do ivar = 0, nvar-1
      varname1 = varlist1(ivar)
      varname2 = varlist2(ivar)
      print("")
      print("var name: " + varname2)
      if (ivar.le.4) then
        var = infile->$varname1$(0:ntime-1,:,:)
      end if
      if (ivar.eq.5) then
        U10 = infile->U10(0:ntime-1,:,:)
        V10 = infile->V10(0:ntime-1,:,:)
        var = sqrt(U10^2+V10^2)
        delete(U10)
        delete(V10)
      end if
      if (ivar.eq.6) then
        RAINC = infile->RAINC
        RAINNC = infile->RAINNC
        RAINSH = infile->RAINSH
        var = RAINC(0:ntime-1,:,:)
        do i=1,ntime-1
          var(i,:,:)=RAINC(i,:,:)-RAINC(i-1,:,:)+RAINNC(i,:,:)-RAINNC(i-1,:,:)+RAINSH(i,:,:)-RAINSH(i-1,:,:)
        end do
        if (ifile .eq. 0) then
          var(0,:,:) = var(1,:,:)
        else
          var(0,:,:)=RAINC(0,:,:)+RAINNC(0,:,:)+RAINSH(0,:,:)-var3 
        end if
        var3 = RAINC(ntime-1,:,:)+RAINNC(ntime-1,:,:)+RAINSH(ntime-1,:,:) 
        var = var/3600
        delete(RAINC)
        delete(RAINNC)
        delete(RAINSH)
      end if

      print("Start interpolating...")
      var2 = rcm2rgrid(lat2d, lon2d, var, lat_out, lon_out, 0) ; Convert the coordinate system of WRF historical forcing to the NLDAS system
      print(min(var2))
      do itime=0,ntime-1
        var2(itime,:,:) = where(maskout.eq.0, var2@_FillValue, var2(itime,:,:))
      end do
      var2 = where(var2.lt.0, 0, var2) 
      print(min(var2))

      outfile->$varname2$(0:ntime-1,:,:) = (/ var2 /) ; Replace the NLDAS2 forcing with the WRF data

      delete(var)
      delete(var2)
    end do  ; var loop

    delete(time)
    print("")
  end do  ; infile loop
  print("Done!")

end
