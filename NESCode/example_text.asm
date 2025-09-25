; CH05 - Programming Games for NES
; Base NES game shell demo

;*****************************************************************
; Define NES control register values
;*****************************************************************

; Define PPU Registers
	.DEF PPU_CONTROL,			$2000 ; PPU Control Register 1 (Write)
	.DEF PPU_MASK,				$2001 ; PPU Control Register 2 (Write)
	.DEF PPU_STATUS,			$2002; PPU Status Register (Read)
	.DEF PPU_SPRRAM_ADDRESS,	$2003 ; PPU SPR-RAM Address Register (Write)
	.DEF PPU_SPRRAM_IO,			$2004 ; PPU SPR-RAM I/O Register (Write)
	.DEF PPU_VRAM_ADDRESS1,		$2005 ; PPU VRAM Address Register 1 (Write)
	.DEF PPU_VRAM_ADDRESS2,		$2006 ; PPU VRAM Address Register 2 (Write)
	.DEF PPU_VRAM_IO,			$2007 ; VRAM I/O Register (Read/Write)
	.DEF SPRITE_DMA,			$4014 ; Sprite DMA Register
	.DEF JOYPAD2,				$4016 ; Sprite DMA Register

; Define APU Registers
	.DEF APU_DM_CONTROL,		$4010 ; APU Delta Modulation Control Register (Write)
	.DEF APU_CLOCK,				$4015 ; APU Sound/Vertical Clock Signal Register (Read/Write)

;*****************************************************************
; Define NES cartridge Header
;*****************************************************************

; .segment "HEADER"
	.DEF INES_MAPPER,  0 ; 0 = NROM
	.DEF INES_MIRROR,  0 ; 0 = horizontal mirroring, 1 = vertical mirroring
	.DEF INES_SRAM,    0 ; 1 = battery backed SRAM at $6000-7FFF

	.ORG $BFF0
	.BASE 0
	.db "NES", $1A ; ID 
	.db $01 ; 16k PRG bank count
	.db $01 ; 8k CHR bank count
	.db INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
	.db (INES_MAPPER & @11110000)
	.db $0, $0, $0, $0, $0, $0, $0, $0 ; padding


;*****************************************************************
; 6502 Zero Page Memory (256 bytes)
;*****************************************************************

; .segment "ZEROPAGE"

.ENUM 0
	nmi_ready,		1 ; set to 1 to push a PPU frame update, 
						;        2 to turn rendering off next NMI
	gamepad,		1 ; stores the current gamepad values

	d_x,			1 ; x velocity of ball
	d_y,			1 ; y velocity of ball
.ENDE


;*****************************************************************
; Sprite OAM Data area - copied to VRAM in NMI routine
;*****************************************************************

; .segment "OAM"
	.DEF oam,	$200	; sprite OAM data

;*****************************************************************
; Remainder of normal RAM area
;*****************************************************************

; .segment "BSS"
	.DEF palette, $300 ; current palette buffer

;*****************************************************************
; Some useful functions
;*****************************************************************

; .segment "CODE"
; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
ppu_update
	lda #1
	sta nmi_ready
-	lda nmi_ready
	bne -
	rts

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_VRAM_IO)
ppu_off
	lda #2
	sta nmi_ready
-	lda nmi_ready
	bne -
	RTS

;*****************************************************************
; Main application entry point for starup/reset
;*****************************************************************

; .segment "CODE"
reset
	sei			; mask interrupts
	lda #0
	sta PPU_CONTROL	; disable NMI
	sta PPU_MASK	; disable rendering
	sta APU_DM_CONTROL	; disable DMC IRQ
	lda #$40
	STA JOYPAD2		; disable APU frame IRQ

	cld			; disable decimal mode
	ldx #$FF
	txs			; initialise stack

	; wait for first vBlank
	bit PPU_STATUS
wait_vblank:
	bit PPU_STATUS
	bpl wait_vblank

	; clear all RAM to 0
	lda #0
	ldx #0
clear_ram:
	sta $0000,x
	sta $0100,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne clear_ram

	; place all sprites offscreen at Y=255
	lda #255
	ldx #0
clear_oam:
	sta oam,x
	inx
	inx
	inx
	inx
	bne clear_oam

; wait for second vBlank
wait_vblank2:
	bit PPU_STATUS
	bpl wait_vblank2
	
	; NES is initialized and ready to begin
	; - enable the NMI for graphical updates and jump to our main program
	lda #@10001000
	sta PPU_CONTROL
	jmp main
