;
; United Forces Intro
;
; Disassembly by MnemoTroN
; 2024-04-02
;

	SECTION	main,CODE_C

	include	"startup.i"
	even

;	move.l	#MAIN,$80.w
;	trap	#0
;	clr.l	d0
;	rts

MAIN:
;	movem.l	d0-d7/a0-a6,-(sp)
	bsr	calc_blitdata
	bsr	copy_images
	bsr	calc_scrollcopper
	bsr	mt_init

	lea	sprite_buffer,a0
	move.l	#$20003002,(a0)+
	move.w	#292,d7
	moveq	#0,d0
lbC000034:
	move.l	d0,(a0)+
	dbra	d7,lbC000034

	move.l	#sprite_buffer,d0
	lea	cop_sprite_addr(pc),a0
	move.w	d0,4(a0)
	swap	d0
	move.w	d0,(a0)

	lea	lbL0034A0(pc),a0
	moveq	#9,d7
	moveq	#0,d0
lbC000054:
	move.l	d0,(a0)+
	dbra	d7,lbC000054

	lea	$DFF000,a6
	lea	sineoffset1(pc),a5
	move.w	$1C(a6),intena_save-sineoffset1(a5)
	or.w	#$8000,intena_save-sineoffset1(a5)
	move.w	#$7FFF,$9A(a6)			;INTENA
	move.w	2(a6),dmacon_save-sineoffset1(a5)
	or.w	#$8000,dmacon_save-sineoffset1(a5)
	move.w	#$7FFF,$96(a6)			;DMACON
	move.w	#$83E0,$96(a6)			;DMACON
	move.l	#copperlist,$84(a6)		;COP2LCHx
	clr.w	$8A(a6)				;COPJMP2
mainloop:
	lea	$DFF000,a6
lbC0000A0:
	btst	#0,5(a6)			;VPOSR, V8=Line 256
	beq.s	lbC0000A0
lbC0000A8:
	btst	#0,5(a6)
	bne.s	lbC0000A8
	bsr	do_spritescroller
	bsr	clear_bitplane
	bsr	draw_bitplane
	bsr	mt_music
	btst	#6,$BFE001
	bne.s	mainloop

	bsr	mt_off

; startup.i will restore
;
;	lea	$DFF000,a6
;	clr.w	$88(a6)				;COPJMP1
;	move.w	intena_save(pc),$9A(a6)		;INTENA
;	move.w	dmacon_save(pc),$96(a6)		;DMACON
;	movem.l	(sp)+,d0-d7/a0-a6
;	rte
	rts

calc_blitdata:
	lea	bltcontable(pc),a0
	lea	blitaddrtable(pc),a1
	moveq	#0,d0			;x position counter
	move.w	#287,d7
lbC0000F8:
	move.w	d0,d1
	move.w	d0,d2
	lsr.w	#4,d1			;x div 16
	add.w	d1,d1			;mul 2
	move.w	d1,(a1)+
	move.w	d1,(a1)+
	and.w	#15,d2			;x and 15
	ror.w	#4,d2			;ASH3-0 = shift by 0-15 pixels
	move.w	d2,2(a0)		;value for BLTCON1
	or.w	#%0000111111100010,d2	;$0FE2
	move.w	d2,(a0)			;value for BLTCON0
	addq.l	#4,a0
	addq.w	#1,d0			;inc x
	dbra	d7,lbC0000F8
	rts

copy_images:
	lea	lbL000372(pc),a0
	lea	lbL000462(pc),a1
	move.w	#26,d7			;copy 27 times
lbC00012A:
	move.l	a0,a2
	moveq	#59,d6			;60 longwords per image
lbC00012E:
	move.l	(a2)+,(a1)+
	dbra	d6,lbC00012E
	dbra	d7,lbC00012A
	rts

calc_scrollcopper:
	lea	cop_spritepos(pc),a0
	move.w	#$1FDF,d0
	move.w	#$90,d1
	move.w	#271,d7
lbC00014A:
	move.w	d1,d2
	move.w	d1,d3
	addq.w	#1,d1
	lsr.w	#1,d2
	and.w	#1,d3
	or.w	#$3002,d3
	move.w	d0,(a0)+		;1FDF
	add.w	#$100,d0
	move.l	#$FFFE0140,(a0)+	;$FFFE, SPR0POS
	move.w	d2,(a0)+
	move.w	#$142,(a0)+		;SPR0CTL
	move.w	d3,(a0)+
	dbra	d7,lbC00014A
	rts

WaitBlitter:
	btst	#6,2(a6)
lbC00017A:
	btst	#6,2(a6)
	bne.s	lbC00017A
	rts

clear_bitplane:
	lea	$DFF000,a6
	bsr.s	WaitBlitter
	move.w	#$8400,$96(a6)			;DMACON
	move.w	#$100,$40(a6)			;BLTCON0 = Only USED
	move.l	#$70000,$54(a6)			;BLTDPTx
	clr.w	(a6)				;BLTDDAT
	clr.w	$66(a6)				;BLTDMOD
	move.w	#(6<<6)+18,$58(a6)		;BLTSIZE, $192, height=6, width=18 words
	rts

draw_bitplane:
	lea	sineoffset1(pc),a0
	move.l	sp,stack_save-sineoffset1(a0)
	lea	$DFF000,a6
	bsr.s	WaitBlitter
	move.w	#$FFFF,$44(a6)			;BLTAFWM
	clr.w	$46(a6)				;BLTALWM
	move.l	#$001EFFFA,$60(a6)		;BLTCMOD=30/BLTBMOD=-6
	move.l	#$FFFE001E,$64(a6)		;BLTAMOD=-2/BLTDMOD=30
	moveq	#7,d0
	move.w	d0,$54(a6)			;BLTDPTH
	move.w	d0,$48(a6)			;BLTCPTH
	lea	lbL000372(pc),a0
	move.l	a0,$50(a6)			;BLTAPTx
	lea	blitmask(pc),a0
	move.l	a0,$4C(a6)			;BLTBPTx
	move.w	#$8400,$96(a6)			;DMACON
	moveq	#14,d0				;Sineoffset1 delta
	moveq	#20,d1				;Sineoffset2 delta
	move.w	#$3FF,d3
	lea	sineoffset1(pc),a0
	add.w	#6,(a0)				;inc sineoffset1
	move.w	(a0),d4
	and.w	d3,d4
	add.w	#-10,sineoffset2-sineoffset1(a0)	;dec sineoffset2
	move.w	sineoffset2-sineoffset1(a0),d5
	and.w	d3,d5
	move.w	#(6<<6)+3,d6			;value for BLTSIZE, height=6, width=3 words
	lea	sinetable(pc),a0
	lea	bltcontable(pc),a1
	lea	blitaddrtable(pc),a2
	lea	$40(a6),a3			;BLTCON0
	lea	$4A(a6),a4			;BLTCPTL
	lea	$50(a6),a5			;BLTAPTH
	lea	$58(a6),sp			;BLTSIZE
	lea	$56(a6),a6			;BLTDPTL
	move.w	#249,d7
