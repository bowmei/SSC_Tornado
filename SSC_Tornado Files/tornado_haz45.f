
      program Tornado_Haz45

c     Last modified: 8/15  

      implicit none
      include 'tornado.h'
      
      real haz(MAX_INTEN,MAX_ATTEN, MAX_FLT, MAX_WIDTH, MAXPARAM,MAX_FTYPE) 
      real haz1(MAX_INTEN)
      real testInten(MAX_INTEN)
      real al_segwt(MAX_FLT)
      integer nInten, jcalc(MAX_ATTENTYPE,MAX_ATTEN), nFlt, isite, iflt
      integer iInten, natten(MAX_FLT), iBR
      character*80 filein, file1
      integer attentype(MAX_FLT), nGM_model(MAX_ATTENTYPE), iFlag, iPrint

      integer nFtype1(MAX_FLT)
      real meanhaz(MAX_INTEN) , nonPoisson(3,MAX_INTEN), meanHaz1(MAX_FLT,MAX_INTEN), meanHaz2(MAX_INTEN)
      integer nProb      , nDam, iDam, iDam0, jBr
      integer indexrate(MAX_FLT,4)
 
      integer sssCalc(MAX_ATTENTYPE,MAX_ATTEN), scalc(MAX_ATTENTYPE,MAX_ATTEN)
      real sigFix(MAX_ATTENTYPE,MAX_ATTEN)

      real*8 haz_SSC(MAX_FLT, MAX_NODE, MAX_BR, MAX_INTEN) 
      real*8 haz_GMC(MAX_ATTENTYPE, MAX_BR, MAX_INTEN) 
      real sum, totalSegWt(MAX_FLT)

      integer n_Dip(MAX_FLT),n_bvalue(MAX_FLT), nActRate(MAX_FLT), nSR(MAX_FLT), 
     1        nRecInt(MAX_FLT), nMoRate(MAX_FLT),
     1        nRefMag(MAX_FLT,MAX_WIDTH), nFtypeModels(MAX_FLT)
      integer nFtype(MAX_FLT,MAXPARAM)
      real ftype_al(MAX_FLt,MAXPARAM,5)
      real t1, fact1

      real segwt(MAX_FLT,MAX_FLT), dipWt(MAX_FLT,MAXPARAM), bValueWt(MAX_FLT,MAXPARAM), actRateWt(MAX_FLT,MAXPARAM), 
     1     wt_SR(MAX_FLT,MAXPARAM), wt_RecInt(MAX_FLT,MAXPARAM), wt_MoRate(MAX_FLT,MAXPARAM), magRecurWt(MAX_FLT,MAXPARAM),    
     1     faultThickWt(MAX_FLT,MAXPARAM), 
     2     refMagWt(MAX_FLT,MAX_Width, MAXPARAM), ftmodelwt(MAX_FLT,MAXPARAM)
      real wt_rateMethod(MAX_FLT,4)
      integer iPer, nAttenType, nFlt0, f_start(MAX_FLT), f_num(MAX_FLT)
      integer nMagRecur(MAX_FLT)
      real contrib_min
      integer iNode, i,  jFlt, kFlt, nNode_SSC
      integer nBR_SSC(MAX_FLT,MAX_NODE), nRate(MAX_FLT), RateType(MAX_FLt,MAXPARAM)
      integer nBR_SSC1(MAX_FLT,MAX_NODE)
      integer j, k, iThick, nThick(MAX_FLT), iFM, iDip, imagRec, iThick1
      integer iSR, iAct, iRecInt, iMo, ib, j2, iSum
      real gm_wt(4,MAX_ATTEN), seg_wt1(MAX_FLT,MAX_SEG)
      integer nSegModel(MAX_FLT), segFlag(MAX_FLT, MAX_SEG)
      real ratio1, ratio2

      real dip_Wt1(MAX_FLT,MAXPARAM), bValue_Wt1(MAX_FLT,MAXPARAM), actRate_Wt1(MAX_FLT,MAXPARAM), 
     1     wt_SR1(MAX_FLT,MAXPARAM), wt_RecInt1(MAX_FLT,MAXPARAM), MoRate_wt1(MAX_FLT,MAXPARAM), 
     1     magRecur_Wt1(MAX_FLT,MAXPARAM), faultThick_Wt1(MAX_FLT,MAXPARAM), 
     2     refMag_Wt1(MAX_FLT,MAX_Width, MAXPARAM), ftype_wt1(MAX_FLT,MAXPARAM)
      real wt_rateMethod1(MAX_FLT,4), hazLevel, GM_ratio(100), GM0, GM1, GM2(MAX_BR)
    
      write (*,*) '*************************'
      write (*,*) '* Tornado Code for use with *'
      write (*,*) '*  Hazard_v5i2 code  *'
      write (*,*) '*    Sep, 2015, NAA     *'
      write (*,*) '*************************'

      write (*,*) 'Enter the input filename.'
      
      read (*,'(a80)') filein
      open (31,file=filein,status='old')

      read (31,*) iPer
      read (31,*) contrib_min
      read (31,*) Hazlevel
      pause 'tst'
     
