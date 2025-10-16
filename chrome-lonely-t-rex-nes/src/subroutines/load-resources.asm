LOAD_PALETTES:
	; read PPU status to reset the high/low latch
	LDA PPU_STATUS

	LDA #>(PAL_RAM_IDX)
	STA PPU_ADDR
	LDA #<(PAL_RAM_IDX)
	STA PPU_ADDR

	LDX #$00
.Loop:
	LDA BIN_PALETTES,x
	STA PPU_DATA
	INX
	CPX #$20
	BNE .Loop
	RTS


LOAD_BACKGROUNDS:
	; read PPU status to reset the high/low latch
	LDA PPU_STATUS

	; set background data write address
	; according the setting in the Initial_PPU_Control
	; the address is 0: 2000
	LDA #>(NAMETABLE_0)
	STA PPU_ADDR
	LDA #<(NAMETABLE_0)
	STA PPU_ADDR

	LDA #<(BIN_BACKGROUNDS)
	STA VAR_BG_LOW
	LDA #>(BIN_BACKGROUNDS)
	STA VAR_BG_HIGH

	LDX #$00
	LDY #$00
.Loop1:
	; from 0x0000 to 0x07FF
	LDA (VAR_BG_LOW),y
	STA PPU_DATA

	INY
	CPY #$00
	BNE .Loop1

	INC VAR_BG_HIGH
	INX
	CPX #$08
	BNE .Loop1

; draw high score
	LDA #$20
	STA PPU_ADDR
	LDA #$54
	STA PPU_ADDR
	LDX #$04

.Loop2
	LDA VAR_SCORE_HI,x
	CLC
	ADC #$91
	STA PPU_DATA
	DEX
	CPX #$FF
	BNE .Loop2
	RTS


LOAD_ATTRIBUTES:
	; read PPU status to reset the high/low latch
	LDA PPU_STATUS

	; set attributes for nametable0
	LDA #>(ATTRIBUTE_0)
	STA PPU_ADDR
	LDA #<(ATTRIBUTE_0)
	STA PPU_ADDR
	LDX #$00
.Loop3
	LDA BIN_ATTRIBUTES,x
	STA PPU_DATA
	INX
	; attributes.asm data size
	CPX #$40
	BNE .Loop3
	RTS


LOAD_SPRITES:
	LDX #$00

.Loop4
	lda BIN_SPRITE_0,x
	STA MEM_LAYOUT_SPR,x
	INX
	CPX #SPRITE_TOTAL_SIZE
	BNE .Loop4
	RTS
