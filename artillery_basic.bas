100 REM  TI BASIC GUNS - TURSI 2017  
110 DIM CC$(101),HPAT$(4)
115 DIM SVR(101),SVC(101)
120 GOTO 470

REM ---------
REM this subroutine plots a pixel at DOTROW,DOTCOL
REM putting it at the beginning supposedly helps
REM it execute quicker.
REM ---------

REM convert dot coordinates to character coordinates
130 MR=INT(DOTROW/8)+1
140 MC=INT(DOTCOL/8)+1

REM check what's already there
150 CALL GCHAR(MR,MC,CH)
REM if it's assigned to plotting, we can just reuse it
160 IF CH>=STARTCHAR THEN 240
REM if it's a space, we can assign a new plotting character
170 IF CH=32 THEN 190
REM anything else, go back (this is how we see a hit gun)
180 RETURN

REM assign a new character to replace a space
190 CH=CURCHAR
200 CURCHAR=CURCHAR+1
210 IF CURCHAR<LASTCHAR THEN 240
REM loop around if we 'run out of ink'
220 CURCHAR=STARTCHAR


REM we have the character to redefine, so get the pattern
240 TC$=CC$(CH-STARTCHAR)
REM now get the offset into the pattern
250 XR=DOTROW-(MR-1)*8
260 XC=DOTCOL-(MC-1)*8
270 P=XR*2+1
REM this gives us the second nibble of a row
280 IF XC<4 THEN 310
290 P=P+1
300 XC=XC-4
REM and get the actual nibble to change
310 X$=SEG$(TC$,P,1)
REM this line uses the four lookup strings to convert
REM the existing pattern into the new pattern with 'XC' set
320 TT$=SEG$(HPAT$(XC),POS(HEX$,X$,1),1)
REM and this inserts it back into the CHAR string
330 TC$=SEG$(TC$,1,P-1)&TT$&SEG$(TC$,P+1,16-P)
REM assign the value
340 CALL CHAR(CH,TC$)
REM and save it off - TI BASIC doesn't have CALL CHARPAT or we'd use that
350 CC$(CH-STARTCHAR)=TC$
REM plot it on the screen - it's faster to do it than check if we need to
360 CALL HCHAR(MR,MC,CH)
REM all done
370 RETURN

REM ---------
REM this subroutine gets a digit from the user at R,P
REM it also watches for SPACE and jumps to restart if pressed
REM ---------

REM check for old key still held down
380 CALL KEY(5,K,S)
390 IF S<>0 THEN 380

REM display the cursor
400 CALL HCHAR(R,P,30)
REM read the keyboard
410 CALL KEY(5,K,S)
REM erase the cursor
420 CALL HCHAR(R,P,32)
REM if space, then go restart
430 IF K=32 THEN 1760
REM if not '1' through '9', go back to cursor
440 IF (K>58)+(K<49)THEN 400
REM display the result
450 CALL HCHAR(R,P,K)
460 RETURN

REM ---------
REM Main program starts here
REM ---------

REM reset the character patterns for plotting
470 GOSUB 1810
REM random numbers
480 RANDOMIZE

REM these set up the legal character range for plotting
REM to use, and set up the four mapping tables for adding
REM one bit to a nibble
490 CURCHAR=58
500 STARTCHAR=58
510 LASTCHAR=159
520 HEX$="0123456789ABCDEF"
530 HPAT$(0)="89ABCDEF89ABCDEF"
540 HPAT$(1)="45674567CDEFCDEF"
550 HPAT$(2)="23236767ABABEFEF"
560 HPAT$(3)="1133557799BBDDFF"

REM set everything to white on black
570 FOR A=1 TO 16
580 CALL COLOR(A,16,2)
590 NEXT A