wait_for_line36:
	cmp.b	#36,-$50(a6)			;VHPOSR, wait for line 36
	blt.s	wait_for_line36
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

blitloop:
	move.w	(a0,d4.w),d2			;get sine1 pos
	add.w	(a0,d5.w),d2			;add sine2 pos
	add.w	d0,d4				;add sine1 delta
	add.w	d1,d5				;add sine2 delta
	and.w	d3,d4				;limit sine1
	and.w	d3,d5				;limit sine2
	move.l	(a1,d2.w),(a3)			;write BLTCON0/BLTCON1 from table
	move.w	(a2,d2.w),d2			;get pre-calced address ($7xxxx)
	move.w	d2,(a4)				;BLTCPTL
	move.w	d2,(a6)				;BLTDPTL
	move.w	d6,(sp)				;BLTSIZE
	nop
	nop
	nop
	nop
	dbra	d7,blitloop

	move.l	stack_save(pc),sp		;restore A7
	rts

do_spritescroller:
	lea	$DFF000,a6
	bsr	WaitBlitter
	lea	sineoffset1(pc),a5
	move.w	#$9F0,$40(a6)			;BLTCON0
	clr.w	$42(a6)				;BLTCON1
	lea	sprite_buffer+4,a0
	move.l	a0,$54(a6)			;BLTDPTx
	addq.l	#4,a0
	move.l	a0,$50(a6)			;BLTAPTx
	moveq	#2,d0
	move.w	d0,$64(a6)			;BLTAMOD
	move.w	d0,$66(a6)			;BLTDMOD
	move.l	#$FFFFFFFF,$44(a6)		;BLTAFWM/BLTALWM
	move.w	#(291<<6)+1,$58(a6)		;BLTSIZE, $48C1
	subq.w	#1,scrollcount-sineoffset1(a5)
	bne.s	lbC00035A
lbC0002F0:
	move.l	scrolltextptr-sineoffset1(a5),a0
	addq.l	#1,scrolltextptr-sineoffset1(a5)
	move.b	(a0),d0
	bne.s	notend

	lea	scrolltext(pc),a1
	move.l	a1,scrolltextptr-sineoffset1(a5)
	bra.s	lbC0002F0

notend:
	sub.b	#$30,d0
	lsl.w	#2,d0
	move.l	fontinfo-sineoffset1(a5,d0.w),d0	;get address+height
	move.w	d0,scrollheight-sineoffset1(a5)
	move.w	d0,scrollcount-sineoffset1(a5)
	sub.w	#6,scrollcount-sineoffset1(a5)
	swap	d0
	lea	scrollfont(pc),a0
	add.w	d0,a0
	bsr	WaitBlitter
	move.l	a0,$50(a6)			;BLTAPTx
	move.l	#sprite_buffer+273*4,$54(a6)	;BLTDPTx
	move.l	#sprite_buffer+273*4,$4C(a6)	;BLTBPTx
	move.w	#2,$62(a6)			;BLTBMOD
	move.w	#$26,$64(a6)			;BLTAMOD
	move.w	#$DFC,$40(a6)			;BLTCON0
	swap	d0
	lsl.w	#6,d0
	addq.w	#1,d0
	move.w	d0,$58(a6)			;BLTSIZE
lbC00035A:
	lea	sprite_buffer+273*4,a0
	move.w	scrollheight-sineoffset1(a5),d0
	addq.w	#3,d0
	asl.w	#2,d0
	add.w	d0,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	rts

lbL000372:
	dc.l	%00110000110001100001100000000000
	dc.l	%00111100111111100111100000000000
	dc.l	%11000011000000011000011000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%11001111001110011110011000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%00110000110001100001100000000000
	dc.l	%11000011000000011000011000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%11001111001110011110011000000000
	dc.l	%00001100001110000110000000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%00110000110001100001100000000000
	dc.l	%00111100111111100111100000000000
	dc.l	%00111100111111100111100000000000
	dc.l	%00111100111111100111100000000000
	dc.l	%11000011000000011000011000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%11001111001110011110011000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%00110000110001100001100000000000
	dc.l	%11000011000000011000011000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%00000000000000000000000000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%11001111001110011110011000000000
	dc.l	%00001100001110000110000000000000
	dc.l	%00001100001110000110000000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%00110000110001100001100000000000
	dc.l	%00111100111111100111100000000000
	dc.l	%11000011000000011000011000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111100000000000111111000000000
	dc.l	%11001111001110011110011000000000
	dc.l	%11110011110001111001111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111111111111111111111000000000
	dc.l	%11111100000000000111111000000000

lbL000462:
	ds.l	27*60

bltcontable:
	ds.l	288

blitaddrtable:
	ds.l	288

