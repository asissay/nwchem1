C
C     rt_tddft_input_field.F
C     
C     Parses input deck for rt-tddft field (excitation) parameters.
C     
C
      subroutine rt_tddft_input_field (rtdb, field_name, nfields)
      implicit none

#include "rt_tddft.fh"
#include "errquit.fh"
#include "inp.fh"
#include "rtdb.fh"
#include "mafdecls.fh"
#include "stdio.fh"

      
C     == Inputs ==
      integer, intent(in)      :: rtdb
      character*16, intent(in) :: field_name   !hardcoded to match geom name max size
      integer, intent(in)      :: nfields      !this is the number of the current field


C     == Parameters ==
      character(*), parameter :: pname = "rt_tddft_input_field: "


C     == Variables ==
      logical done
      character*255 test
      
      type (rt_field_t) prev_field, this_field
      integer i

      character*20 type
      character*20 spin
      character spin1
      double precision max
      double precision center
      double precision frequency
      double precision width
      double precision phase
C      double precision gap      ! For N2 DC-field calculations for tanh field (this one did not work)
      double precision tau      ! For N2 DC-field calculations for sin^2 field
      character*16 polarization  !x,y,z for dipole; xx,xy,xz,... for quad
      double precision theta    ! Azimuthal angle for the x-y plane (0 < theta < 2pi)
      double precision phi      ! Zenith angle for the z-direction (0 < phi < pi)

      logical lhave_center
      logical lhave_polarization
      logical lhave_width
      logical lhave_max
      logical lhave_type
      logical lhave_frequency
      logical lhave_spin
      logical lhave_phase
C      logical lhave_gap
      logical lhave_tau
      
