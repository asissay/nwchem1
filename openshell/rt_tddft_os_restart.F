C
C     rt_tddft_os_restart.F
C
C     Routines for dumping and reading in restart point info.
C
C     Open shell version.
C
      subroutine rt_tddft_os_restart_save (params, it, tt, g_zdens_ao)
      implicit none

#include "errquit.fh"
#include "mafdecls.fh"
#include "stdio.fh"
#include "global.fh"
#include "rtdb.fh"
#include "util.fh"
#include "cdft.fh"
#include "matutils.fh"
#include "rt_tddft.fh"

C     == Inputs ==
      type(rt_params_t), intent(in)     :: params
      integer, intent(in)               :: it
      double precision, intent(in)      :: tt
      integer, intent(in)               :: g_zdens_ao(2)

      
C     == Parameters ==
      character(*), parameter :: pname = "rt_tddft_os_restart_save: "


C     == Variables ==
      integer n
      integer g_densre_ao(2), g_densim_ao(2)
      character(255) fname_re_alpha, fname_re_beta
      character(255) fname_im_alpha, fname_im_beta
      character(255) fname_restart
      integer, parameter      :: unitno = 6457251    !XXX TERRIBLE: HARDCODED UNIT #
      integer ios, me, lmat, kmat
      logical ok

      integer i, j
      double complex zval
      double precision checksum
      double precision elapsed

      me = ga_nodeid()
      

      if (params%prof) call prof_start (elapsed)

      if (params%ipol .ne. 2)
     $     call errquit (pname//"only valid for ipol = 2",0,0)

C
C     First, store current time in rtdb.  Note we put both it and tt
C     which is redundant, but we check that tt = tmin + (it-1)*dt when
C     we restart.
C
      if (.not.rtdb_put(params%rtdb,'rt_tddft:rest_it', mt_int, 1, it))
     $     call errquit(pname//'Write failed rest_it to rtdb',
     $     0,RTDB_ERR)

      if (.not.rtdb_put(params%rtdb,'rt_tddft:rest_tt', mt_dbl, 1, tt))
     $     call errquit(pname//'Write failed rest_tt to rtdb',
     $     0,RTDB_ERR)


C
C     Also store some other params (so we can check when we restart).
C
CXXX  [KAL]: ns_ao, ns_mo
      

C     
C     Compute and store checksum for complex dens mat.  Note checksum is
C     calculated using the alpha complex AO dens mat (beta part not
C     used for checksum).
C
      checksum = zmat_checksum (g_zdens_ao(1))

      if (.not.rtdb_put(params%rtdb,'rt_tddft:rest_checksum',
     $     mt_dbl, 1, checksum))
     $     call errquit(pname//'Write failed rest_checksum to rtdb',
     $     0,RTDB_ERR)


C
C     Dump dens mat in AO basis to file.  Note we do real and imag parts
C     separately.
C
      n = params%ns_ao   !alias for clarity

      ok = .true.
      ok = ok.and.ga_create(mt_dbl, n,n, "Re[Pa]", 0, 0, g_densre_ao(1))
      ok = ok.and.ga_create(mt_dbl, n,n, "Re[Pb]", 0, 0, g_densre_ao(2))

      ok = ok.and.ga_create(mt_dbl, n,n, "Im[Pa]", 0, 0, g_densim_ao(1))
      ok = ok.and.ga_create(mt_dbl, n,n, "Im[Pb]", 0, 0, g_densim_ao(2))

      if (.not.ok) call errquit(pname//"GA allocation failed", 0,GA_ERR)

      call convert_z2d (g_zdens_ao(1), g_densre_ao(1), g_densim_ao(1))
      call convert_z2d (g_zdens_ao(2), g_densre_ao(2), g_densim_ao(2))

      call util_file_name ("densmat_ao_alpha_re",
     $     .false., .false., fname_re_alpha)
      call util_file_name ("densmat_ao_beta_re",
     $     .false., .false., fname_re_beta)

      call util_file_name ("densmat_ao_alpha_im",
     $     .false., .false., fname_im_alpha)
      call util_file_name ("densmat_ao_beta_im",
     $     .false., .false., fname_im_beta)

      if (.not. dmat_io_dump (g_densre_ao(1), fname_re_alpha))
     $     call errquit (pname//"failed to dump densao_alpha_re",0,0)

      if (.not. dmat_io_dump (g_densre_ao(2), fname_re_beta))
     $     call errquit (pname//"failed to dump densao_beta_re",0,0)

      if (.not. dmat_io_dump (g_densim_ao(1), fname_im_alpha))
     $     call errquit (pname//"failed to dump densao_alpha_im",0,0)

      if (.not. dmat_io_dump (g_densim_ao(2), fname_im_beta))
     $     call errquit (pname//"failed to dump densao_beta_im",0,0)


C
C     Dump restart info to self-contained file (so we can use "start"
C     instead of "restart" to bypass bugginess with range-separated
C     functionals)
C
C     XXXTODO: ADD TO CLOSED SHELL CODE
C     
      if (me.eq.0) then
         
         call util_file_name ("rt_restart",
     $        .false., .false., fname_restart)
         
c$$$         if (.not. ma_push_get (mt_dcpl, n*n, "alpha AO density matrix",
c$$$     $        lmat, kmat))
c$$$     $        call errquit (pname//"failed to alloc alpha P", 0, 0)
c$$$         call ga_get (g_zdens_ao, 1, n, 1, n, dcpl_mb(kmat), 1)

c$$$         if (.not. ma_push_get (mt_dcpl, n*n, "alpha AO density matrix",
c$$$     $        lmat, kmat))

         open (unitno, status="replace", file=fname_restart, iostat=ios)
         if (ios .ne. 0) call errquit("failed to open/create: "
     $        //trim(fname_restart), 0, 0)
         
         write (unitno, "(a)") "RT-TDDFT restart file"
         write (unitno, "(a)") "unrestricted"
         write (unitno, "(a,x,i0)") "it", it
         write (unitno, "(a,x,e20.8)") "tt", tt
         write (unitno, "(a,x,e20.8)") "Nao", n
C         write (unitno, "(a,x,e20.8)")  "checksum", checksum
         
         do i = 1, n
            do j = 1, n
               call ga_get (g_zdens_ao, i, i, j, j, zval, 1)
               write (unitno, advance="no", fmt="(1e20.10, a, 1e20.10)")
     $              dble(zval), ",", aimag(zval)
            enddo
         enddo

c$$$         do i = 1, n1
c$$$            call ga_get (g_a, 1, n1, i, i, dbl_mb(k_matsl), 1)
c$$$            call swrite (unitno, dbl_mb(k_matsl), n1)
c$$$         enddo

         
C         write (unitno, *) dcpl_mb(kmat)
C         call swrite_dcpl(unitno, dcpl_mb(kmat), n*n)
        
         close (unitno)
         
         if (ios .ne. 0) call errquit("failed to close: "
     $        //trim(fname_restart), 0, 0)

         if (.not. ma_pop_stack (lmat))
     $        call errquit (pname//"failed to pop stack", 0, 0)

      endif
      call ga_sync()


      
C
C     Clean up.
C
      ok = .true.
      ok = ok .and. ga_destroy(g_densre_ao(1))
      ok = ok .and. ga_destroy(g_densre_ao(2))
      ok = ok .and. ga_destroy(g_densim_ao(1))
      ok = ok .and. ga_destroy(g_densim_ao(2))
      if (.not.ok) call errquit(pname//"failed to destroy GAs", 0,0)

      if (params%prof) call prof_end (elapsed, "Saving restart point")
      end subroutine


C====================================================================
C
C     Load info from previous restart point.
C
      subroutine rt_tddft_os_restart_load (params, it, tt, g_zdens_ao)
      implicit none

#include "errquit.fh"
#include "mafdecls.fh"
#include "stdio.fh"
#include "global.fh"
#include "rtdb.fh"
#include "util.fh"
#include "cdft.fh"
#include "matutils.fh"
#include "rt_tddft.fh"

      
C     == Inputs ==
      type(rt_params_t), intent(in) :: params

      
C     == Outputs ==
      integer, intent(in)           :: g_zdens_ao(2)

      
C     == Parameters ==
      character(*), parameter  :: pname = "rt_tddft_os_restart_load: "

      
C     == Outputs ==
      integer, intent(out)          :: it
      double precision, intent(out) :: tt

      
C     == Variables ==
      double precision checksum, rest_checksum
      integer n
      integer g_densre_ao(2), g_densim_ao(2)
      character(255) fname_re_alpha, fname_re_beta
      character(255) fname_im_alpha, fname_im_beta
      logical ok
      double precision elapsed

      
      call rt_tddft_os_confirm (params)

      if (params%prof) call prof_start (elapsed)

C
C     Read in previous time values.
C
      if (.not.rtdb_get (params%rtdb,"rt_tddft:rest_it",mt_int, 1, it))
     $     call errquit (pname//"failed to read rest_it from rtdb",0,0)

      if (.not.rtdb_get (params%rtdb,"rt_tddft:rest_tt",mt_dbl, 1, tt))
     $     call errquit (pname//"failed to read rest_tt from rtdb",0,0)

C Commented out by adonay
c$$$      if (tt .ne. (params%tmin + (it-1)*params%dt))
c$$$     $     call errquit (pname//"inconsistent rest_it, rest_tt",0,0)
C Commented ut by adonay 
      if (.not.rtdb_get (params%rtdb,"rt_tddft:rest_checksum",
     $     mt_dbl, 1, rest_checksum)) call errquit (pname//
     $     "failed to read rest_checksum from rtdb",0,0)

      
C
C     Read in complex dens mat in AO basis.
C
      call util_file_name ("densmat_ao_alpha_re",
     $     .false., .false., fname_re_alpha)
      
      call util_file_name ("densmat_ao_beta_re",
     $     .false., .false., fname_re_beta)

      call util_file_name ("densmat_ao_alpha_im",
     $     .false., .false., fname_im_alpha)

      call util_file_name ("densmat_ao_beta_im",
     $     .false., .false., fname_im_beta)

      n = params%ns_ao   !alias for clarity

      ok = .true.
      ok = ok.and.ga_create(mt_dbl, n, n, "Re[P]", 0, 0, g_densre_ao(1))
      ok = ok.and.ga_create(mt_dbl, n, n, "Re[P]", 0, 0, g_densre_ao(2))
      
      ok = ok.and.ga_create(mt_dbl, n, n, "Im[P]", 0, 0, g_densim_ao(1))
      ok = ok.and.ga_create(mt_dbl, n, n, "Im[P]", 0, 0, g_densim_ao(2))
      
      if (.not. dmat_io_read (g_densre_ao(1), fname_re_alpha))
     $     call errquit (pname//"failed to read densao_re_alpha",0,0)
      if (.not. dmat_io_read (g_densre_ao(2), fname_re_beta))
     $     call errquit (pname//"failed to read densao_re_beta",0,0)

      if (.not. dmat_io_read (g_densim_ao(1), fname_im_alpha))
     $     call errquit (pname//"failed to read densao_im_alpha",0,0)
      if (.not. dmat_io_read (g_densim_ao(2), fname_im_beta))
     $     call errquit (pname//"failed to read densao_im_beta",0,0)


C
C     Load real and im parts into complex GA and check that checksum is
C     consistent.
C
      call convert_d2z (1d0, g_densre_ao(1), 1d0, g_densim_ao(1),
     $     g_zdens_ao(1))
      call convert_d2z (1d0, g_densre_ao(2), 1d0, g_densim_ao(2),
     $     g_zdens_ao(2))
      

C
C     Recall, we did checksum using only alpha part of complex dens mat
C     in AO basis.
C     
      checksum = zmat_checksum (g_zdens_ao(1))

      if ( abs(checksum - rest_checksum) > params%tol_zero)
     $     call errquit (pname//
     $     "bad checksum while importing density matrices",0,0)

      ok = .true.
      ok = ok .and. ga_destroy(g_densre_ao(1))
      ok = ok .and. ga_destroy(g_densre_ao(2))
      ok = ok .and. ga_destroy(g_densim_ao(1))
      ok = ok .and. ga_destroy(g_densim_ao(2))
      if (.not.ok) call errquit(pname//"failed to destroy GAs", 0,0)

      if (params%prof) call prof_end (elapsed, "Loading restart point")
      end subroutine
