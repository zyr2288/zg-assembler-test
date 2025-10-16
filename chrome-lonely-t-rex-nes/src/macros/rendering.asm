	.MACRO MACRO_DINO_ADD_X, value1
	LDX #$03
Loop
	LDA SPRITE_DINO,x
	ADC #value1
	STA SPRITE_DINO,x
	INX
	INX
	INX
	INX
	CPX #$1F
	BNE Loop
	.ENDM


	.MACRO MACRO_DINO_SUB_Y, value1
Loop
	LDA SPRITE_DINO,y
	SEC
	SBC value1
	STA SPRITE_DINO,y
	INY
	INY
	INY
	INY
	CPY #SPRITE_DINO_SIZE
	BNE Loop
	.ENDM


	.MACRO MACRO_DINO_ADD_Y, value1
Loop
	LDA SPRITE_DINO,y
	CLC
	ADC value1
	STA SPRITE_DINO,y
	INY
	INY
	INY
	INY
	CPY #SPRITE_DINO_SIZE
	BNE Loop
	.ENDM


	.MACRO MACRO_OBSTACLE_CLEAR_LINE
	stx PPU_ADDR
	sty PPU_ADDR
	lda BIN_EMPTY
	sta PPU_DATA
	sta PPU_DATA

	; set y, move to next line
	tya
	; #$20: magic number, row width
	adc #$20
	tay
	.ENDM


	.MACRO MACRO_OBSTACLE_DRAW_LINE
	stx PPU_ADDR
	sty PPU_ADDR
	lda BIN_HORIZON_LINE
	adc VAR_COLUMN_ID
	sta PPU_DATA
	adc #$01
	sta PPU_DATA

	; set y, move to next line
	tya
	; #$20: magic number, row width
	adc #$20
	tay
	.ENDM
