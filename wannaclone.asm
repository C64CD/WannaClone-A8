;
; WANNACLONE (ATARI 8-BIT VERSION)
;

; Code by TMR
; Graphics by Jose and TMR
; Music by Miker


; A simple example of EOR-based "encryption" written as a demonstration
; for 2600problems on the Atar Age forums.
; Coded for C64CrapDebunk.Wordpress.com

; Notes: this source is formatted for the Xasm cross assembler from
; https://github.com/pfusik/xasm
; Compression is handled with Exomizer 2 which can be downloaded at
; http://hem.bredband.net/magli143/exo/

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Memory Map
; $3400 - $4dff		music
; $4e00 - $4fff		display list
; $5000 - $57ff		program code/data
; $5800 - $5fff		player/missile data
; $6000 - $7fff		bitmapped picture
; $8000 - $83ff		colour tables
; $8400 -		scrolling message


; Pull in the binary data
		org $3400
		opt h-
		ins "binary\jeopardy.xex"
		opt h+

		org $6100
		ins "binary\bitmap.raw"

		org $8400
scroll_text	ins "binary\scroll_text.raw"


; This is the initial value of the seed - if it's changed, the
; BlitzMax code's equivalent SeedInit needs to be updated
; accordingly!
seed_init	equ $a8


; Atari 8-bit register declarations
atract		equ $4d

; Shadow registers
vdslst		equ $0200
sdmctl		equ $022f
sdlstl		equ $0230
sdlsth		equ $0231
gprior		equ $026f

pcolr0		equ $02c0
pcolr1		equ $02c1
pcolr2		equ $02c2
pcolr3		equ $02c3
color0		equ $02c4
color1		equ $02c5
color2		equ $02c6
color3		equ $02c7
color4		equ $02c8
chbas		equ $02f4

; Registers
hposp0		equ $d000
hposp1		equ $d001
hposp2		equ $d002
hposp3		equ $d003
hposm0		equ $d004
hposm1		equ $d005
hposm2		equ $d006
hposm3		equ $d007
sizep0		equ $d008
sizep1		equ $d009
sizep2		equ $d00a
sizep3		equ $d00b
sizem		equ $d00c

colpm0		equ $d012
colpm1		equ $d013
colpm2		equ $d014
colpm3		equ $d015
colpf0		equ $d016
colpf1		equ $d017
colpf2		equ $d018
colpf3		equ $d019
colbk		equ $d01a
prior		equ $d01b
vdelay		equ $d01c
gractl		equ $d01d

dmactl		equ $d400
hscrol		equ $d404
vscrol		equ $d405
pmbase		equ $d407
chbase		equ $d409
wsync		equ $d40a
nmien		equ $d40e


; Label assignments
scroll_pos	equ $fe		; two bytes used

seed		equ $0600
xor_count	equ $0601

scroll_x	equ $06bf
scroll_line	equ $06c0

music		equ $4000

player_ram	equ $5800


; Display list
		org $4e00
dlist		dta $70,$70,$10+$80,$20

; First half of the bitmapped image
		dta $4f,$00,$61
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

; Second half of the bitmapped image
		dta $4f,$00,$70
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

; Scrolling message area
		dta $52
		dta <scroll_line,>scroll_line

; End of the screen, loop back to the start
		dta $41,<dlist,>dlist


; Entry point for the code
		run $5000
		org $5000


; Set up the music driver
		lda #$00
		ldx #$00
		ldy #$40
		jsr $3400

; Set up vertical blank interrupt
		lda #$06
		ldx #>vblank
		ldy #<vblank
		jsr $e45c

; Set up display list / DLI
dl_init		lda #<dlist
		sta sdlstl
		lda #>dlist
		sta sdlsth

		lda #<dli
		sta vdslst+$00
		lda #>dli
		sta vdslst+$01
		lda #$c0
		sta nmien

; Set up shadow regisers for the playfield colours
		lda #$00
		sta color4
		lda #$fe
		sta color2
		lda #$04
		sta color1