REM initialize graphics
REM 34-block, 35-A, 36-F, 37-explosion, 38,39-guns, 40,41-arrows
600 CALL CLEAR
610 CALL CHAR(34,"FFFFFFFFFFFFFFFF")
620 CALL CHAR(35,"183C243C7E666666")
630 CALL CHAR(36,"7E7E607878606060")
640 CALL CHAR(37,"0002145E3C1C1200")
650 CALL CHAR(38,"00020418183C427E")
660 CALL CHAR(39,"00402018183C427E")
670 CALL CHAR(40,"0010087C08100000")
680 CALL CHAR(41,"0008103E10080000")

REM some constants 
REM 2*PI in Radians
690 PI2=6.2831853
REM arbitrary gravity force
700 GRAV=.3
REM PI/2 in Radians
710 PIH=PI2/4

REM ---------
REM Main loop starts here
REM ---------

REM first we draw the screen. TER selects a random
REM offset in a sine wave and DIV selects randomly
REM how fast to step through it. We then just draw
REM the partial SINE wave on the screen.
720 CALL CLEAR
730 TER=RND*PI2
740 DIV=RND*128+64
750 FOR C=1 TO 32

REM calculate starting height, 18 is the center row
760 H=SIN(TER+(PI2/DIV)*C)*5+18
770 CALL VCHAR(H,C,34,25-H)

REM check for gun 1, and draw and save it when reached
780 IF C<>3 THEN 810
790 CALL HCHAR(H-1,C,38)
800 H1=INT(H-0.5)

REM check for gun 2, and draw and save it when reached
810 IF C<>30 THEN 840
820 CALL HCHAR(H-1,C,39)
830 H2=INT(H-0.5)
840 NEXT C

REM calculate a random wind for this stage. Even this is probably too high 
850 WIND=RND-.5

REM decide which arrow to draw
860 IF WIND>0 THEN 890
870 CALL HCHAR(2,16,41)
880 GOTO 900
890 CALL HCHAR(2,16,40)

REM ---------
REM Player 1 turn starts here
REM ---------

REM redraw the bottom line in case it was erased by a shot
900 CALL HCHAR(24,1,34,32)

REM request the Angle
910 CALL HCHAR(1,3,35)
920 P=4
930 R=1
940 GOSUB 380
REM invert and scale to 1-9
950 AN=10-(K-48)

REM request the Force
960 CALL HCHAR(2,3,36)
970 P=4
980 R=2
990 GOSUB 380
REM scale to 2-18
1000 FO=(K-48)*2

REM calculate the vertical and horizontal components of the shot
1010 VF=COS(AN/10*PIH)*FO
1020 HF=SIN(AN/10*PIH)*FO

REM set the shot's position
1030 SROW=(H1-2)*8
1040 SCOL=24

REM ---------
REM Loop for player 1 shot
REM ---------

REM calculate the rounded screen position
REM (the plotter code does not work well with non-integers)
1050 DOTROW=INT(SROW+.5)
1060 DOTCOL=INT(SCOL+.5)
REM if we are off the edge of the screen, then the shot is done
1070 IF (DOTCOL<1)+(DOTCOL>255)THEN 1330
REM but if we are just off the top, just skip drawing
1080 IF DOTROW<17 THEN 1110
REM draw the pixel
1090 GOSUB 130
REM check if the draw function detected something
1100 IF CH<STARTCHAR THEN 1160

REM This updates the shot position by the forces, then updates
REM the forces (vertical by gravity, horizontal by wind)
1102 SVR(CH-STARTCHAR)=MR
1104 SVC(CH-STARTCHAR)=MC
1110 SCOL=SCOL+HF
1120 SROW=SROW-VF
1130 VF=VF-GRAV
1140 HF=HF+WIND

REM loop around and keep moving the shot
1150 GOTO 1050

REM ---------
REM Plot function detected something during P1 shot
REM ---------

REM if it's a gun (either one!), go blow it up
1160 IF (CH=38)+(CH=39)THEN 1250

REM otherwise assume it's terrain. Draw a little boom and erase
1170 CALL HCHAR(MR,MC,37)
1180 CALL SOUND(500,-5,0)
1190 CALL SOUND(1,-5,0)
1200 CALL HCHAR(MR,MC,32)