sinetable:
	dc.w	$108,$108,$10C,$110,$114,$118,$118,$11C
	dc.w	$120,$124,$128,$128,$12C,$130,$134,$138
	dc.w	$138,$13C,$140,$144,$148,$148,$14C,$150
	dc.w	$154,$154,$158,$15C,$160,$160,$164,$168
	dc.w	$16C,$16C,$170,$174,$178,$178,$17C,$180
	dc.w	$184,$184,$188,$18C,$18C,$190,$194,$194
	dc.w	$198,$19C,$19C,$1A0,$1A4,$1A4,$1A8,$1AC
	dc.w	$1AC,$1B0,$1B4,$1B4,$1B8,$1B8,$1BC,$1C0
	dc.w	$1C0,$1C4,$1C4,$1C8,$1C8,$1CC,$1CC,$1D0
	dc.w	$1D0,$1D4,$1D8,$1D8,$1D8,$1DC,$1DC,$1E0
	dc.w	$1E0,$1E4,$1E4,$1E8,$1E8,$1E8,$1EC,$1EC
	dc.w	$1F0,$1F0,$1F0,$1F4,$1F4,$1F4,$1F8,$1F8
	dc.w	$1F8,$1FC,$1FC,$1FC,$200,$200,$200,$200
	dc.w	$204,$204,$204,$204,$208,$208,$208,$208
	dc.w	$208,$208,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$208
	dc.w	$208,$208,$208,$208,$208,$204,$204,$204
	dc.w	$204,$200,$200,$200,$200,$1FC,$1FC,$1FC
	dc.w	$1FC,$1F8,$1F8,$1F8,$1F4,$1F4,$1F4,$1F0
	dc.w	$1F0,$1EC,$1EC,$1EC,$1E8,$1E8,$1E4,$1E4
	dc.w	$1E0,$1E0,$1E0,$1DC,$1DC,$1D8,$1D8,$1D4
	dc.w	$1D4,$1D0,$1D0,$1CC,$1C8,$1C8,$1C4,$1C4
	dc.w	$1C0,$1C0,$1BC,$1BC,$1B8,$1B4,$1B4,$1B0
	dc.w	$1AC,$1AC,$1A8,$1A8,$1A4,$1A0,$1A0,$19C
	dc.w	$198,$198,$194,$190,$190,$18C,$188,$184
	dc.w	$184,$180,$17C,$17C,$178,$174,$170,$170
	dc.w	$16C,$168,$164,$164,$160,$15C,$158,$158
	dc.w	$154,$150,$14C,$148,$148,$144,$140,$13C
	dc.w	$13C,$138,$134,$130,$12C,$12C,$128,$124
	dc.w	$120,$11C,$11C,$118,$114,$110,$10C,$108
	dc.w	$108,$108,$104,$100,$FC,$FC,$F8,$F4
	dc.w	$F0,$EC,$EC,$E8,$E4,$E0,$DC,$DC
	dc.w	$D8,$D4,$D0,$CC,$CC,$C8,$C4,$C0
	dc.w	$C0,$BC,$B8,$B4,$B0,$B0,$AC,$A8
	dc.w	$A4,$A4,$A0,$9C,$98,$98,$94,$90
	dc.w	$90,$8C,$88,$84,$84,$80,$7C,$7C
	dc.w	$78,$74,$74,$70,$6C,$6C,$68,$64
	dc.w	$64,$60,$60,$5C,$58,$58,$54,$54
	dc.w	$50,$4C,$4C,$48,$48,$44,$44,$40
	dc.w	$40,$3C,$3C,$38,$38,$34,$34,$30
	dc.w	$30,$2C,$2C,$28,$28,$28,$24,$24
	dc.w	$20,$20,$20,$1C,$1C,$1C,$18,$18
	dc.w	$18,$14,$14,$14,$10,$10,$10,$10
	dc.w	12,12,12,12,12,8,8,8
	dc.w	8,8,8,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,8
	dc.w	8,8,8,8,8,12,12,12
	dc.w	12,12,$10,$10,$10,$14,$14,$14
	dc.w	$14,$18,$18,$18,$1C,$1C,$1C,$20
	dc.w	$20,$24,$24,$24,$28,$28,$2C,$2C
	dc.w	$2C,$30,$30,$34,$34,$38,$38,$3C
	dc.w	$3C,$40,$40,$44,$44,$48,$48,$4C
	dc.w	$50,$50,$54,$54,$58,$5C,$5C,$60
	dc.w	$60,$64,$68,$68,$6C,$70,$70,$74
	dc.w	$78,$78,$7C,$80,$80,$84,$88,$88
	dc.w	$8C,$90,$94,$94,$98,$9C,$9C,$A0
	dc.w	$A4,$A8,$A8,$AC,$B0,$B4,$B4,$B8
	dc.w	$BC,$C0,$C4,$C4,$C8,$CC,$D0,$D4
	dc.w	$D4,$D8,$DC,$E0,$E0,$E4,$E8,$EC
	dc.w	$F0,$F4,$F4,$F8,$FC,$100,$104,$104
	dc.w	$108,$108,$10C,$110,$114,$118,$118,$11C
	dc.w	$120,$124,$128,$128,$12C,$130,$134,$138
	dc.w	$138,$13C,$140,$144,$148,$148,$14C,$150
	dc.w	$154,$154,$158,$15C,$160,$160,$164,$168
	dc.w	$16C,$16C,$170,$174,$178,$178,$17C,$180
	dc.w	$184,$184,$188,$18C,$18C,$190,$194,$194
	dc.w	$198,$19C,$19C,$1A0,$1A4,$1A4,$1A8,$1AC
	dc.w	$1AC,$1B0,$1B4,$1B4,$1B8,$1B8,$1BC,$1C0
	dc.w	$1C0,$1C4,$1C4,$1C8,$1C8,$1CC,$1CC,$1D0
	dc.w	$1D0,$1D4,$1D8,$1D8,$1D8,$1DC,$1DC,$1E0
	dc.w	$1E0,$1E4,$1E4,$1E8,$1E8,$1E8,$1EC,$1EC
	dc.w	$1F0,$1F0,$1F0,$1F4,$1F4,$1F4,$1F8,$1F8
	dc.w	$1F8,$1FC,$1FC,$1FC,$200,$200,$200,$200
	dc.w	$204,$204,$204,$204,$208,$208,$208,$208
	dc.w	$208,$208,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$20C
	dc.w	$20C,$20C,$20C,$20C,$20C,$20C,$20C,$208
	dc.w	$208,$208,$208,$208,$208,$204,$204,$204
	dc.w	$204,$200,$200,$200,$200,$1FC,$1FC,$1FC
	dc.w	$1FC,$1F8,$1F8,$1F8,$1F4,$1F4,$1F4,$1F0
	dc.w	$1F0,$1EC,$1EC,$1EC,$1E8,$1E8,$1E4,$1E4
	dc.w	$1E0,$1E0,$1E0,$1DC,$1DC,$1D8,$1D8,$1D4
	dc.w	$1D4,$1D0,$1D0,$1CC,$1C8,$1C8,$1C4,$1C4
	dc.w	$1C0,$1C0,$1BC,$1BC,$1B8,$1B4,$1B4,$1B0
	dc.w	$1AC,$1AC,$1A8,$1A8,$1A4,$1A0,$1A0,$19C
	dc.w	$198,$198,$194,$190,$190,$18C,$188,$184
	dc.w	$184,$180,$17C,$17C,$178,$174,$170,$170
	dc.w	$16C,$168,$164,$164,$160,$15C,$158,$158
	dc.w	$154,$150,$14C,$148,$148,$144,$140,$13C
	dc.w	$13C,$138,$134,$130,$12C,$12C,$128,$124
	dc.w	$120,$11C,$11C,$118,$114,$110,$10C,$108
	dc.w	$108,$108,$104,$100,$FC,$FC,$F8,$F4
	dc.w	$F0,$EC,$EC,$E8,$E4,$E0,$DC,$DC
	dc.w	$D8,$D4,$D0,$CC,$CC,$C8,$C4,$C0
	dc.w	$C0,$BC,$B8,$B4,$B0,$B0,$AC,$A8
	dc.w	$A4,$A4,$A0,$9C,$98,$98,$94,$90
	dc.w	$90,$8C,$88,$84,$84,$80,$7C,$7C
	dc.w	$78,$74,$74,$70,$6C,$6C,$68,$64
	dc.w	$64,$60,$60,$5C,$58,$58,$54,$54
	dc.w	$50,$4C,$4C,$48,$48,$44,$44,$40
	dc.w	$40,$3C,$3C,$38,$38,$34,$34,$30
	dc.w	$30,$2C,$2C,$28,$28,$28,$24,$24
	dc.w	$20,$20,$20,$1C,$1C,$1C,$18,$18
	dc.w	$18,$14,$14,$14,$10,$10,$10,$10
	dc.w	12,12,12,12,12,8,8,8
	dc.w	8,8,8,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,4
	dc.w	4,4,4,4,4,4,4,8
	dc.w	8,8,8,8,8,12,12,12
	dc.w	12,12,$10,$10,$10,$14,$14,$14
	dc.w	$14,$18,$18,$18,$1C,$1C,$1C,$20
	dc.w	$20,$24,$24,$24,$28,$28,$2C,$2C
	dc.w	$2C,$30,$30,$34,$34,$38,$38,$3C
	dc.w	$3C,$40,$40,$44,$44,$48,$48,$4C
	dc.w	$50,$50,$54,$54,$58,$5C,$5C,$60
	dc.w	$60,$64,$68,$68,$6C,$70,$70,$74
	dc.w	$78,$78,$7C,$80,$80,$84,$88,$88
	dc.w	$8C,$90,$94,$94,$98,$9C,$9C,$A0
	dc.w	$A4,$A8,$A8,$AC,$B0,$B4,$B4,$B8
	dc.w	$BC,$C0,$C4,$C4,$C8,$CC,$D0,$D4
	dc.w	$D4,$D8,$DC,$E0,$E0,$E4,$E8,$EC
	dc.w	$F0,$F4,$F4,$F8,$FC,$100,$104,$104