c     Read Input File
      call RdInput ( nInten,  testInten, nGM_model, nattentype, attenType, nProb, iPer,
     2     jcalc, scalc, sigFix, sssCalc, gm_wt)
      pause 'test out of rdInput'

c     Read run file
      call Rd_Fault_Data  (nFlt, nFlt0, f_start, f_num, AttenType, 
     1           n_Dip, n_bValue, nActRate,  nSR,   nRecInt,   nMoRate,   nMagRecur,  nThick,
     1           nRefMag,  nFtypeModels,
     2           dipWt, bValueWt, actRateWt, wt_sr, wt_recInt, wt_MoRate, magRecurWt, 
     3           faultThickWt, refMagWt, ftmodelwt,
     3           nFtype, ftype_al, wt_rateMethod, al_Segwt,
     3           nRate, rateType, nBR_SSC, nSegModel, segwt, segFlag, indexRate )
       nNode_SSC = 12

c     Set nBR_SSC1 (for output)
      do iFlt=1,nFlt
       do iNode=1,nNode_SSC
        nBR_SSC1(iFlt,iNode) = nBR_SSC(iFlt,iNode)
        if ( iNode .eq. 6 ) then
          iSum = 0
          do iBR=1,4
           if ( iBR .eq. 1 .and. nSR(iFlt) .gt. 0 ) iSum = iSum + 1
           if ( iBR .eq. 2 .and. nActRate(iFlt) .gt. 0 ) iSum = iSum + 1
           if ( iBR .eq. 3 .and. nRecInt(iFlt) .gt. 0 ) iSum = iSum + 1
           if ( iBR .eq. 4 .and. nMoRate(iFlt) .gt. 0 ) iSum = iSum + 1
          enddo
          nBR_SSC1(iFlt,iNode) = iSum
        endif 
       enddo
      enddo  

      read (31,'( a80)') file1
      write (*,'( a80)') file1
      open (43,file=file1,status='unknown')

      read (31,*) iDam0, nDam

c     Loop Over Number of Dam sites (iSite is a summary used in haz runs)
      iSite = 1
      do 1000 iDam = iDam0, iDam0+nDam-1

c      Read the out1 file       
       write (*,'( 2x,''reading logic tree file'')')
       call read_logichaz ( nFlt, haz, natten, nFtype1, iPer, nProb )
       write (*,'( 2x,''out of logichaz'')')

c      THis is set up using brute force.  It is not efficient, but will be easier to modify to 
c      account for correlations later.

c         First, reset the SSC Weights to starting value for all faults
          do jFlt=1,nFlt           

c           Set Dip
            do j=1,n_Dip(jFlt)
              dip_Wt1(jFlt,j) = dipWt(jFlt,j)
            enddo