.endproc

;*****************************************************************
; NMI Routine - called every vBlank
;*****************************************************************

; .segment "CODE"
nmi
	; save registers
	pha
	txa
	pha
	tya
	pha

	lda nmi_ready
	bne + ; nmi_ready == 0 not ready to update PPU
	jmp ppu_update_end
+	cmp #2 ; nmi_ready == 2 turns rendering off
	bne cont_render
	lda #@00000000
	sta PPU_MASK
	ldx #0
	stx nmi_ready
	jmp ppu_update_end
cont_render

	; transfer sprite OAM data using DMA
	ldx #0
	stx PPU_SPRRAM_ADDRESS
	lda #>oam
	sta SPRITE_DMA

	; transfer current palette to PPU
	lda #@10001000 ; set horizontal nametable increment
	sta PPU_CONTROL 
	lda PPU_STATUS
	lda #$3F ; set PPU address to $3F00
	sta PPU_VRAM_ADDRESS2
	stx PPU_VRAM_ADDRESS2
	ldx #0 ; transfer the 32 bytes to VRAM
loop:
	lda palette,x
	sta PPU_VRAM_IO
	inx
	cpx #32
	bcc loop

	; enable rendering
	lda #@00011110
	sta PPU_MASK
	; flag PPU update complete
	ldx #0
	stx nmi_ready
ppu_update_end:

	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	rti

;*****************************************************************
; IRQ Clock Interrupt Routine
;*****************************************************************

; .segment "CODE"
irq
	rti

;*****************************************************************
; Main application logic section includes the game loop
;*****************************************************************
;  .segment "CODE"
main
	; main application - rendering is currently off

	; initialize palette table
	ldx #0
paletteloop:
	lda default_palette,x
	sta palette,x
	inx
	cpx #32
	bcc paletteloop

	; clear 1st name table
	jsr clear_nametable

	; draw some text on the screen
	lda PPU_STATUS ; reset address latch
	lda #$20 ; set PPU address to $208A (Row = 4, Column = 10)
	sta PPU_VRAM_ADDRESS2
	lda #$8A
	sta PPU_VRAM_ADDRESS2

	ldx #0
textloop
	lda welcome_txt,x
	sta PPU_VRAM_IO
	inx
	cmp #0
	beq +
	jmp textloop
+

 	; get the screen to render
 	jsr ppu_update

mainloop:
	; skip reading controls if and change has not been drawn
	lda nmi_ready
	cmp #0
	bne mainloop
	; read the gamepad


	; ensure our changes are rendered
	lda #1
	sta nmi_ready
	jmp mainloop

; .segment "CODE"
clear_nametable
	lda PPU_STATUS ; reset address latch
	lda #$20 ; set PPU address to $2000
	sta PPU_VRAM_ADDRESS2
	lda #$00
	sta PPU_VRAM_ADDRESS2

	; empty nametable
	lda #0
	ldy #30 ; clear 30 rows
--	ldx #32 ; 32 columns
-	sta PPU_VRAM_IO
	dex
	bne -
	dey
	bne --

	; empty attribute table
	ldx #64 ; attribute table is 64 bytes
-	sta PPU_VRAM_IO
	dex
	bne -
	rts

;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************

;*****************************************************************
; Our default palette table 16 entries for tiles and 16 entries for sprites
;*****************************************************************

; .segment "RODATA"
default_palette:
	.DB $0F,$15,$26,$37 ; bg0 purple/pink
	.DB $0F,$09,$19,$29 ; bg1 green
	.DB $0F,$01,$11,$21 ; bg2 blue
	.DB $0F,$00,$10,$30 ; bg3 greyscale
	.DB $0F,$18,$28,$38 ; sp0 yellow
	.DB $0F,$14,$24,$34 ; sp1 purple
	.DB $0F,$1B,$2B,$3B ; sp2 teal
	.DB $0F,$12,$22,$32 ; sp3 marine

welcome_txt:
	.DB "WELCOMEHOME", 0
	
;*****************************************************************
; Define NES interrupt vectors
;*****************************************************************

; .segment "VECTORS"
	.ORG $FFFA
	.DW nmi
	.DW reset
	.DW irq

;*****************************************************************
; Import both the background and sprite character sets
;*****************************************************************

; .segment "TILES"
	.incbin "example.chr"