sineoffset1:
	dc.w	0
sineoffset2:
	dc.w	0
stack_save:
	dc.l	0
intena_save:
	dc.w	0
dmacon_save:
	dc.w	0
scrollcount:
	dc.w	1
scrolltextptr:
	dc.l	scrolltext
scrollheight:
	dc.w	0

; Mask for blitting, 3 words wide
blitmask:
	dc.w	$FFFF,$FE00,0

; Data table with character offsets into bitmap and height
fontinfo:
	dc.w	$2DC,14
	dc.w	$2DE,10
	dc.w	$2E0,14
	dc.w	$2E2,13
	dc.w	$2E4,14
	dc.w	$2E6,14
	dc.w	$2E8,13
	dc.w	$2EA,14
	dc.w	$2EC,13
	dc.w	$2EE,14
	dc.w	$2F4,10
	dc.w	$2F0,10
	dc.w	$2F2,15
	dc.w	$2F2,15
	dc.w	$2F2,15
	dc.w	$2F6,15
	dc.w	$2F2,15
	dc.w	0,15
	dc.w	2,15
	dc.w	4,13
	dc.w	6,14
	dc.w	8,13
	dc.w	10,14
	dc.w	12,14
	dc.w	14,14
	dc.w	$10,9
	dc.w	$12,13
	dc.w	$14,14
	dc.w	$16,14
	dc.w	$18,17
	dc.w	$1A,15
	dc.w	$1C,15
	dc.w	$1E,15
	dc.w	$20,15
	dc.w	$22,16
	dc.w	$24,15
	dc.w	$26,16
	dc.w	$2D0,15
	dc.w	$2D2,14
	dc.w	$2D4,16
	dc.w	$2D6,15
	dc.w	$2D8,15
	dc.w	$2DA,15

scrollfont:
	dc.w	3,3,15,3,3,3,0,3
	dc.w	3,0,3,3,3,3,3,3
	dc.w	3,3,3,3,15,15,$3F,15
	dc.w	15,15,15,14,14,0,14,14
	dc.w	15,14,15,15,15,15,15,7
	dc.w	$3F,$3B,$E3,$3B,$3B,$3B,$3F,$38
	dc.w	$38,0,$38,$38,$3B,$3C,$3B,$3B
	dc.w	$3B,$3B,$3B,3,$E7,$E3,$383,$E3
	dc.w	$E3,$E3,$E3,$E0,$E0,0,$E0,$E0
	dc.w	$E6,$F8,$E3,$E3,$E3,$E3,$63,3
	dc.w	$387,$386,$E06,$386,$383,$383,$383,$380
	dc.w	$380,3,$3C0,$380,$38C,$3B0,$383,$383
	dc.w	$383,$383,$C3,7,$E06,$F8C,$380C,$E0C
	dc.w	$F83,$F83,$E00,$F83,$E00,14,$FFF,$E00
	dc.w	$E18,$E60,$E03,$F03,$E03,$F03,$C3,$1F
	dc.w	$3E0C,$3998,$6018,$3818,$3980,$3983,$3880,$398E
	dc.w	$3800,$2038,$3BFC,$3800,$383F,$38C3,$3803,$3B03
	dc.w	$3803,$3B03,$20C3,$73,$E618,$E1F0,$C000,$E030
	dc.w	$E180,$E180,$6180,$E1B8,$E000,$60E0,$E600,$6000
	dc.w	$E07F,$E18E,$6006,$E30E,$6006,$E30E,$60C2,$1C3
	dc.w	$8630,$C1C0,$C000,$C060,$C100,$8100,$C180,$81E0
	dc.w	$8000,$C380,$8C00,$C000,$8003,$8338,$C01C,$8338
	dc.w	$C21C,$8338,$C0C0,$706,$660,$C180,$C000,$C1C0
	dc.w	$C000,0,$C180,$380,0,$CE00,$1800,$C000
	dc.w	14,$6E0,$C070,$3E0,$C670,$7E0,$C0C0,$1C00
	dc.w	$1C0,$C300,$F800,$C700,$C000,0,$C600,$E00
	dc.w	0,$F800,$3000,$C000,$38,$F80,$C1C0,$380
	dc.w	$CDC0,$F80,$C180,$7000,$700,$CE00,$F000,$FC00
	dc.w	$C000,0,$F800,$3800,0,$E000,$6000,$E000
	dc.w	$E0,$1E00,$C700,0,$DF00,$1800,$C700,$C000
	dc.w	$1C00,$F800,0,$F000,$C000,0,$E000,$E000
	dc.w	0,0,$C000,$E000,$380,$3800,$DC00,0
	dc.w	$FC00,$3000,$DC00,0,$7000,$E000,0,0
	dc.w	$8000,0,0,$8000,0,0,$8000,0
	dc.w	$E00,$E000,$F000,0,$F000,$6000,$F000,0
	dc.w	$C000,0,0,0,0,0,0,0
	dc.w	0,0,0,0,$3800,$8000,$C000,0
	dc.w	$C000,$C000,$C000,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	$E000,0,0,0,0,$8000,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,$8000,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	3,3,3,3,3,3,3,15
	dc.w	3,3,3,3,3,3,3,3
	dc.w	$800,0,3,3,14,6,6,6
	dc.w	6,3,15,15,15,3,14,15
	dc.w	15,7,15,15,$3800,0,14,15
	dc.w	$38,$18,$18,12,12,3,$3B,$1C
	dc.w	3,3,$38,$3B,$3B,3,$3B,$3B
	dc.w	$F800,0,$38,3,$E0,$30,$30,$18
	dc.w	$18,3,$E3,$70,3,3,$E0,$E3
	dc.w	$E3,3,$E3,$63,$E000,0,$E0,3
	dc.w	$380,$C0,$C0,$30,$30,3,$393,$1C0
	dc.w	3,$183,$181,$C3,$383,3,$383,$C3
	dc.w	$8000,0,$380,3,$E00,$183,$180,$60
	dc.w	$60,3,$E66,$700,14,$18E,$187,$C3
	dc.w	$F80,$13F,$F86,$C3,0,0,$600,$63
	dc.w	$3803,$61E,$600,$3FFF,$FF,$3FFF,$399C,$1C00
	dc.w	$3FF8,$1B8,$19C,$C0,$3980,$3FF,$399C,$CE
	dc.w	0,0,$2000,$1E3,$600E,$CF0,$C00,$7FFE
	dc.w	$3FE,$FFFE,$6670,$7000,$FFE0,$C1E0,$1F0,$C0C0
	dc.w	$E180,$380,$E1F0,$C0F8,0,0,$E000,$76E
	dc.w	$C038,$3780,$3003,$300,$E00,$C000,$C9C0,$C000
	dc.w	$C000,$C380,$1C0,$C180,$C180,$F00,$C1C0,$C0E0
	dc.w	0,0,$8000,$478,$C0E0,$7C00,$7C1E,$600
	dc.w	$3800,$C000,$C700,0,$C000,$CE00,$700,$C300
	dc.w	$C700,$3B00,$C700,$C380,0,0,0,$6000
	dc.w	$C380,$E000,$F8F0,$C00,$E000,$C000,$DC00,0
	dc.w	$C000,$F800,$1C00,$CE00,$DC00,$E000,$DC00,$CE00
	dc.w	0,0,0,$C000,$CE00,0,$3780,$1800
	dc.w	$8000,$C000,$F000,0,$E000,$E000,$7000,$F800
	dc.w	$F000,$8000,$F000,$F800,0,0,0,0
	dc.w	$F800,0,$7C00,$3000,0,$C000,$C000,0
	dc.w	$8000,0,$C000,$E000,$C000,0,$C000,$E000
	dc.w	0,0,0,0,$E000,0,$E000,$6000
	dc.w	0,$C000,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,$8000,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0