c          Set thick and refMag
           do iThick=1,nThick(jFlt)
             faultThick_Wt1(jFlt,iThick) = faultThickWt(jFlt,iThick)
             do j=1,nRefMag(jFlt,iThick) 
               refMag_Wt1(jFlt,iThick,j)  = refMagWt(jFlt,iThick,j) 
             enddo
           enddo

c          Set b-values
           do j=1,n_bValue(jFlt)
             bvalue_Wt1(jFlt,j) = bvalueWt(jFlt,j)
           enddo

c          Set mag recur
           do j=1,nMagRecur(jFlt)
             magRecur_Wt1(jFlt,j)  = magRecurWt(jFlt,j) 
           enddo

c          Set ftype
           k = 0
           do iFM=1,nFtypeModels(jFlt)
             do j=1,nFtype(jFlt,IFM)
               k = k + 1
               ftype_wt1 (jFlt,k) =  ftModelwt(jFlt, iFM) * ftype_al(jFlt,iFM,k)
             enddo
           enddo

c          set segmentation
           do i=1,nSegModel(jFlt)
            seg_wt1(jFlt,i)= segwt(jFlt,i)
           enddo

c          Set Activity Rate Method weights
           do i=1,4
             wt_RateMethod1(jFlt,i) = wt_RateMethod(jFLt,i)
           enddo

c         Set SR weights 
           do i=1,nSR(jFLt)
             wt_SR1(jFLT,i) = wt_SR(jFlt,i)
           enddo

c          Set Activity Rate weights
           do i=1,nActRate(jFLt)
             actRate_wt1(jFLT,i) = actRateWt(jFlt,i)
           enddo

c          Set Rec Int weights
           do i=1,nRecInt(jFLt)
             wt_RecInt1(jFLT,i) = wt_recInt(jFlt,i)
           enddo

c          Set moment rate weights
           do i=1,nMoRate(jFLt)
             MoRate_wt1(jFLT,i) = wt_MoRate(jFLT,i) 
           enddo

c           Find the total weight for this fault
            sum = 0.
            do i=1,nSegModel(jFlt)
              sum = sum + seg_wt1(jFlt,i) * segFlag(jFlt,i)
            enddo
            totalSegWt(jFlt) = sum

          enddo
c         End of loops to reset weights to starting values


c         Compute the mean hazard for each fault separately
          do kFlt=1,nFlt
            iPrint = 0
            call calcHaz ( haz, haz1, al_segwt, totalSegWt, 
     1         dip_Wt1, bValue_Wt1, actRate_Wt1, wt_SR1, wt_RecInt1, MoRate_wt1, magRecur_Wt1,    
     2         faultThick_Wt1, refMag_Wt1, ftype_wt1,
     3         wt_rateMethod1, gm_wt, 
     4         nInten, nFlt, attentype, nGM_model, n_Dip, n_bvalue, nRefMag,
     5         nFtype1, indexrate, nMagRecur, nRate, RateType, nThick, kflt, iPrint )
            do i=1,nInten
              meanhaz1(kFlt,i)= haz1(i)
            enddo
          enddo

c         Compute the total mean hazard for all faults
            do i=1,nInten
              meanhaz(i)= 0.
            enddo
          do iFlt=1,nFlt
            do i=1,nInten
              meanhaz(i)= meanhaz1(iFlt,i) + meanhaz(i)
            enddo
          enddo

c      SSC, reset the weights to unity for a given branch, fault and one node at a time
       do 950 kFlt = 1, nFlt
         write (*,'( 6i5)') iDam, nDam, kFlt, nFlt

        do 940 iNode=1,nNode_SSC 
         do 930, iBR=1,nBR_SSC(kFlt,iNode)

c          remove the mean hazard from this fault from total mean (add to this later)
           do iInten=1,nInten
             meanhaz2(iInten) = meanhaz(iInten) - meanhaz1(kFlt,iInten)
           enddo