REM check if we erased the ground under a player
1210 IF (MR=H1+1)*(MC=3)THEN 1230
1215 IF (MR=H2+1)*(MC=30)THEN 1230
REM Nope, so go play player 2
1220 GOTO 1330

REM we did erase the ground under a player - make him fall
1230 CALL HCHAR(MR-1,3,32)
1240 CALL HCHAR(MR,3,38)
REM then fall into the normal death code

REM ---------
REM Player dead from P1 shot (it might be P1  )
REM ---------

REM loop a short blinking explosion
1250 FOR A=1 TO 3
1260 CALL HCHAR(MR,MC,37)
1270 CALL SOUND(700,-6,0)
1280 CALL HCHAR(MR,MC,33)
1290 CALL SOUND(100,-7,0)
1300 NEXT A
REM erase it
1310 CALL HCHAR(MR,MC,32)
REM go wait for key to replay
1320 GOTO 1770

REM ---------
REM Player 2 turn - much the same as player 1
REM but horizontal movement is negative 
REM ---------

REM redraw bottom line
1330 CALL HCHAR(24,1,34,32)

REM get Angle
1340 CALL HCHAR(1,29,35)
1350 P=30
1360 R=1
1370 GOSUB 380
1380 AN=10-(K-48)

REM get force
1390 CALL HCHAR(2,29,36)
1400 P=30
1410 R=2
1420 GOSUB 380
1430 FO=(K-48)*2

REM calculate vectors
1440 VF=COS(AN/10*PIH)*FO
1450 HF=SIN(AN/10*PIH)*FO
1460 SROW=(H2-2)*8
1470 SCOL=232

REM run P2's shot
1480 DOTROW=INT(SROW+.5)
1490 DOTCOL=INT(SCOL+.5)
1500 IF (DOTCOL<1)+(DOTCOL>255)THEN 1650
1510 IF DOTROW<17 THEN 1540
1520 GOSUB 130
1530 IF CH<STARTCHAR THEN 1590
1532 SVR(CH-STARTCHAR)=MR
1534 SVC(CH-STARTCHAR)=MC
1540 SCOL=SCOL-HF
1550 SROW=SROW-VF
1560 VF=VF-GRAV
1570 HF=HF-WIND
1580 GOTO 1480
1590 IF (CH=38)+(CH=39)THEN 1680
1600 CALL HCHAR(MR,MC,37)
1610 CALL SOUND(500,-5,0)
1620 CALL SOUND(1,-5,0)
1630 CALL HCHAR(MR,MC,32)
1640 IF (MR=H1+1)*(MC=3)THEN 1660
1645 IF (MR=H2+1)*(MC=30)THEN 1660
REM clear dots
1650 FOR A=0 TO 101
1651 IF SVR(A)=0 THEN 1657
1652 CALL HCHAR(SVR(A), SVC(A), 32)
1653 CC$(A)="0000000000000000"
1654 SVR(A)=0
1657 NEXT A
1658 CURCHAR=STARTCHAR
REM back to player 1
1659 GOTO 900

REM player falls (might be either one)
1660 CALL HCHAR(MR-1,30,32)
1670 CALL HCHAR(MR,30,39)

REM player boom
1680 FOR A=1 TO 3
1690 CALL HCHAR(MR,MC,37)
1700 CALL SOUND(700,-6,0)
1710 CALL HCHAR(MR,MC,33)
1720 CALL SOUND(100,-7,0)
1730 NEXT A
1740 CALL HCHAR(MR,MC,32)
REM go wait for new game
1750 GOTO 1770

REM aborted game comes here, erases the top window
1760 CALL HCHAR(1,1,32,64)

REM wait for new game here - requires a new keypress
1770 CALL KEY(0,K,S)
1780 IF S<>1 THEN 1770
REM erase the character patterns
1790 GOSUB 1810
REM go play again
1800 GOTO 720

REM ---------
REM Short subroutine to reset the plot characters
REM ---------

1810 FOR A=0 TO 101
1820 CC$(A)="0000000000000000"
1830 NEXT A
1840 RETURN