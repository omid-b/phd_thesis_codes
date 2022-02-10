!modified from wnd.f and takes phase velocity at shortest and longest periods from the stinput
! determine the right window of the surface wave train at different 
! frequency
! based on the envelope of the filted seismogram

! Modified by omid.bagherpur@gmail.com
! to compile $> gfortran -o wnd wnd.f $SACHOME/lib/libsacio.a

	parameter (maxf=20, maxst=120, maxpts=8000)
	real tdata(maxpts), pamp(200), tmax(maxst), dseis(maxpts)
	real ssg(maxpts), amp(maxpts), time(maxpts), wnd(maxpts) 
	character*80 fn(maxst),ffltn(maxst),fevlp(maxst),
     &  	fbp(maxf,maxst), dfile, elpfile, stname 
	character*4 fqname(maxf)
	integer blank, nlt
	
	pi=4*atan(1.)
	open (1, file="file.in")
	read (1,*) ns
	do i=1, ns
	 read (1,'(a)') fn(i)
!	 write(*,'(a)') fn(i)
	enddo		 
	open(2, file="freq.in")
	read(2, *) nf
	do i=1, nf
	 read(2,'(a)') fqname(i)
!	 write(*,'(a)') fqname(i)
	enddo

!  use the shortest and longest distances to determine a general window 
!  for this event 	 
!  Give the phase velocity at the shortest and longest periods based on 
!  a global model 
	read(*,*) phv1 !phase velocity at the shortest period passband
	read(*,*) phv2 !phase velocity at the longest period passband
	call rsac1(fn(1), tdata, npt, beg, delt, maxpts, nerr)
	call getfhv('DIST',disn,nerr)
	cutw1=disn/phv2-200.	
	call rsac1(fn(ns), tdata, npt, beg, delt, maxpts, nerr)
	call getfhv('DIST',disf,nerr)
	cutw2=disf/phv1+500.

! loop over frequency and stations	
	do ifq=1, nf
	 ntmx=0
	 do i=1, ns
	  tmax(i)=0.
	 enddo
	 do js=1, ns
	  nlt=blank(fn(js)) 
	  dfile = fn(js)(1:nlt)//'.'//fqname(ifq)//'.p'
	  elpfile = fn(js)(1:nlt)//'.'//fqname(ifq)//'.evlp' 
	  fbp(ifq,js)= fn(js)(1:nlt)//'.'//fqname(ifq)
!	  write(*,*) fbp(ifq, js)
	call rsac1(dfile,tdata,nst,beg, delt,maxpts,nerr)
! make a small data array contain only the windowed part
        nwnd1=1+int((cutw1-beg)/delt)        
        ndt=1+int((cutw2-cutw1)/delt)
        do i=1, ndt
         ssg(i)=0.
        enddo
        do i=1, ndt
         j=nwnd1+i
         ssg(i)=tdata(j)
        enddo                  
        call rsac1 (elpfile, tdata, nst, beg, delt, maxpts, nerr) 
        do i=1, ndt
         amp(i)=0.
        enddo
        do i=1, ndt
         j=nwnd1+i
         amp(i)=tdata(j)
        enddo
                    
   	do i=1, ndt
         time(i)=cutw1+(i-1)*delt
        enddo       
! check the peaks of amp in the window to form a array with peak values
	 do i=1, 200
	  pamp(i)=0.
	 enddo 
	 np=0
	 do i=2, ndt-1
	  if ((amp(i).ge.amp(i-1)).and.(amp(i).gt.amp(i+1))) then
	   np=1+np
	   pamp(np)=amp(i)
!	   write(*,*) np, pamp(np)
	  endif
	 enddo 
	 call piksrt(np, pamp)	 
!	 write(*,*) pamp(np), pamp(np-1)
         if ((ifq.le.6).and.((pamp(np-1)/pamp(np)).gt.0.7)) then
          goto 800
         elseif (((ifq.gt.6).and.(ifq.le.12)).and. 
     &    ((pamp(np-1)/pamp(np)).gt.0.6)) then
	   goto 800
	 elseif  ((ifq.gt.12).and. 
     &    ((pamp(np-1)/pamp(np)).gt.0.5)) then
          goto 800
	 else
!	 write(*,*) ifq, fbp(ifq,js)
	 
! compare the time of the largest amplitude with previous ones
! compare the ratio of the largest and the second largest amp	 	 
       
          call max(amp, ndt, ampmx, iapmx)