c         Now, set weights to unity for the Node and Branch of interest for fault kFlt
c         SSC branches: 1 = Dip, 2=crustal thick, 3=ftype, 4=magpdf, 5=maxmag,  6=RateType, 7=SR, 8=a-value, 9=paleo, 
c                       10=Moment, 11=b_value flt, 12=segModel
c         Reset the dip weight
          if ( iNode .eq. 1 ) then
            do  iDip=1,n_Dip(kFlt)
              dip_wt1(kFlt,iDip) = 0.
            enddo
            dip_wt1(kFlt,iBR) = 1.
          endif

c         Reset the crustal thickness weight
          if ( iNode .eq. 2 ) then
            do  iThick=1,nThick(kFlt)
              faultThick_Wt1(kFlt,iThick) = 0.
            enddo
            faultThick_Wt1(kFlt,iBR) = 1.
          endif

c         Reset the ftype Model weight (This is the product of the ftmodelwt and the aleatory wt)
          if ( iNode .eq. 3 ) then
           k = 0
           do iFM=1,nFtypeModels(kFlt)
            do j=1,nFtype(kFlt,IFM)
              k = k + 1
              if ( iFM .eq. iBR ) then 
                ftype_wt1 (kFlt,k) =  ftype_al(kFlt,iFM,k)
              else
                ftype_wt1 (kFlt,k) =  0.
              endif
            enddo
           enddo
          endif

c         Reset the magpdf Model weight
          if ( iNode .eq. 4 ) then
            do iMagRec=1,nmagRecur(kFlt)
              magRecur_Wt1(kFlt,iMagRec) = 0.
            enddo
            magRecur_Wt1(kFlt,iBR) = 1. 
         endif

c         Reset the maxmag weight
c         combine all of the maxmag (by thickness) into one big branch
          if ( iNode .eq. 5 ) then
            do ithick1=1,nThick(kFlt)
              do j=1,nRefMag(kFlt,ithick1)
               refMag_Wt1(kFlt,iThick1,j) = 0.
               enddo
            enddo
            k = 0
             do ithick1=1,nThick(kFlt)
              do j=1,nRefMag(kFlt,ithick1)
                k = k + 1
                if ( k .eq. iBR) then
                  refMag_Wt1(kFlt,iThick1,j) = 1.  
                  jBR = (iBR-1)/3 + 1
                  faultThick_Wt1(kFlt,jBR) = 1.
                endif
              enddo
            enddo
           
          endif

c         Reset the rate type weight
          if ( iNode .eq. 6 ) then
           do i=1,nBR_SSC(kFlt,6)
             wt_RateMethod1(iFlt,i) = 0.
           enddo
           if ( iBR .eq. 1 .and. nSR(kFlt) .eq. 0 ) goto 930
           if ( iBR .eq. 2 .and. nActRate(kFlt) .eq. 0 ) goto 930
           if ( iBR .eq. 3 .and. nRecInt(kFlt) .eq. 0 ) goto 930
           if ( iBR .eq. 4 .and. nMoRate(kFlt) .eq. 0 ) goto 930
          endif

c         Reset the SR weight
          if ( iNode .eq. 7 ) then
            do iSR=1,nSR(kFLt)
             wt_sr1(kFlt,iSR) = 0.
            enddo
            wt_SR1(kFlt,iBR) = 1.
          endif

c         Reset the a-value weight
          if ( iNode .eq. 8 ) then
            do iAct=1,nActRate(kFLt)
             actRate_wt1(kFlt,iAct) = 0.
            enddo
            actrate_Wt1(kFlt,iBR) = 1.
          endif

c         Reset the paleo weight
          if ( iNode .eq. 9 ) then
            do iRecInt=1,nRecInt(kFLt)
             wt_recInt1(kFlt,iRecInt) = 0.
            enddo
            wt_recInt1(kFlt,iBR) = 1.
          endif

c         Reset the Moment-rate weight
          if ( iNode .eq. 10 ) then
            do iMo=1,nMoRate(kFLt)
             MoRate_wt1(kFlt,iMo) = 0.
            enddo
            MoRate_wt1(kFlt,iBR) = 1.
          endif