; initialise the player/missile graphics
		lda #>player_ram
		sta pmbase

		lda #$3e
		sta sdmctl
		lda #$03
		sta gractl		; enable player/missile DMA
		lda #$00
		sta gprior

; Set player/missile horizontal positions
		lda #$34
		sta hposp0
		lda #$54
		sta hposm0
		lda #$54
		sta hposp1
		lda #$86
		sta hposp2

; Set player/missile colours (where needed)
		lda #$34
		sta pcolr2

; Set player/missile expansion
		lda #$03
		sta sizep0
		sta sizep2
		sta sizem

; Clear player/missile data
		ldx #$00
		txa
player_clear	sta player_ram+$300,x
		sta player_ram+$400,x
		sta player_ram+$500,x
		sta player_ram+$600,x
		sta player_ram+$700,x
		inx
		bne player_clear

; Build player/missile data (one byte expands to eight)
		ldx #$00
		ldy #$1c
player_build	lda missile_data,x
		sta player_ram+$301,y
		sta player_ram+$302,y
		sta player_ram+$303,y
		sta player_ram+$304,y
		sta player_ram+$305,y
		sta player_ram+$306,y
		sta player_ram+$307,y
		sta player_ram+$308,y

		lda player_0_data,x
		sta player_ram+$401,y
		sta player_ram+$402,y
		sta player_ram+$403,y
		sta player_ram+$404,y
		sta player_ram+$405,y
		sta player_ram+$406,y
		sta player_ram+$407,y
		sta player_ram+$408,y

		lda player_1_data,x
		sta player_ram+$501,y
		sta player_ram+$502,y
		sta player_ram+$503,y
		sta player_ram+$504,y
		sta player_ram+$505,y
		sta player_ram+$506,y
		sta player_ram+$507,y
		sta player_ram+$508,y

		lda player_2_data,x
		sta player_ram+$601,y
		sta player_ram+$602,y
		sta player_ram+$603,y
		sta player_ram+$604,y
		sta player_ram+$605,y
		sta player_ram+$606,y
		sta player_ram+$607,y
		sta player_ram+$608,y

		tya
		clc
		adc #$08
		tay

		inx
		cpx #$18
		bne player_build

; Reset the scrolling message
		jsr scroll_reset

		ldx #$00
		lda #$80
scroll_clear	sta scroll_line,x
		inx
		cpx #$30
		bne scroll_clear

; Infinite loop - all of the code is executing on the interrupt
		jmp *


; Vertical blank interrupt - suppress attract mode timer
vblank		lda #$00
		sta atract

; Move scrolling message
		ldx scroll_x
		inx
		cpx #$04
		bne scr_xb

; Move the text line
		ldx #$00
scroll_mover	lda scroll_line+$01,x
		sta scroll_line+$00,x
		inx
		cpx #$2b
		bne scroll_mover

; Decode and copy a new character to the scroller
		ldy #$00
scroll_mread	lda (scroll_pos),y
		tax
		sec
		sbc seed
		ldy xor_count
		eor music,y
		and #$7f
		cmp #$7f
		bne scroll_okay

		jsr scroll_reset
		jmp scroll_mread-$02

scroll_okay	ora #$80
		sta scroll_line+$2b
		txa
		clc
		adc seed
		sta seed

		inc scroll_pos+$00
		bne *+$04
		inc scroll_pos+$01

		inc xor_count

		ldx #$00
scr_xb		stx scroll_x

; Set up the hardware scroll register for the message
		txa
		eor #$03
		sta hscrol

; Exit the interrupt
		jmp $e45f


		org $5200
; Display list interrupt
dli		pha
		txa
		pha
		tya
		pha

; Wait a couple of scanlines to get synchronised
		sta wsync
		sta wsync
		sta wsync

		ldx #$11
		dex
		bne *-$01
		bit $ea

; First colour splitter for the picture
		ldx #$00
splitter_loop_1	lda #$fe
		ldy split_cols_pm0,x
		sty colpm0
		sta colpf2
		ldy split_cols_pm1,x
		sty colpm1
		nop
		nop
		nop
		bit $ea
		lda split_cols_pf2,x
		sta colpf2
		bit $ea
		nop
		nop
		nop
		nop
		nop
		inx
		cpx #$5e
		bne splitter_loop_1

