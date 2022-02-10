!  Modified from 'gridgenvar2.f' by Omid.B (Jan 2019): I made it interactive!

!  program to generate regular-spaced points in lon-lat grid based on 
!  output from simannerr* - use same interpolation scheme as original
!  generated in simulnoread17 etc. 

!  This version also estimates variance of interpolated velocities using
!  complete covariance matrix of velocity parameters (nodes or ages)

!  cos and sin terms and their variance for anisotropy can be treated as 
!  isovelocity (ityp =1)
!  the amplitude and fast direction and their variance should be calculated
!  with ityp = 3

!  WARNING - right now works only for nodes and for velocities, not anisotropy
!		modified by A. Li    Feb., 1999

      parameter (maxx = 1000, maxy = 1000,maxages = 50, maxnodes = 10000)
      real*4 nodelat(maxnodes),nodelon(maxnodes), nodevel(maxnodes)
      real*4 nodecos2(maxnodes), nodesin2(maxnodes)
      real*4 boxlat(4), boxlon(4),applat,applon
      real*4 xgrid(maxx,maxy),ygrid(maxx,maxy)
      real*4 gridlat(maxx,maxy),gridlon(maxx,maxy)
      real*4 xnode(maxnodes),ynode(maxnodes)
      real*4 latinc,loninc
      real*4 value(maxx,maxy),value2(maxx,maxy),value3(maxx,maxy)
      real*4 agevel(maxnodes),agecos2(maxnodes),agesin2(maxnodes)
      real*4 covar(maxnodes,maxnodes), stddev(maxx,maxy)
      real*4 covarage(maxages,maxages)
      real*4 qvector(maxnodes)
      integer indexqv(maxnodes) 
      character*100  dummy,grdfile,infile,outfile
      integer ityp, nx, ny
      
      
     
!  ityp = 1 isovelocity data, ityp = 2 is iso and aniso, 3 is aniso only
!  option 2 doesn't work because currently assumes two different grids
!  for interpolation of vel and aniso
      ityp = 1

!  set scale for later plotting.  0.25/.0375 will produce 0.5 (2x.25) inch
!  symbol for approximately 2% (1% amp) peak2peak velocity variation
!      anscale = 0.125/.0375      
      alpha = 1./(80.*80.)
!      alpha = 1./(65.*65.)

!  alpha is distance scale for interpolation designed to make unit box 100 km 
!  calculate distance to each node from each gridpoint
      pi = 3.1415928
      narea=3
      convdeg = 3.1415928/180.
      rad2deg = 1./convdeg
      circ = 6371.*3.1415928/180.
      twopi = 3.1415928*2.
      
      write(*,*) "Input the grid file?"
      read(*,'(a)') grdfile
      open(15, file = grdfile)


      write(*,*) "Input the covar file?"
      read(*,'(a)') infile
      open(16, file = infile)
         
      write(*,*) "Input the output file?"
      read(*,'(a)') outfile
      open(17, file = outfile)

      write(*,*) "Input latitude spacing (deg)?"
      read(*,*) latinc
      write(*,*) "Input longitude spacing (deg)?"
      read(*,*) loninc
      write(*,*) "Input the smoothing length (km)?"
      read(*,*) alphaFactor


      alpha = 1/(alphaFactor*alphaFactor)

      read(15,'(a)') dummy
      read(15,*) nnodes
      
      maxLat = -999
      maxLon = -999
      minLat = 999
      minLon = 999
       
      do i = 1, nnodes
        read(15,*)  nodelat(i),nodelon(i)
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
      
      read(15, *) (boxlat(i), boxlon(i), i= 1,4)
      

      read(16,*) nnodes
      do ii = 1, nnodes
        do jj= 1, nnodes
          read(16,*) covar(ii,jj)
        enddo
      enddo

!  set up x,y scheme for interpolation based on pole about 90 deg
!  from study area  
      
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
        call disthead(applat,applon,nodelat(inode),nodelon(inode) &
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
      write(*,*) "start to make new grid"
      do i = 1,nx
        do j=1,ny
          wgtsum = 0.0
          value(i,j) = 0.0
          value2(i,j) = 0.0
          value3(i,j) = 0.0
          nqvector = 0
          do ii = 1, nnodes
            qvector(ii) = 0.0
            adistsq = alpha *((xgrid(i,j)-xnode(ii))**2 + &
     &           (ygrid(i,j)-ynode(ii))**2)
            if(adistsq.lt.50.) then
              wgttemp = exp(-adistsq)
              wgtsum = wgtsum + wgttemp
!  ***********************************************
!  change following statement to interpolate cosine or sine terms
!  ***********************************************
              if ((ityp.eq.1).or.(ityp.eq.2)) then
                value(i,j) = value(i,j) + wgttemp*nodevel(ii)
                qvector(ii) = wgttemp
		if (qvector(ii).gt.0.0) then
		 nqvector = nqvector + 1
		 indexqv(nqvector) = ii
	        endif
              endif
              if ((ityp.eq.2).or.(ityp.eq.3)) then
                value2(i,j) = value2(i,j) +wgttemp*nodecos2(ii)
                value3(i,j) = value3(i,j) +wgttemp*nodesin2(ii)
              endif
            endif
          enddo		! ii
!  normalize weights to total 1.0
        if ((ityp.eq.1).or.(ityp.eq.2)) then
          value(i,j) = value(i,j)/wgtsum
          stddev(i,j) = 0.0
          do ii = 1, nqvector
            iii = indexqv(ii)
            do jj = 1, nqvector
             jjj = indexqv(jj)  
              stddev(i,j) = stddev(i,j) + covar(iii,jjj)*qvector(iii) &
     &                                                *qvector(jjj)
            enddo
          enddo
	  if (stddev(i,j).lt.0.) then          
!	   write(*,*) gridlon(i,j), gridlat(i,j),stddev(i,j)
	   stddev(i,j) = 1.0D-6
	  endif
!  double to represent approx 95% limits
          stddev(i,j) = 2.*sqrt(stddev(i,j))/wgtsum
        endif
!         if ((ityp.eq.2).or.(ityp.eq.3)) then
	 if (ityp.eq.3) then
          value2(i,j) = value2(i,j)/wgtsum
          value3(i,j) = value3(i,j)/wgtsum
!  convert to amplitude and fast direction
          amp = sqrt (value2(i,j)**2+value3(i,j)**2)
          azi = 0.5*rad2deg*atan2(value3(i,j),value2(i,j))
          value2(i,j) = amp*anscale
          value3(i,j) = azi
! ?calaulate uncertainties for anisotropic terms ?
         endif
        enddo
      enddo
      write(*,*) "finishing"

        if ((ityp.eq.1).or.(ityp.eq.2)) then

         do i = 1,nx
           do j=1,ny
             write(17,*) gridlon(i,j), gridlat(i,j), stddev(i,j)
           enddo
         enddo
        endif
      close(unit = 10)
      close(unit=15)
      close(unit=16)
      close(unit=17)
      stop
      end
           
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