c         Reset the b-value (for fault) weight
          if ( iNode .eq. 11 ) then
            do ib=1,n_bvalue(kFLt)
             bvalue_wt1(kFlt,ib) = 0.
            enddo
            bvalue_wt1(kFlt,iBR) = 1.
          endif

c         Reset the segmentation weight (for fault) weight
          if ( iNode .eq. 12 ) then
            do i=1,nSegModel(kFlt)
              seg_Wt1(kFlt,i) = 0.
            enddo
            seg_Wt1(kFlt,iBR) = 1.
          endif

c         Find the total weight for this segment
          sum = 0.
          do i=1,nSegModel(kFlt)
            sum = sum + seg_wt1(kFlt,i) * segFlag(kFlt,i)
          enddo
          totalSegWt(kFlt) = sum

c         Compute the hazard for this set of weights
          iPrint = 1
          call calcHaz ( haz, haz1, al_segwt, totalSegWt, 
     1         dip_Wt1, bValue_Wt1, actRate_Wt1, wt_SR1, wt_RecInt1, MoRate_wt1, magRecur_Wt1,    
     2         faultThick_Wt1, refMag_Wt1, ftype_wt1,
     3          wt_rateMethod1, gm_wt, 
     4         nInten, nFlt, attentype, nGM_model, n_Dip, n_bvalue, nRefMag,
     5         nFtype1, indexrate, nMagRecur, nRate, RateType, nThick, kflt, iPrint )

c         Add the hazard from this fault (for this branch) to total hazard array
          do iInten=1,nInten
            haz_SSC(kFlt,iNode,iBR,iInten) = meanhaz2(iInten) + haz1(iInten)
          enddo

C   Reset the weights for this fault back to the starting weights
       jFlt = kFlt
c           Set Dip
            do j=1,n_Dip(jFlt)
              dip_Wt1(jFlt,j) = dipWt(jFlt,j)
            enddo

c          Set thick and refMag
           do iThick=1,nThick(jFlt)
             faultThick_Wt1(jFlt,iThick) = faultThickWt(jFlt,iThick)
             do j=1,nRefMag(jFlt,iThick) 
               refMag_Wt1(jFlt,iThick,j)  = refMagWt(jFlt,iThick,j) 
             enddo
           enddo

c          Set b-values
           do j=1,n_bValue(jFlt)
             bvalue_Wt1(jFlt,j) = bvalueWt(jFlt,j)
           enddo

c          Set mag recur
           do j=1,nMagRecur(jFlt)
             magRecur_Wt1(jFlt,j)  = magRecurWt(jFlt,j) 
           enddo

c          Set ftype
           k = 0
           do iFM=1,nFtypeModels(jFlt)
             do j=1,nFtype(jFlt,IFM)
               k = k + 1
               ftype_wt1 (jFlt,k) =  ftModelwt(jFlt, iFM) * ftype_al(jFlt,iFM,k)
             enddo
           enddo

c          set segmentation
           do i=1,nSegModel(jFlt)
            seg_wt1(jFlt,i)= segwt(jFlt,i)
           enddo

c          Set Activity Rate Method weights
           do i=1,4
             wt_RateMethod1(jFlt,i) = wt_RateMethod(jFLt,i)
           enddo

c         Set SR weights 
           do i=1,nSR(jFLt)
             wt_SR1(jFLT,i) = wt_SR(jFlt,i)
           enddo

c          Set Activity Rate weights
           do i=1,nActRate(jFLt)
             actRate_wt1(jFLT,i) = actRateWt(jFlt,i)
           enddo

c          Set Rec Int weights
           do i=1,nRecInt(jFLt)
             wt_RecInt1(jFLT,i) = wt_recInt(jFlt,i)
           enddo

c          Set moment rate weights
           do i=1,nMoRate(jFLt)
             MoRate_wt1(jFLT,i) = wt_MoRate(jFLT,i) 
           enddo