lbL0034A0:
	ds.l	10

scrolltext:
	dc.b	'UNITED@FORCES@PRESENT@@@@@@@@@ARC@ED@VERSION'
	dc.b	'@1@;02@@@@@@@@@@CALL@OUR@BBS@TOUCHDOWN@FOR@T'
	dc.b	'EQUILA@AND@MANY@MORE@@@@@IF@YAR@LIKE@STAMPS@'
	dc.b	'AND@ENVELOPES@THEN@WRITE@TO@@@@@@@@PLK@038@3'
	dc.b	'38@B@@@@@@@@@@W@3320@SALZGITTER@31@@@@@@@@@@'
	dc.b	'GERMANY@@@@@@@@@@OR@TO@@@@@@@@@@PLK@023@316@'
	dc.b	'C@@@@@@@@@@W@1000@BERLIN@26@@@@@@@@@GERMANY@'
	dc.b	'@@@@@@@@@OK@AND@NOW@SOME@REGARDS@FROM@GUARDI'
	dc.b	'AN@AND@COKE@IN@NO@SPECIAL@ORDER@TO@@@@@@@@@@'
	dc.b	'LUKE@AND@CHUCK@AND@STRIDER@OF@FAIRLIGHT@@@@@'
	dc.b	'@@@@@@PAUL@OF@QUARTEX@@@@@@@@@@@LAZERBRAIN@A'
	dc.b	'ND@DR@AWESOME@OF@CRUSADERS@@@@@@@@@@@CONQI@A'
	dc.b	'ND@ANDY@AND@QUINN@OF@AGILE@@@@@@@@@@@DIE@WUN'
	dc.b	'STORFER@SAEUFER@AND@HAMSTER@AND@BYTEMASTER@A'
	dc.b	'ND@JOHN@PLAYER@AND@DARK@AND@FLYNN@AND@IRATA@'
	dc.b	'AND@DEATH@ANGEL@OF@TRISTAR@AND@RED@SECTOR@@@'
	dc.b	'@@@@@@@@JASON@AND@STRANGER@OF@ENERGY@@@@@@@@'
	dc.b	'@@@MUNSTER@AND@BLACKSTAR@AND@MIKE@AND@UCOM@O'
	dc.b	'F@SPREADPOINT@@@@@@@@@@@SLAYER@AND@REWARD@OF'
	dc.b	'@SCOOPEX@@@@@@@@@@@SAURON@@@@@@@@@@@SELIM@OF'
	dc.b	'@COMPANY@@@@@@@@@@@CARNIVURE@AND@ALFRED@OF@B'
	dc.b	'EERMACHT@@@@@@@@@@TRIX@AND@JAKE@OF@REBELS@@@'
	dc.b	'@@@@@@@@THE@PRIDE@OF@FLASH@PRODUCTION@@@@@@@'
	dc.b	'@@@@ICE@OF@VERTIGO@@@@@@@@@@@ANDY@AND@THE@OT'
	dc.b	'HER@BAYRISCH@BUAM@OF@AMIGA@INDUSTRIES@@@@@@@'
	dc.b	'@@@@ALL@WE@KNOW@IN@D@TECT@@@@@@@@@@@YANKEE@A'
	dc.b	'ND@DEVIL@OF@ADDONIC@@@@@@@@@@@ALL@WE@KNOW@IN'
	dc.b	'@CYTAX@@@@@@@@@@@LYZANXIA@OF@SILENTS@@@@@@@@'
	dc.b	'@@@THUNDERCAT@@@@@@@@@@@JBM@OF@DUAL@CREW@@@@'
	dc.b	'@@@@@@@FRED@OF@AMITECH@@@@@@@@@@@SKYLORD@AND'
	dc.b	'@TYRANT@OF@DEFCON@ONE@@@@@@@@@@@JOE@PANIC@OF'
	dc.b	'@SQUADRON@@@@@@@@@@@BUTCHER@@@@@@@@@@@ZADOS@'
	dc.b	'@@@@@@@@@@SIXX@OF@D@MOB@@@@@@@@@@@NOSFERATU@'
	dc.b	'OF@RAZOR@1911@@@@@@@@@@@STINGER@OF@CAVE@@@@@'
	dc.b	'@@@@@@MINDBLASTER@AND@SHADOWCAT@OF@WIZZCAT@@'
	dc.b	'@@@@@@@@@HUNTER@OF@NO@LIMITS@@@@@@@@@@@JAFFA'
	dc.b	'@OF@CRYSTAL@@@@@@@@@@@FLUSH@OF@PURE@METAL@CO'
	dc.b	'DERS@@@@@@@@@@@ULTIMATOR@OF@ILLUSION@@@@@@@@'
	dc.b	'@@@JACKMIX@OF@CRYPTOBURNERS@@@@@@@@@@@GRAVED'
	dc.b	'IGGER@OF@MOTION@@@@@@@@@@@SATANIC@SLAUGHTER@'
	dc.b	'AND@ANGEL@DAWN@OF@JUMP@@@@@@@@@@@AND@A@L@L@T'
	dc.b	'HE@OTHERS@@@@@@OKI@PALS@B@Y@E@@@@@@@@@@@@@@@'
	dc.b	'@@@@@@@@@@@@@@@@@@@@',0
	even