C      logical lhave_phi
C      logical lhave_theta
      
      if (nfields .gt. rt_max_fields)
     $     call errquit (pname//"cannot exceed max num fields", 0, 0)
      

      lhave_center = .false.
      lhave_polarization = .false.
      lhave_width = .false.
      lhave_type = .false.
      lhave_frequency = .false.
      lhave_spin = .false.
      lhave_phase = .false.
C     lhave_gap = .false.
      lhave_tau = .false.
C      lhave_theta = .false.
C      lhave_phi = .false.
      
C     
C     Parse the input; we will put in rtdb later after checking.
C     
      done = .false.
      do while (.not. done)
         
         if (.not. inp_read()) 
     $        call errquit(pname//'Read failed input',0, INPUT_ERR)
         if (.not. inp_a(test)) 
     $        call errquit(pname//'Read failed keyword',0, INPUT_ERR)
         
         
         
C     
C     type (delta, cw, gaussian)
C     
         if (inp_compare(.false.,test,'type')) then
            if (.not. inp_a (type))
     $           call errquit (pname//"failed to read field type",0,0)
            
            if ( (type.ne."cw").and.
     $           (type.ne."delta").and.
     $           (type.ne."hann").and.
     $           (type.ne."linramp").and.
     $           (type.ne."static").and.
     $           (type.ne."pwave").and.
     $           (type.ne."gaussian") )
     $           call errquit (pname//"invalid field type: "//type,0,0)
            
            lhave_type = .true.
            
            
C     
C     spin which the field acts on
C     
         elseif (inp_compare(.false.,test,'spin')) then
            if (.not. inp_a (spin))
     $           call errquit (pname//
     $           "failed to read field target spin",0,0)

            lhave_spin = .true.



C
C     max value of the field
C
         elseif (inp_compare(.false.,test,'max')) then
            if (.not.inp_f(max)) call errquit (pname//
     $           "max takes a float", 0, 0)
            lhave_max = .true.

C
C     center the field (only for gaussian and Hann)
C
         elseif (inp_compare(.false.,test,'center')) then
            if (.not.inp_f(center)) call errquit (pname//
     $           "center takes a float >= 0", 0, 0)
            lhave_center = .true.


C
C     width the field (only for gaussian and Hann)
C
         elseif (inp_compare(.false.,test,'width')) then
            if (.not.inp_f(width)) call errquit (pname//
     $           "width takes a float >= 0", 0, 0)
            lhave_width = .true.


C
C     frequency the field (only for gaussian and cw)
C
         elseif (inp_compare(.false.,test,'frequency')) then
            if (.not.inp_f(frequency)) call errquit (pname//
     $           "frequency takes a float >= 0", 0, 0)
            lhave_frequency = .true.


C
C     field polarization
C
         elseif (inp_compare(.false.,test,'polarization')) then
            if (.not.inp_a(polarization)) call errquit (pname//
     $           "polarization can be: x,y,z, angle")
            lhave_polarization = .true.



C
C     phase (only for gaussian and cw)
C     
         elseif (inp_compare(.false.,test,'phase')) then
            if (.not.inp_f(phase)) call errquit (pname//
     $           "phase takes a float >= 0", 0, 0)
            lhave_phase = .true.


C
C     Gap (only for ramp field)
C     
c$$$         elseif (inp_compare(.false.,test,'gap')) then
c$$$            if (.not.inp_f(gap)) call errquit (pname//
c$$$     $           "gap takes a float >= 0", 0, 0)
c$$$            lhave_gap = .true.


         elseif (inp_compare(.false.,test,'tau')) then
            if (.not.inp_f(tau)) call errquit (pname//
     $           "tau takes a float >= 0", 0, 0)
            lhave_tau = .true.



C
C    Angle of the applied field (only for Hann)
C
c$$$         elseif (inp_compare(.false.,test,'theta')) then
c$$$            if (.not.inp_f(theta)) call errquit (pname//
c$$$     $           "theta takes a float >= 0 and <= 360", 0, 0)
c$$$            lhave_theta = .true.
c$$$  
c$$$
c$$$
c$$$         elseif (inp_compare(.false.,test,'phi')) then
c$$$            if (.not.inp_f(phi)) call errquit (pname//
c$$$     $           "phi takes a float >= 0 and <= 180", 0, 0)
c$$$            lhave_phi = .true.
  
            

C     
C     end of parse
C     
         else if (inp_compare(.false.,test,'end')) then
            done = .true.
         else
            call errquit(pname//'Unknown directive: '//trim(test),
     $           0, INPUT_ERR)
         endif


CXXX  [KAL]: CHIRP

      enddo

      
C
C     Now check that we have all required parameters, no superfluous
C     ones, no name clashes with other fields, and that params are
C     reasonable (e.g., no negative times, etc).
C

      if (nfields .gt. 1) then
         do i = 1, nfields - 1
            call rt_tddft_field_rtdb_get (rtdb, i, prev_field)
            if (prev_field%name .eq. field_name)
     $           call errquit (pname//"cannot have multiple fields"//
     $           " with the same name: "//trim(field_name), 0, 0)
         enddo
      endif
      

      if (.not. lhave_type)
     $     call errquit (pname//trim(field_name)//
     $     ": must supply a field type", 0, 0)

      if (lhave_spin) then
         if (spin.eq."alpha") then 
            spin1 = "a"
         elseif (spin.eq."beta") then 
            spin1 = "b"
         elseif (spin.eq."total") then 
            spin1 = "t"
         else
            spin1 = "X"
            call errquit (pname//"invalid field spin: "//spin,0,0)
         endif
      else
         spin1 = "t"            !default to acting on all spins
      endif

      if (.not. lhave_spin) spin = "total" !default to acting on both spins


      if (.not. lhave_max)
     $     call errquit (pname//trim(field_name)//
     $     ": must supply a field max", 0, 0)

      if (.not. lhave_polarization)
     $     call errquit (pname//trim(field_name)//
     $     ": must supply a field polarization", 0,0)

      if (type .eq. "cw") then
         if (.not. lhave_frequency)
     $        call errquit (pname//trim(field_name)//
     $        ": must supply a frequency if doing cw", 0,0)
         
         if (lhave_center) call errquit (pname//trim(field_name)//
     $     ": cannot specify center if cw", 0,0)

         if (lhave_width) call errquit (pname//trim(field_name)//
     $     ": cannot specify width if cw", 0,0)
      endif

      if (type .eq. "gaussian") then
         if (.not. lhave_frequency)
     $        call errquit (pname//trim(field_name)//
     $        ": must supply a frequency if doing gaussian", 0,0)

         if (.not. lhave_center) call errquit (pname//trim(field_name)//
     $     ": must specify center if gaussian", 0,0)

         if (.not. lhave_width) call errquit (pname//trim(field_name)//
     $     ": must specify width if gaussian", 0,0)
      endif

      if (type .eq. "hann") then
         if (.not. lhave_frequency)
     $        call errquit (pname//trim(field_name)//
     $        ": must supply a frequency if doing Hann", 0,0)
         
         if (.not. lhave_center) call errquit (pname//trim(field_name)//
     $        ": must specify center if Hann", 0,0)
         
         if (.not. lhave_width) call errquit (pname//trim(field_name)//
     $        ": must specify width if Hann", 0,0)
         
c$$$  if (.not. lhave_theta) call errquit (pname//trim(field_name)//
c$$$  $     ": must specify theta if Hann", 0,0)
c$$$  if (.not. lhave_phi) call errquit (pname//trim(field_name)//
c$$$  $     ": must specify phi if Hann", 0,0)
         
      endif
 

      if (type .eq. "pwave") then
         if (.not. lhave_frequency)
     $        call errquit (pname//trim(field_name)//
     $        ": must supply a frequency if doing pwave", 0,0)
         
c$$$         if (.not. lhave_center) call errquit (pname//trim(field_name)//
c$$$     $        ": must specify center if pwave", 0,0)
c$$$         
c$$$         if (.not. lhave_width) call errquit (pname//trim(field_name)//
c$$$     $        ": must specify width if pwave", 0,0)
      endif
      
      
      if ( (type .eq. "delta").or.(type .eq. "static") ) then
         if (lhave_frequency) call errquit (pname//trim(field_name)//
     $        ": cannot supply a frequency if doing delta or static"
     $        , 0,0)
         
         if (.not. lhave_center) then
            center = 0d0        !default delta kick to t=0
            lhave_center = .true.
         endif
         
         
c$$$         if (lhave_center) call errquit (pname//trim(field_name)//
c$$$     $     ": cannot specify center if delta", 0,0)

         if (lhave_width) call errquit (pname//trim(field_name)//
     $     ": cannot specify width if delta", 0,0)
      endif

      if (type .eq. "pwave") then
         if (.not. lhave_frequency)
     $        call errquit (pname//trim(field_name)//
     $        ": must supply a frequency if doing pwave", 0,0)
c$$$         
c$$$         if (.not. lhave_center) call errquit (pname//trim(field_name)//
c$$$     $        ": must specify center if pwave", 0,0)
c$$$         
c$$$         if (.not. lhave_width) call errquit (pname//trim(field_name)//
c$$$     $        ": must specify width if pwave", 0,0)
      endif
      
      
      if ( (polarization.ne."x").and.
     $     (polarization.ne."y").and.
     $     (polarization.ne."z").and.
     $     (polarization.ne."angle"))
     $     call errquit (pname//trim(field_name)//
     $     ": polarization must be x, y, z, or angle",
     $     0,0)

C      if ( (lhave_frequency).and.(frequency.lt.0d0) )
C     $     call errquit (pname//trim(field_name)//
C     $     ": frequency must be positive", 0, 0)

      if ( (lhave_center).and.(center.lt.0d0) )
     $     call errquit (pname//trim(field_name)//
     $     ": center must be positive", 0, 0)

      if ( (lhave_width).and.(width.lt.0d0) )
     $     call errquit (pname//trim(field_name)//
     $     ": width must be positive", 0, 0)

c$$$      if ( (lhave_gap).and.(gap.lt.0d0) )
c$$$     $     call errquit (pname//trim(field_name)//
c$$$     $     ": gap must be positive", 0, 0)


      if ( (lhave_tau).and.(tau.lt.0d0) )
     $     call errquit (pname//trim(field_name)//
     $     ": tau must be positive", 0, 0)



C     (no, its OK to have a negative "max")
C      if ( (lhave_max).and.(max.lt.0d0) )
C     $     call errquit (pname//trim(field_name)//
C     $     ": max must be positive", 0, 0)


C
C     Frequency-related stuff only valid for CW and pulses (gaussian, hann)
C
      if (lhave_phase .or. lhave_frequency) then
         if ((type .ne. "cw").and.(type .ne. "gaussian")
     $        .and. (type .ne. "hann") .and. (type .ne. "linramp")
     $        .and. (type .ne. "pwave"))
     $        call errquit (pname//
     $        "phase and frequency only valid for "//
     $        "CW, gaussian, linramp, and hann",0,0)
      endif

C
C     Angle
C
c$$$
c$$$      if (lhave_phi .or. lhave_theta) then
c$$$         if (type .ne. "Hann") 
c$$$     $    call errquit (pname//
c$$$     $    "phi and theta only valid for "//"hann",0,0)
c$$$      endif



C
C     Load into rtdb
C
      this_field%name = field_name
      this_field%type = type
      this_field%polarization = polarization
      this_field%max = max
      this_field%spin = spin1
C      this_filed%theta = theta
C      this_field%phi = phi
      
      if (type.eq."cw") then
         this_field%frequency = frequency
         this_field%phase = phase
         this_field%width = -99d0
         this_field%center = -99d0
      endif

      if (type.eq."linramp") then
         this_field%frequency = frequency
         this_field%phase = phase
         this_field%width = -99d0
         this_field%center = -99d0
      endif

      if (type.eq."gaussian") then
         this_field%frequency = frequency
         this_field%phase = phase
         this_field%width = width
         this_field%center = center
      endif

      if (type.eq."hann") then
         this_field%frequency = frequency
         this_field%phase = phase
         this_field%width = width
         this_field%center = center
C         this_field%theta = theta
C         this_field%phi = phi
      endif

      if ((type.eq."delta").or.(type.eq."static")) then
         this_field%frequency = -99d0
         this_field%width = -99d0
         this_field%center = center
C         this_field%gap = gap
         this_field%tau = tau
      endif

      if (type.eq."pwave") then
         this_field%frequency = frequency
         this_field%phase = phase
c$$$         this_field%width = -99d0
c$$$         this_field%center = center
      endif
        
      call rt_tddft_field_rtdb_put (rtdb, nfields, this_field)

      end subroutine 


C====================================================================
C
C     Generate entry name for field rtdb stuff (hack)
C
      subroutine rt_tddft_field_rtdb_entry_name (i, name)
      implicit none

#include "errquit.fh"
#include "rtdb.fh"
#include "mafdecls.fh"
#include "stdio.fh"
#include "rt_tddft.fh"

      
C     == Inputs ==
      integer, intent(in) :: i

      
C     == Outputs ==
      character(len=*), intent(out) :: name   !was 17

      
C     == Parameters ==
      character(len=*), parameter :: pname =
     $     "rt_tddft_field_rtdb_entry_name"

      
C     == Variables ==
      character*5 istring       !note length 5 limit size of int

      
      if ( (i .gt. rt_max_fields).or.(i .lt. 1) )
     $     call errquit(pname//"i must be between 1, rt_max_fields",0,0)

      if (rt_max_fields .gt. 999) call errquit(pname//
     $     "rt_max_fields too large; fix formatting", 0, 0)

      write (istring, "(i0.5)") i
      
      name = "rt_tddft:field_"//trim(istring)//"_"

      end subroutine


C====================================================================      
C
C     Load field into rtbd.  This is an ugly hack, but it's easier than
C     adding a custom struct to the rtdb routines.
C     
      subroutine rt_tddft_field_rtdb_put (rtdb, i, field)
      implicit none

#include "rt_tddft.fh"
#include "errquit.fh"
#include "rtdb.fh"
#include "mafdecls.fh"
#include "stdio.fh"

      
C     == Inputs ==
      integer, intent(in)          :: rtdb
      integer, intent(in)          :: i           !index for the field
      type(rt_field_t), intent(in) :: field


C     == Parameters ==
      character(len=*), parameter :: pname = "rt_tddft_field_rtdb_put: "


C     == Variables ==
      character*32 basename
      character*32 entry_name

      if ( (i .gt. rt_max_fields).or.(i .lt. 1) )
     $     call errquit(pname//"i must be between 1, rt_max_fields",0,0)

      call rt_tddft_field_rtdb_entry_name (i, basename)

      entry_name = trim(basename) // "name"
      if (.not.rtdb_cput(rtdb,entry_name,1,field%name))
     $     call errquit(pname//'Write failed to name rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "type"
      if (.not.rtdb_cput(rtdb,entry_name,1,field%type))
     $     call errquit(pname//'Write failed to type rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "polarization"
      if (.not.rtdb_cput(rtdb,entry_name,1,field%polarization))
     $     call errquit(pname//'Write failed to polarization rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "spin"
      if (.not.rtdb_cput(rtdb,entry_name,1,field%spin))
     $     call errquit(pname//'Write failed to spin rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "max"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%max))
     $     call errquit(pname//'Write failed to max rtdb',0,RTDB_ERR)

      entry_name = trim(basename) // "frequency"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%frequency))
     $     call errquit(pname//'Write failed to frequency rtdb',
     $     0,RTDB_ERR)
      
      entry_name = trim(basename) // "width"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%width))
     $     call errquit(pname//'Write failed to width rtdb',
     $     0,RTDB_ERR)
      
      entry_name = trim(basename) // "center"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%center))
     $        call errquit(pname//'Write failed to center rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "phase"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%phase))
     $        call errquit(pname//'Write failed to phase rtdb',
     $     0,RTDB_ERR)
      
c$$$      entry_name = trim(basename) // "gap"
c$$$      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%gap))
c$$$     $        call errquit(pname//'Write failed to gap rtdb',
c$$$     $     0,RTDB_ERR)
c$$$

      entry_name = trim(basename) // "tau"
      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%tau))
     $     call errquit(pname//'Write failed to tau rtdb',
     $     0,RTDB_ERR)



c$$$      entry_name = trim(basename) // "theta"
c$$$      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%theta))
c$$$     $        call errquit(pname//'Write failed to theta rtdb',
c$$$     $     0,RTDB_ERR)
c$$$
c$$$      entry_name = trim(basename) // "phi"
c$$$      if (.not.rtdb_put(rtdb,entry_name,mt_dbl,1,field%phi))
c$$$     $        call errquit(pname//'Write failed to phi rtdb',
c$$$     $     0,RTDB_ERR)


      end subroutine

      

C
C     Get field from rtdb and put into struct
C
      subroutine rt_tddft_field_rtdb_get (rtdb, i, field)
      implicit none

#include "rt_tddft.fh"
#include "errquit.fh"
#include "rtdb.fh"
#include "mafdecls.fh"
#include "stdio.fh"

      
C     == Inputs ==
      integer, intent(in) :: rtdb
      integer, intent(in) :: i                 !index for the field

      
C     == Outputs ==
      type(rt_field_t), intent(out) :: field



C     == Parameters ==
      character(len=*), parameter :: pname = "rt_tddft_field_rtdb_get: "


C     == Variables ==
      character*32 basename
      character*32 entry_name


      if ( (i .gt. rt_max_fields).or.(i .lt. 1) )
     $     call errquit(pname//"i must be between 1, rt_max_fields",0,0)

      call rt_tddft_field_rtdb_entry_name (i, basename)

      
      entry_name = trim(basename) // "name"
      if (.not.rtdb_cget(rtdb,entry_name,1,field%name))
     $     call errquit(pname//'Read failed for name rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "type"
      if (.not.rtdb_cget(rtdb,entry_name,1,field%type))
     $     call errquit(pname//'Read failed for type rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "polarization"
      if (.not.rtdb_cget(rtdb,entry_name,1,field%polarization))
     $     call errquit(pname//'Read failed for polarization rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "spin"
      if (.not.rtdb_cget(rtdb,entry_name,1,field%spin))
     $     call errquit(pname//'Read failed for spin rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "max"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%max))
     $     call errquit(pname//'Read failed for max rtdb',0,RTDB_ERR)

      entry_name = trim(basename) // "frequency"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%frequency))
     $     call errquit(pname//'Read failed for frequency rtdb',
     $     0,RTDB_ERR)
      
      entry_name = trim(basename) // "width"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%width))
     $     call errquit(pname//'Read failed for width rtdb',
     $     0,RTDB_ERR)
      
      entry_name = trim(basename) // "center"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%center))
     $        call errquit(pname//'Read failed for center rtdb',
     $     0,RTDB_ERR)

      entry_name = trim(basename) // "phase"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%phase))
     $        call errquit(pname//'Read failed for phase rtdb',
     $     0,RTDB_ERR)

c$$$      entry_name = trim(basename) // "gap"
c$$$      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%gap))
c$$$     $        call errquit(pname//'Read failed for gap rtdb',
c$$$     $     0,RTDB_ERR)

      entry_name = trim(basename) // "tau"
      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,field%tau))
     $        call errquit(pname//'Read failed for tau rtdb',
     $     0,RTDB_ERR)



c$$$      entry_name = trim(basename) // "theta"
c$$$      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,theta))
c$$$     $        call errquit(pname//'Read failed for theta rtdb',
c$$$     $     0,RTDB_ERR)
c$$$
c$$$      entry_name = trim(basename) // "phi"
c$$$      if (.not.rtdb_get(rtdb,entry_name,mt_dbl,1,phi))
c$$$     $        call errquit(pname//'Read failed for phi rtdb',
c$$$     $     0,RTDB_ERR)
c$$$
      
      end subroutine