c           Find the total weight for this fault
            sum = 0.
            do i=1,nSegModel(jFlt)
              sum = sum + seg_wt1(jFlt,i) * segFlag(jFlt,i)
            enddo
            totalSegWt(jFlt) = sum

c         End of reset weights to starting values


 930    continue
 940    continue
 950   continue         

c       Write out sensitivity hazard curves for SSC
        read (31,'( a80)') file1
        open (42,file=file1,status='unknown')
        write (42,'( ''SSC Nodes: 1 = Dip, 2=crustal thick, 3=ftype, 4=magpdf, 5=maxmag,  6=RateType, '')')
        write (42,'( ''           7=SR, 8=a-value, 9=paleo, 10=Moment, 11=b_value flt, 12=segModel'')')

        write (42,'( 2x,'' Z values:'')')
        write(42,'(6x,25f12.4)') (testInten(J2),J2=1,nInten)
        write (42,'( 2x,''Mean hazard'')')
        write(42,'( 25e12.4)') (meanHaz(j),j=1,nInten)

        write (42,'( /,2x,''Sensitivity hazard'')')
        write (42,'( 2x,''iFlt, Number of Nodes, Number of Branches for each Node'')')
        write (42,'( 2x,'' iFlt, iNode, iBranch, hazard(z) '')')
        
        do iFlt=1,nFlt
c        write (42,'( 20i5)') iFlt, nNode_SSC, (nBR_SSC1(iFlt,iNode),iNode=1,nNode_SSC)
         do iNode=1,nNode_SSC
          do iBR=1,nBR_SSC(iFlt,iNode)
            if ( iNode .eq. 6 ) then
              if ( iBR .eq. 1 .and. nSR(iFlt) .eq. 0 ) goto 990
              if ( iBR .eq. 2 .and. nActRate(iFlt) .eq. 0 ) goto 990
              if ( iBR .eq. 3 .and. nRecInt(iFlt) .eq. 0 ) goto 990
              if ( iBR .eq. 4 .and. nMoRate(iFlt) .eq. 0 ) goto 990
            endif
            if ( nBR_SSC1(iFlt,iNode) .eq. 1 ) goto 990
            write (42,'( 6x, 3i5,25e12.4)') iFlt, iNode, iBR, (haz_SSC(iFlt,iNode,iBR,iInten),iInten=1,nInten)
 990        continue
          enddo
         enddo
        enddo
        close (42)

c      Interpolate the desired hazard level for tornado plot
c      First find the GM for the mean hazard, interpolated to desired haz level
       do iInten=2,nInten
         if ( meanhaz(iInten-1) .ge. hazLevel .and. meanhaz(iInten) .le. hazLevel ) then
          GM0 = exp( alog(hazLevel / meanhaz(iInten-1)) / 
     1                  alog( meanhaz(iInten)/ meanhaz(iInten-1))
     2                  * alog( testInten(iInten)/testInten(iInten-1) ) + alog(testInten(iInten-1)) )
         endif
        enddo

        do iFlt=1,nFlt
         do iNode=1,nNode_SSC
          do k=1,9
             GM_ratio(k) = 1.
          enddo

          k = 0
          do iBR=1,nBR_SSC(iFlt,iNode)
            if ( iNode .eq. 6 ) then
              if ( iBR .eq. 1 .and. nSR(iFlt) .eq. 0 ) goto 995
              if ( iBR .eq. 2 .and. nActRate(iFlt) .eq. 0 ) goto 995
              if ( iBR .eq. 3 .and. nRecInt(iFlt) .eq. 0 ) goto 995
              if ( iBR .eq. 4 .and. nMoRate(iFlt) .eq. 0 ) goto 995
            endif
            if ( nBR_SSC1(iFlt,iNode) .eq. 1 ) goto 995
 