; There's a few less cycles for a couple of scanlines, so this bit
; times around them.
		lda split_cols_pm0,x
		sta colpm0
		ldy split_cols_pm1,x
		sty colpm1
		lda #$fe
		sta colpf2
		nop
		nop
		nop
		nop
		nop
		lda split_cols_pf2,x
		sta colpf2
		bit $ea
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		inx

		lda split_cols_pm0,x
		sta colpm0
		ldy split_cols_pm1,x
		sty colpm1
		lda #$fe
		sta colpf2
		nop
		nop
		nop
		nop
		nop
		lda split_cols_pf2,x
		sta colpf2
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		inx

; Second colour splitter for the picture
splitter_loop_2	lda #$fe
		ldy split_cols_pm0,x
		sty colpm0
		sta colpf2
		ldy split_cols_pm1,x
		sty colpm1
		nop
		nop
		nop
		bit $ea
		lda split_cols_pf2,x
		sta colpf2
		bit $ea
		nop
		nop
		nop
		nop
		nop
		inx
		cpx #$c0
		bne splitter_loop_2

		nop
		nop
		lda #$fe
		sta colpf2

; Play the music
		jsr $3403

; Exit the interrupt
		pla
		tay
		pla
		tax
		pla
		rti

; Subroutine to reset the scrolling message
scroll_reset	lda #<scroll_text
		sta scroll_pos+$00
		lda #>scroll_text
		sta scroll_pos+$01

		lda #seed_init
		sta seed
		lda #$00
		sta xor_count
		rts


; Player/missile data
missile_data	dta %00000000

		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000

		dta %00000010
		dta %00000010
		dta %00000010
		dta %00000000
		dta %00000010
		dta %00000000

		dta %00000000
		dta %00000000

		dta %00000010
		dta %00000010
		dta %00000010
		dta %00000000
		dta %00000010
		dta %00000000

		dta %00000000

player_0_data	dta %00000000

		dta %00111111
		dta %00111111
		dta %00111111
		dta %00111111
		dta %00111111
		dta %00111111

		dta %00000000
		dta %00000000

		dta %11111111
		dta %11111111
		dta %11111111
		dta %00000000
		dta %11111111
		dta %01111111

		dta %00000000
		dta %00000000

		dta %11111111
		dta %11111111
		dta %11111111
		dta %00000000
		dta %11111111
		dta %01111111

		dta %00000000

player_1_data	dta %00000000

		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000

		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111

		dta %00000000
		dta %00000000

		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111
		dta %00001111

		dta %00000000

player_2_data	dta %00000000

		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000

		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %00000000
		dta %11111110

		dta %00000000

; Plauer/missile colour tables
		org $5800
split_cols_pm0	dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa
		dta $fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa
		dta $fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $00,$00,$00,$00,$00,$00,$00,$00

		org $5900
split_cols_pm1	dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $a8,$a8,$a8,$a8,$a8,$38,$a8,$a8
		dta $a8,$a8,$a8,$38,$a8,$a8,$a8,$a8
		dta $38,$a8,$a8,$a8,$38,$a8,$a8,$38
		dta $a8,$38,$38,$a8,$38,$38,$38,$a8
		dta $38,$38,$38,$38,$a8,$38,$38,$38
		dta $38,$38,$a8,$38,$38,$38,$38,$38

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $a8,$a8,$a8,$a8,$a8,$38,$a8,$a8
		dta $a8,$a8,$a8,$38,$a8,$a8,$a8,$a8
		dta $38,$a8,$a8,$a8,$38,$a8,$a8,$38
		dta $a8,$38,$38,$a8,$38,$38,$38,$a8
		dta $38,$38,$38,$38,$a8,$38,$38,$38
		dta $38,$38,$a8,$38,$38,$38,$38,$38

		dta $00,$00,$00,$00,$00,$00,$00,$00

		org $5a00
split_cols_pf2	dta $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
		dta $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
		dta $04,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$04