copperlist:
	dc.w	$8E		;DIWSTRT
	dc.w	$2081
	dc.w	$90		;DIWSTOP
	dc.w	$30C1
	dc.w	$92		;DDFSTRT
	dc.w	$40
	dc.w	$94		;DDFSTOP
	dc.w	$C8
	dc.w	$100		;BPLCON0
	dc.w	$6200		;6 bitplanes+COLOR
	dc.w	$102		;BPLCON1
	dc.w	0
	dc.w	$104		;BPLCON2
	dc.w	9		;PF2P0+PF1P0
	dc.w	$108		;BPL1MOD
	dc.w	-36
	dc.w	$10A		;BPL2MOD
	dc.w	-36
	dc.w	$180		;COLOR00
	dc.w	0
	dc.w	$182		;COLOR01
	dc.w	$FF
	dc.w	$184		;COLOR02
	dc.w	$F00
	dc.w	$186		;COLOR03
	dc.w	$C00
	dc.w	$188		;COLOR04
	dc.w	$900
	dc.w	$18A		;COLOR05
	dc.w	$F80
	dc.w	$18C		;COLOR06
	dc.w	$C70
	dc.w	$18E		;COLOR07
	dc.w	$960
	dc.w	$190		;cont...
	dc.w	$FF0
	dc.w	$192
	dc.w	$CC0
	dc.w	$194
	dc.w	$990
	dc.w	$196
	dc.w	$F0
	dc.w	$198
	dc.w	$C0
	dc.w	$19A
	dc.w	$90
	dc.w	$19C
	dc.w	$F8
	dc.w	$19E
	dc.w	$C7
	dc.w	$1A0
	dc.w	$96
	dc.w	$1A2
	dc.w	$FFF
	dc.w	$1A4
	dc.w	$CC
	dc.w	$1A6
	dc.w	$99
	dc.w	$1A8
	dc.w	$8F
	dc.w	$1AA
	dc.w	$7C
	dc.w	$1AC
	dc.w	$69
	dc.w	$1AE
	dc.w	15
	dc.w	$1B0
	dc.w	12
	dc.w	$1B2
	dc.w	9
	dc.w	$1B4
	dc.w	$80F
	dc.w	$1B6
	dc.w	$70C
	dc.w	$1B8
	dc.w	$609
	dc.w	$1BA
	dc.w	$F08
	dc.w	$1BC		;COLOR30
	dc.w	$C07
	dc.w	$1BE		;COLOR31
	dc.w	$906
	dc.w	$120		;SPR0PTH
cop_sprite_addr:
	dc.w	0
	dc.w	$122		;SPR0PTL
	dc.w	0
	dc.w	$124
	dc.w	0
	dc.w	$126
	dc.w	0
	dc.w	$128
	dc.w	0
	dc.w	$12A
	dc.w	0
	dc.w	$12C
	dc.w	0
	dc.w	$12E
	dc.w	0
	dc.w	$130
	dc.w	0
	dc.w	$132
	dc.w	0
	dc.w	$134
	dc.w	0
	dc.w	$136
	dc.w	0
	dc.w	$138
	dc.w	0
	dc.w	$13A
	dc.w	0
	dc.w	$13C		;SPR7PTH
	dc.w	0
	dc.w	$13E		;SPR7PTL
	dc.w	0
	dc.w	$144		;SPR0DATA
	dc.w	0
	dc.w	$146		;SPR0DATB
	dc.w	0
	dc.w	$14C		;SPR1DATA
	dc.w	0
	dc.w	$14E		;SPR1DATB
	dc.w	0
	dc.w	$154		;SPR2DATA
	dc.w	0
	dc.w	$156		;SPR2DATB
	dc.w	0
	dc.w	$15C		;SPR3DATA
	dc.w	0
	dc.w	$15E		;SPR3DATB
	dc.w	0
	dc.w	$164
	dc.w	0
	dc.w	$166
	dc.w	0
	dc.w	$16C
	dc.w	0
	dc.w	$16E
	dc.w	0
	dc.w	$174
	dc.w	0
	dc.w	$176
	dc.w	0
	dc.w	$17C		;SPR7DATA
	dc.w	0
	dc.w	$17E		;SPR7DATB
	dc.w	0
	dc.w	$E0		;BPL1PTH
	dc.w	7
	dc.w	$E2		;BPL1PTL
	dc.w	0
	dc.w	$E4		;BPL2PTH
	dc.w	7
	dc.w	$E6		;BPL2PTL
	dc.w	$24
	dc.w	$E8		;BPL3PTH
	dc.w	7
	dc.w	$EA		;BPL3PTL
	dc.w	$48
	dc.w	$EC		;BPL4PTH
	dc.w	7
	dc.w	$EE		;BPL4PTL
	dc.w	$6C
	dc.w	$F0		;BPL5PTH
	dc.w	7
	dc.w	$F2		;BPL5PTL
	dc.w	$90
	dc.w	$F4		;BPL6PTH
	dc.w	7
	dc.w	$F6		;BPL6PTL
	dc.w	$B4
cop_spritepos:
	ds.w	272*6
	dc.w	$FFFF,$FFFE

mt_init:
	movem.l	d0-d2/a0-a2,-(sp)
	lea	mt_module,a0
	lea	$3B8(a0),a1
	moveq	#$7F,d0
	moveq	#0,d2
	moveq	#0,d1
lbC004A42:
	move.b	(a1)+,d1
	cmp.b	d2,d1
	ble.s	lbC004A4A
	move.l	d1,d2
lbC004A4A:
	dbra	d0,lbC004A42
	addq.b	#1,d2
	asl.l	#8,d2
	asl.l	#2,d2
	lea	4(a1,d2.l),a2
	lea	lbL0050AE(pc),a1
	add.w	#$2A,a0
	moveq	#$1E,d0
lbC004A62:
	clr.l	(a2)
	move.l	a2,(a1)+
	moveq	#0,d1
	move.w	(a0),d1
	asl.l	#1,d1
	add.l	d1,a2
	add.l	#$1E,a0
	dbra	d0,lbC004A62
	or.b	#2,$BFE001
	move.b	#6,lbB0050A6
	moveq	#0,d0
	lea	$DFF000,a0
	move.w	d0,$A8(a0)
	move.w	d0,$B8(a0)
	move.w	d0,$C8(a0)
	move.w	d0,$D8(a0)
	clr.b	lbB0050AA
	clr.b	lbB0050A7
	clr.w	lbW0050A8
	movem.l	(sp)+,d0-d2/a0-a2
	rts

mt_off:
	clr.w	$DFF0A8
	clr.w	$DFF0B8
	clr.w	$DFF0C8
	clr.w	$DFF0D8
	move.w	#15,$DFF096
	rts