c           Interpolate
            k = k + 1
            GM_ratio(k) = -999.
            do iInten=2,nInten
              if ( haz_SSC(iFlt,iNode,iBR,iInten-1) .ge. hazLevel
     1        .and. haz_SSC(iFlt,iNode,iBR,iInten)  .le. hazLevel ) then
                 GM1 = exp( alog(hazLevel / haz_SSC(iFlt,iNode,iBR,iInten-1)) / 
     1                  alog( haz_SSC(iFlt,iNode,iBR,iInten)/ haz_SSC(iFlt,iNode,iBR,iInten-1))
     2                  * alog( testInten(iInten)/testInten(iInten-1) ) + alog(testInten(iInten-1)) )

c                save GM from thickness, to use to normalize the maxmag
                 if (iNode .eq. 2 ) then
                   GM2(iBR) = GM1
                   write (*,'( i5,f10.4)') iBr, GM1
                 endif

                 if ( iNode .ne. 5 ) then
                   GM_ratio(k) = GM1 / GM0
                 else
                   jBR = (iBR-1)/3 + 1
                   GM_ratio(k) = GM1 / GM2(jBR)
                 endif
                 goto 995 
              endif
            enddo
 995        continue
          enddo

c         Check if the range is large enought to be relevant
          ratio1 = 1 - contrib_min
          ratio2 = 1 + contrib_min
          iFlag = 0
          do iBR=1,k
            if (GM_ratio(iBR) .gt. 0. ) then
              if ( GM_ratio(iBR) .lt. ratio1 .or. GM_ratio(iBR) .gt. ratio2 ) iFlag = 1         
            endif
          enddo

c         Find max factor for this branch
          fact1 = 0.
          do iBR=1,k
            t1 = abs (  alog(GM_ratio(iBR) ) )
            if ( t1 .gt. fact1 ) fact1 = t1
          enddo

          if ( iFlag .eq. 1 ) write (43,'( 6x, 3i5,f10.3, 25f10.4)') iDam, iFlt, iNode,  fact1, (GM_ratio(iBR), iBR=1,9)
         enddo

        enddo

c       Set branch for non-poisson
c       interpolate the meanhaz and scaled mean haz
        do iInten=1,nInten
          nonPoisson(1,iInten) = meanhaz(iInten) * 0.5          
          nonPoisson(2,iInten) = meanhaz(iInten) * 1.          
          nonPoisson(3,iInten) = meanhaz(iInten) * 2.          
        enddo
          do k=1,9
             GM_ratio(k) = 1.
          enddo

        do j=1,3
          do iInten=2,nInten
            if ( nonPoisson(j,iInten-1) .ge. hazLevel .and. nonPoisson(j,iInten)  .le. hazLevel ) then
                 GM1 = exp( alog(hazLevel / nonPoisson(j,iInten-1)) / 
     1                  alog( nonPoisson(j,iInten)/ nonPoisson(j,iInten-1))
     2                  * alog( testInten(iInten)/testInten(iInten-1) ) + alog(testInten(iInten-1)) )
                 GM_ratio(j) = GM1 / GM0
                 goto 997
            endif
          enddo
 997      continue
        enddo
        iFlt=0
        iNode = 13
        write (43,'( 6x, 3i5,25e12.4)') iDam, iFlt, iNode,  (GM_ratio(iBR), iBR=1,9)
        call flush (43)


c       Write out tornado for GMC
c        read (31,'( a80)') file1
c        open (43,file=file1,status='new')
c        write(43,'(3x,25f12.4)') (testInten(J2),J2=1,nInten)
c        do j=1,nAttenType
c          do iBR=1,nGM_Model(j)
c            write (43,'( 2i5,f8.3, 25e12.4)') jcalc(j,iBR), scalc(j,iBR), sigFix(j,iBR),  
c     1             (haz_GMC(j,iBR,iInten ),iInten=1,nInten)
c          enddo
c        enddo
c       close (43)



 1000 continue

      write (*,*) 
      write (*,*) '*** Tornado Code (45) Completed with Normal Termination ***'

      stop
      end

