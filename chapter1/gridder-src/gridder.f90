!  This version is modified by Omid.B (Jan 2019), works for any xyz format scattered data
!  original code file name: gridgen2.f    modified from gridgen.f By DWF		

      parameter (maxx = 7000,maxy = 7000, maxnodes = 15000)
      real*4 nodelat(maxnodes),nodelon(maxnodes), nodevel(maxnodes)
      real*4 nodecos2(maxnodes), nodesin2(maxnodes)
      real*4 applat,applon
      real*4 xgrid(maxx,maxy),ygrid(maxx,maxy)
      real*4 gridlat(maxx,maxy),gridlon(maxx,maxy)
      real*4 xnode(maxnodes),ynode(maxnodes)
      real*4 latinc,loninc
      real*4 value(maxx,maxy),value2(maxx,maxy),value3(maxx,maxy)
      real*4 agevel(maxnodes),agecos2(maxnodes),agesin2(maxnodes)
      character*100  dummy,grdfile,infile,outfile
      integer nx, ny	


      write(*,*) "Input number of nodes?"
      read(*,*) nnodes
      write(*,*) "Enter the input xyz file name?"
      read(*,'(a)') infile
      write(*,*) "Enter the output gridded file name?"
      read(*,'(a)') outfile
      write(*,*) "Input latitude spacing (deg)?"
      read(*,*) latinc
      write(*,*) "Input longitude spacing (deg)?"
      read(*,*) loninc
      write(*,*) "Input the smoothing length (km)?"
      read(*,*) alphaFactor
      
      open(10, file = infile)
      open(11, file = outfile)

!  set scale for later plotting.  0.25/.0375 will produce 0.5 (2x.25) inch
!  symbol for approximately 2% (1% amp) peak2peak velocity variation   
      alpha = 1/(alphaFactor*alphaFactor)
!     alpha = 1/(120.*120.) 	

!  alpha is distance scale for interpolation designed to make unit box 100 km 
      pi = 3.1415928
      convdeg = 3.1415928/180.
      rad2deg = 1./convdeg
      circ = 6371.*3.1415928/180.
      twopi = 3.1415928*2.
     
      
      maxLat = -999
      maxLon = -999
      minLat = 999
      minLon = 999
       
      do i = 1, nnodes
        read(10,*)  nodelon(i),nodelat(i),nodevel(i)
        if (nodelon(i).gt.maxLon) then
          maxLon = nodelon(i)
        endif
        if (nodelat(i).gt.maxLat) then
          maxLat = nodelat(i)
        endif
        if (nodelon(i).lt.minLon) then
          minLon = nodelon(i)
        endif
        if (nodelat(i).lt.minLat) then
          minLat = nodelat(i)
        endif
      enddo
      
      minLat = minLat-1
      minLon = minLon-1
      maxLat = maxLat+1
      maxLon = maxLon+1
      
      
      write(*,*) 'Lon range: ',minLon, maxLon
      write(*,*) 'Lat range: ',minLat, maxLat
      
      reflat = (minLat+maxLat)/2
      reflon = (minLon+maxLon)/2
      
      applat = reflat-90
      if (applat.lt.-90) then
        applat = applat+180
      endif

      applon = reflat-90
      if (applon.lt.-90) then
        applon = applon+180
      endif

!  set up x,y scheme for interpolation based on pole about 90 deg
!  from study area, (reflat, reflon): center of the map area 
!  (applat, applon): 90 degree from the center 

      call disthead(applat,applon,reflat,reflon &
     &                                   ,deltaref,tazimref)
!  generate grid of points with ny values in latitude spaced latinc
!  apart, and nx in longitude spaced loninc apart, beginning at 
!  latitude startlat and longitude startlon


      startlat = minLat
      startlon = minLon
      nx = ((maxLon-minLon)/loninc)+1
      ny = ((maxLat-minLat)/latinc)+1

 

      do inode = 1, nnodes
        call disthead(applat,applon,nodelat(inode),nodelon(inode)&
     &                                       ,delta,tazim)
        deltadiff = delta - deltaref
        if (deltadiff.gt.180.) deltadiff = deltadiff -360.
        if (deltadiff.lt.-180.) deltadiff = deltadiff+360.
        xnode(inode) = circ*deltadiff
        tazdiff =tazimref-tazim
        if (tazdiff.gt.180.) tazdiff = tazdiff - 360.
        if (tazdiff.lt. -180.) tazdiff = tazdiff +360.
        ynode(inode) = circ*sin(delta*convdeg)*tazdiff

      enddo
      do i = 1, nx
        do j = 1, ny
          gridlon(i,j) = startlon + (i-1)*loninc
          gridlat(i,j) = startlat + (j-1)*latinc
          call disthead(applat,applon,gridlat(i,j),gridlon(i,j)&
     &                                       ,delta,tazim)
          deltadiff = delta - deltaref
          if (deltadiff.gt.180.) deltadiff = deltadiff -360.
          if (deltadiff.lt.-180.) deltadiff = deltadiff+360.
          xgrid(i,j) = circ*deltadiff
          tazdiff =tazimref-tazim
          if (tazdiff.gt.180.) tazdiff = tazdiff - 360.
          if (tazdiff.lt. -180.) tazdiff = tazdiff +360.
          ygrid(i,j) = circ*sin(delta*convdeg)*tazdiff

        enddo
      enddo
      do i = 1,nx
        do j=1,ny
          wgtsum = 0.0
          value(i,j) = 0.0
          value2(i,j) = 0.0
          value3(i,j) = 0.0
          do ii = 1, nnodes
            adistsq = alpha *((xgrid(i,j)-xnode(ii))**2 + &
     &           (ygrid(i,j)-ynode(ii))**2)
            if(adistsq.lt.50.) then
              wgttemp = exp(-adistsq)
              wgtsum = wgtsum + wgttemp
              value(i,j) = value(i,j) + wgttemp*nodevel(ii)
            endif
          enddo
!  normalize weights to total 1.0

          value(i,j) = value(i,j)/wgtsum

        enddo
      enddo


      do i = 1,nx
        do j = 1, ny
          write(11,*) gridlon(i,j), gridlat(i,j), value(i,j)
        enddo
      enddo


      close(unit = 10)

      STOP
      END
           
      subroutine disthead(slat,slon,flat,flon,delta,azim)
!  Calculates distance and azimuth on sphere from starting point s 
!  to finishing point f
      dtor= 3.1415928/180.
      slt = slat*dtor
      sln = slon*dtor
      flt = flat*dtor
      fln = flon*dtor
      delta = acos(sin(slt)*sin(flt)+cos(slt)*cos(flt)*cos(fln-sln))
      azim = atan2(sin(fln-sln)*cos(flt),&
     &  sin(flt)*cos(slt) - cos(fln-sln)*cos(flt)*sin(slt))
      delta = delta/dtor
      azim = azim/dtor
      return
      end