mt_music:
	movem.l	d0-d3/a0-a5,-(sp)
	lea	mt_module,a0
	addq.b	#1,lbB0050A7
	move.b	lbB0050A7(pc),d0
	cmp.b	lbB0050A6(pc),d0
	blt	lbC004C20
	clr.b	lbB0050A7
	lea	mt_module,a0
	lea	12(a0),a3
	lea	$3B8(a0),a2
	lea	$43C(a0),a0
	moveq	#0,d0
	moveq	#0,d1
	move.b	lbB0050AA(pc),d0
	move.b	(a2,d0.w),d1
	lsl.w	#8,d1
	lsl.w	#2,d1
	add.w	lbW0050A8(pc),d1
	clr.w	lbW0050AC
	lea	$DFF0A0,a5
	lea	lbL00512A(pc),a4
	bsr	lbC004C9A
	addq.l	#4,d1
	lea	$DFF0B0,a5
	lea	lbL005146(pc),a4
	bsr	lbC004C9A
	addq.l	#4,d1
	lea	$DFF0C0,a5
	lea	lbL005162(pc),a4
	bsr	lbC004C9A
	addq.l	#4,d1
	lea	$DFF0D0,a5
	lea	lbL00517E(pc),a4
	bsr	lbC004C9A
	move.w	lbW0050AC(pc),d0
	beq.s	lbC004B7E
	bsr	lbC004C04
	or.w	#$8000,d0
	move.w	d0,$DFF096
	bsr	lbC004C04
lbC004B7E:
	lea	lbL00512A(pc),a4
	lea	$DFF000,a3
	move.l	10(a4),$A0(a3)
	move.w	14(a4),$A4(a3)
	move.l	$26(a4),$B0(a3)
	move.w	$2A(a4),$B4(a3)
	move.l	$42(a4),$C0(a3)
	move.w	$46(a4),$C4(a3)
	move.l	$5E(a4),$D0(a3)
	move.w	$62(a4),$D4(a3)
	add.w	#$10,lbW0050A8
	cmp.w	#$400,lbW0050A8
	bne.s	lbC004BF6
lbC004BCA:
	clr.w	lbW0050A8
	clr.b	lbB0050AB
	addq.b	#1,lbB0050AA
	and.b	#$7F,lbB0050AA
	move.b	-2(a2),d0
	cmp.b	lbB0050AA(pc),d0
	bne.s	lbC004BF6
	move.b	-1(a2),lbB0050AA
lbC004BF6:
	tst.b	lbB0050AB
	bne.s	lbC004BCA
	movem.l	(sp)+,d0-d3/a0-a5
	rts

lbC004C04:
	moveq	#3,d3
lbC004C06:
	move.b	$DFF006,d2
lbC004C0C:
	cmp.b	$DFF006,d2
	beq.s	lbC004C0C
	dbra	d3,lbC004C06
	moveq	#8,d2
lbC004C1A:
	dbra	d2,lbC004C1A
	rts

lbC004C20:
	lea	lbL00512A(pc),a4
	lea	$DFF0A0,a5
	bsr	lbC004EE0
	lea	lbL005146(pc),a4
	lea	$DFF0B0,a5
	bsr	lbC004EE0
	lea	lbL005162(pc),a4
	lea	$DFF0C0,a5
	bsr	lbC004EE0
	lea	lbL00517E(pc),a4
	lea	$DFF0D0,a5
	bsr	lbC004EE0
	bra.s	lbC004BF6

lbW004C5A:
	dc.w	0,$1E,$3C,$5A,$78,$96,$B4,$D2
	dc.w	$F0,$10E,$12C,$14A,$168,$186,$1A4,$1C2
	dc.w	$1E0,$1FE,$21C,$23A,$258,$276,$294,$2B2
	dc.w	$2D0,$2EE,$30C,$32A,$348,$366,$384,$3A2

lbC004C9A:
	move.l	(a0,d1.l),(a4)
	moveq	#0,d2
	move.b	2(a4),d2
	lsr.b	#4,d2
	move.b	(a4),d0
	and.b	#$F0,d0
	or.b	d0,d2
	beq.s	lbC004D0C
	lea	lbB0050AA(pc),a1
	asl.w	#2,d2
	move.l	(a1,d2.l),4(a4)
	lsr.w	#1,d2
	move.w	lbW004C5A(pc,d2.w),d2
	move.w	(a3,d2.w),8(a4)
	move.w	2(a3,d2.w),$12(a4)
	moveq	#0,d3
	move.w	4(a3,d2.w),d3
	tst.w	d3
	beq.s	lbC004CF2
	move.l	4(a4),d0
	asl.w	#1,d3
	add.l	d3,d0
	move.l	d0,10(a4)
	move.w	4(a3,d2.w),d0
	add.w	6(a3,d2.w),d0
	move.w	d0,8(a4)
	bra.s	lbC004CFC

lbC004CF2:
	move.l	4(a4),d0
	add.l	d3,d0
	move.l	d0,10(a4)
lbC004CFC:
	move.w	6(a3,d2.w),14(a4)
	moveq	#0,d0
	move.b	$13(a4),d0
	move.w	d0,8(a5)
lbC004D0C:
	move.w	(a4),d0
	and.w	#$FFF,d0
	beq	lbC004FC0
	tst.w	8(a4)
	beq.s	lbC004D6A
	tst.b	$12(a4)
	bne.s	lbC004D6A
	move.b	2(a4),d0
	and.b	#15,d0
	cmp.b	#5,d0
	beq.s	lbC004D76
	cmp.b	#3,d0
	beq.s	lbC004D76
	move.w	(a4),$10(a4)
	and.w	#$FFF,$10(a4)
	move.w	$1A(a4),$DFF096
	clr.b	$19(a4)
	move.l	4(a4),(a5)
	move.w	8(a4),4(a5)
	move.w	$10(a4),6(a5)
	move.w	$1A(a4),d0
	or.w	d0,lbW0050AC
	bra	lbC004FC0

lbC004D6A:
	move.w	$1A(a4),$DFF096
	bra	lbC004FC0

lbC004D76:
	move.w	(a4),d2
	and.w	#$FFF,d2
	move.w	d2,$16(a4)
	move.w	$10(a4),d0
	clr.b	$14(a4)
	cmp.w	d0,d2
	beq.s	lbC004D9A
	bge	lbC004FC0
	move.b	#1,$14(a4)
	bra	lbC004FC0

lbC004D9A:
	clr.w	$16(a4)
	rts

lbC004DA0:
	move.b	3(a4),d0
	beq.s	lbC004DAE
	move.b	d0,$15(a4)
	clr.b	3(a4)
lbC004DAE:
	tst.w	$16(a4)
	beq.s	lbC004DDE
	moveq	#0,d0
	move.b	$15(a4),d0
	tst.b	$14(a4)
	bne.s	lbC004DE0
	add.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	bgt.s	lbC004DD8
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
lbC004DD8:
	move.w	$10(a4),6(a5)
lbC004DDE:
	rts

lbC004DE0:
	sub.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	blt.s	lbC004DD8
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
	move.w	$10(a4),6(a5)
	rts