!          write(*,*) ampmx, iapmx, time(iapmx), ntmx  	          
!	  t1=0
!	  t2=0
!         if (ntmx.ge.2) then
!          t1=abs(time(iapmx)-tmax(ntmx))
!          t2=abs(time(iapmx)-tmax(ntmx-1))
!  	 write (*,*) time(iapmx), ntmx, tmax(ntmx), tmax(ntmx-1)  
!  	 write (*,*) ifq, t1, t2
!         endif 
!	 if ((t1.gt.200).and.(t2.gt.200)) then
!          goto  900
!         else                 
!          ntmx=ntmx+1
!          tmax(ntmx)=time(iapmx)
!          write(*,*) ifq, ntmx, t1, t2 
                      
!  check the window tmx-250 to tmx and tmx to tmx+250 for the first turning 
!  point.         
        tmx=time(iapmx)
        npw=int(250/delt)
	aturn1=ampmx
	aturn2=ampmx
	iturn1=0
	iturn2=0
	amin1=ampmx
        amin2=ampmx        
	do i=1, npw
	i1=iapmx-i
	i2=iapmx+i
        if (amp(i1).lt.amin1) then
         amin1=amp(i1)
         imin1=i1
        endif	
	if (iturn1.eq.0) then
	 if ((amp(i1).le.amp(i1+1)).and.(amp(i1).lt.amp(i1-1))) then
	  aturn1=amp(i1)
	  iturn1=i1	 	
	 endif
	endif
	if (amp(i2).lt.amin2) then
         amin2=amp(i2)
         imin2=i2
        endif 
	if (iturn2.eq.0) then
	 if ((amp(i2).le.amp(i2-1)).and.(amp(i2).lt.amp(i2+1))) then
	  aturn2=amp(i2)
	  iturn2=i2
	 endif 
	endif
	enddo	
!	write(*,*)amin1, time(imin1), aturn1, time(iturn1) 
!	write(*,*)amin2, time(imin2), aturn2, time(iturn2)
! determine the approriate window based on the minimum and the turning 
! points		
! generate the approriate window based from tw1 to tw2
! add cosin taper with 40 s, equivalent to period of 80 s 
	if ((iturn1.ne.0).and.(time(iturn1).gt.time(imin1))) then
	 tw1=time(iturn1)
	 itw1=iturn1
	else
	 tw1=time(imin1)
	 itw1=imin1
	endif
	if ((iturn2.ne.0).and.(time(iturn2).lt.time(imin2))) then 
	 tw2=time(iturn2)
	 itw2=iturn2
	else 
	 tw2=time(imin2)
	 itw2=imin2
	endif 
!	write(*,*) tw1, tw2, itw1, itw2
! form a window array 
	icutw1=int((cutw1-beg)/delt)+1
	icutw2=int((cutw2-beg)/delt)+1
 	ngwl=icutw2-icutw1
 	do i=1, ndt
 	 dseis(i)=0.
 	enddo 
	do i=1, ndt
	 wnd(i)=0.
	enddo
	itb=itw1-int(40/delt)
	do i=itb, itw1-1
	 ttemp=cutw1+(i-1)*delt
	 wnd(i)=cos((ttemp-tw1)*pi/80.)
!	 write(*,*) (ttemp-tw1), wnd(i)
	enddo
	 do i= itw1, itw2
	  wnd(i)=1.
	 enddo
	 ite=itw2+int(40/delt)
	 do i=itw2+1, ite
	  ttemp=cutw1+(i-1)*delt
	  wnd(i)=cos((ttemp-tw2)*pi/80.)
	 enddo		
!	call wsac1("window",wnd, ndt, cutw1, delt, nerr)	
	 do i=1, ndt 
	  dseis(i)=ssg(i)*wnd(i)
	 enddo
         call setnhv('NPTS', ndt, nerr)
	 call setfhv('B', cutw1, nerr)
         call wsac0(fbp(ifq,js), dummy, dseis, nerr)	 
! 900     endif	 
 800	 endif
 	enddo
        enddo
        
        stop
        end
        
        
        subroutine max(a, n, amx, imx)
        real a(n)
        integer n, imx
         amx=0.
         do i=1, n
          if (a(i).gt.amx) then
          amx=a(i)
          imx=i
          endif
         enddo
         return
         end
         
      integer function blank(file)
      character file*80
      do 50 i=1,80
      if(file(i:i).ne.' ') goto 50
      blank=i-1
      return
50     continue
      write(1,100) file
100   format(' no blanks found in ',a80)
      blank = 0
      return
      end
      
      SUBROUTINE piksrt(n,arr)
      INTEGER n
      REAL arr(n)
      INTEGER i,j
      REAL a
      do 12 j=2,n
        a=arr(j)
        do 11 i=j-1,1,-1
          if(arr(i).le.a)goto 10
          arr(i+1)=arr(i)
11      continue
        i=0
10      arr(i+1)=a
12    continue
      return
      END

      