lbB004E00:
	dc.b	0,$18,$31,$4A,$61,$78,$8D,$A1
	dc.b	$B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
	dc.b	$FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
	dc.b	$B4,$A1,$8D,$78,$61,$4A,$31,$18

lbC004E20:
	move.b	3(a4),d0
	beq.s	lbC004E2A
	move.b	d0,$18(a4)
lbC004E2A:
	move.b	$19(a4),d0
	lsr.w	#2,d0
	and.w	#$1F,d0
	moveq	#0,d2
	move.b	lbB004E00(pc,d0.w),d2
	move.b	$18(a4),d0
	and.w	#15,d0
	mulu	d0,d2
	lsr.w	#7,d2
	move.w	$10(a4),d0
	tst.b	$19(a4)
	bmi.s	lbC004E54
	add.w	d2,d0
	bra.s	lbC004E56

lbC004E54:
	sub.w	d2,d0
lbC004E56:
	move.w	d0,6(a5)
	move.b	$18(a4),d0
	lsr.w	#2,d0
	and.w	#$3C,d0
	add.b	d0,$19(a4)
	rts

lbB004E6A:
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1,2
	dc.b	0,1

lbC004E8A:
	moveq	#0,d0
	move.b	lbB0050A7(pc),d0
	move.b	lbB004E6A(pc,d0.w),d0
	beq.s	lbC004EC8
	cmp.b	#2,d0
	beq.s	lbC004EA6
	moveq	#0,d0
	move.b	3(a4),d0
	lsr.b	#4,d0
	bra.s	lbC004EB0

lbC004EA6:
	moveq	#0,d0
	move.b	3(a4),d0
	and.b	#15,d0
lbC004EB0:
	asl.w	#1,d0
	move.w	$10(a4),d1
	and.w	#$FFF,d1
	lea	lbW00505C(pc),a0
	moveq	#$24,d2
lbC004EC0:
	cmp.w	(a0)+,d1
	bge.s	lbC004ED0
	dbra	d2,lbC004EC0
lbC004EC8:
	move.w	$10(a4),6(a5)
	rts

lbC004ED0:
	move.w	-2(a0,d0.w),6(a5)
	rts

lbC004ED8:
	move.w	$10(a4),6(a5)
	rts

lbC004EE0:
	move.w	2(a4),d0
	and.w	#$FFF,d0
	beq.s	lbC004ED8
	move.b	2(a4),d0
	and.b	#15,d0
	tst.b	d0
	beq.s	lbC004E8A
	cmp.b	#1,d0
	beq.s	lbC004F2C
	cmp.b	#2,d0
	beq.s	lbC004F4E
	cmp.b	#3,d0
	beq	lbC004DA0
	cmp.b	#4,d0
	beq	lbC004E20
	cmp.b	#5,d0
	beq.s	lbC004F76
	cmp.b	#6,d0
	beq.s	lbC004F70
	move.w	$10(a4),6(a5)
	cmp.b	#10,d0
	beq.s	lbC004F7A
	rts

lbC004F2C:
	moveq	#0,d0
	move.b	3(a4),d0
	sub.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$71,d0
	bpl.s	lbC004F46
	move.w	#$71,$10(a4)
lbC004F46:
	move.w	$10(a4),6(a5)
	rts

lbC004F4E:
	moveq	#0,d0
	move.b	3(a4),d0
	add.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$358,d0
	bmi.s	lbC004F68
	move.w	#$358,$10(a4)
lbC004F68:
	move.w	$10(a4),6(a5)
	rts

lbC004F70:
	bsr	lbC004E2A
	bra.s	lbC004F7A

lbC004F76:
	bsr	lbC004DAE
lbC004F7A:
	moveq	#0,d0
	move.b	3(a4),d0
	lsr.b	#4,d0
	beq.s	lbC004FA2
	add.b	d0,$13(a4)
	cmp.b	#$40,$13(a4)
	bmi.s	lbC004F96
	move.b	#$40,$13(a4)
lbC004F96:
	moveq	#0,d0
	move.b	$13(a4),d0
	move.w	d0,8(a5)
	rts

lbC004FA2:
	move.b	3(a4),d0
	and.b	#15,d0
	sub.b	d0,$13(a4)
	bpl.s	lbC004FB4
	clr.b	$13(a4)
lbC004FB4:
	moveq	#0,d0
	move.b	$13(a4),d0
	move.w	d0,8(a5)
	rts

lbC004FC0:
	move.b	2(a4),d0
	and.b	#15,d0
	cmp.b	#14,d0
	beq.s	lbC004FE8
	cmp.b	#13,d0
	beq.s	lbC005002
	cmp.b	#11,d0
	beq.s	lbC00500C
	cmp.b	#12,d0
	beq.s	lbC005022
	cmp.b	#15,d0
	beq.s	lbC005040
	rts

lbC004FE8:
	move.b	3(a4),d0
	and.b	#1,d0
	asl.b	#1,d0
	and.b	#$FD,$BFE001
	or.b	d0,$BFE001
	rts

lbC005002:
	move.b	#1,lbB0050AB
	rts

lbC00500C:
	move.b	#1,lbB0050AB
	move.b	3(a4),d0
	subq.b	#1,d0
	move.b	d0,lbB0050AA
	rts

lbC005022:
	cmp.b	#$40,3(a4)
	bls.s	lbC005030
	move.b	#$40,3(a4)
lbC005030:
	moveq	#0,d0
	move.b	3(a4),d0
	move.b	d0,$13(a4)
	move.w	d0,8(a5)
	rts

lbC005040:
	moveq	#0,d0
	move.b	3(a4),d0
	cmp.b	#$1F,d0
	bls.s	lbC00504E
	moveq	#$1F,d0
lbC00504E:
	tst.w	d0
	bne.s	lbC005054
	moveq	#1,d0
lbC005054:
	move.b	d0,lbB0050A6
	rts

lbW00505C:
	dc.w	$358,$328,$2FA,$2D0,$2A6,$280,$25C,$23A
	dc.w	$21A,$1FC,$1E0,$1C5,$1AC,$194,$17D,$168
	dc.w	$153,$140,$12E,$11D,$10D,$FE,$F0,$E2
	dc.w	$D6,$CA,$BE,$B4,$AA,$A0,$97,$8F
	dc.w	$87,$7F,$78,$71,0

lbB0050A6:
	dc.b	6
lbB0050A7:
	dc.b	0
lbW0050A8:
	dc.w	0
lbB0050AA:
	dc.b	0
lbB0050AB:
	dc.b	0
lbW0050AC:
	dc.w	0
lbL0050AE:
	ds.l	31

lbL00512A:
	dc.l	0,0,0,0,0,0,1
lbL005146:
	dc.l	0,0,0,0,0,0,2
lbL005162:
	dc.l	0,0,0,0,0,0,4
lbL00517E:
	dc.l	0,0,0,0,0,0,8

mt_module:
	incbin	"newtech.mod"
	ds.l	1			;safety long, gets cleared by ProTracker replay
	even

sprite_buffer:
	ds.l	294
