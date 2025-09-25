; .segment "ZEROPAGE"
; .importzp winner_flag

; .segment "CODE"
; .import palettes
; .export Load_Background, update_winner_screen_if_needed

Load_Background
	; left player
	jsr DrawLeftBackgroundPlayer

	; draw left player brackets
	jsr DrawLeftPlayerBrackets

	; draw left player first row of hearts
	jsr WriteLeftPlayerFirstHeartsRow

	; draw left player second row of hearts
	jsr WriteLeftPlayerSecondHeartsRow

	; draw left player third row of hearts
	jsr WriteLeftPlayerThirdHeartsRow

	; draw left player heart box attributes
	jsr WriteLeftPlayerHeartBoxAttrs

	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	; right player
	jsr DrawRightBackgroundPlayer

	; draw right player brackets
	jsr DrawRightPlayerBrackets

	; draw right player first row of hearts
	jsr WriteRightPlayerFirstHeartsRow

	; draw right player second row of hearts
	jsr WriteRightPlayerSecondHeartsRow

	; draw right player third row of hearts
	jsr WriteRightPlayerThirdHeartsRow

	; draw right player heart box attributes
	jsr WriteRightPlayerHeartBoxAttrs
	; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	; draw clouds
	jsr DrawCloudTopRows
	jsr DrawCloudBottomRows

	; draw floor
	jsr DrawGrassFlameFloorTopRow
	jsr FillGrassLavaFloorBelow

	; draw floor attributes
	jsr WriteFloorAttributes

	rts


DrawLeftBackgroundPlayer
	ldx #0

LoopBGP2Draw:
	lda Player1BGData,x
	sta PPUADDR
	inx

	lda Player1BGData,x
	sta PPUADDR
	inx

	lda Player1BGData,x
	sta PPUDATA
	inx

	lda Player1BGData,x
	sta PPUDATA
	inx

	cpx #24                 ; 6 entries × 4 bytes
	bne LoopBGP2Draw

	rts


; Format: HighAddr, LowAddr, Tile1, Tile2
Player1BGData:
	.DB $21, $20, $17, $18   ; Head
	.DB $21, $40, $19, $1A   ; Body
	.DB $21, $60, $0F, $0F   ; Floor
	.DB $21, $80, $0F, $00   ; Below Floor
	.DB $23, $D0, $33, $00 ; attribute table player
	.DB $23, $D8, $FF, $00 ; attribute table below player

DrawLeftPlayerBrackets
	ldx #0

DrawBracketsLoop:
	lda LeftPlayerBrackets,x
	sta PPUADDR
	inx

	lda LeftPlayerBrackets,x
	sta PPUADDR
	inx

	lda LeftPlayerBrackets,x
	sta PPUDATA
	inx

	cpx #12              ; total bytes (4 entries × 3)
	bne DrawBracketsLoop

	rts


LeftPlayerBrackets:
	.DB $20, $21, $09   ; top-left corner at $2021
	.DB $20, $2C, $0A   ; top-right corner at $202C
	.DB $20, $E1, $0B   ; bottom-left at $20E1
	.DB $20, $EC, $0C   ; bottom-right at $20EC


WriteLeftPlayerFirstHeartsRow
	; Set PPU address to $2042 (start of Player 1 hearts row)
	lda #$20
	sta PPUADDR
	lda #$42
	sta PPUADDR

	; Loop to write 8 tile values from FirstRowPlayerHearts
	ldx #0
WriteFirstRowHeartsLoop:
	lda FirstRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	bne WriteFirstRowHeartsLoop

	rts


; Tile data for: P1: <3 <3 <3
FirstRowPlayerHearts:
	.DB $04, $05, $08, $00
	.DB $0D, $0E, $0D, $0E
	.DB $0D, $0E, $00, $00

WriteLeftPlayerSecondHeartsRow
	lda #$20
	sta PPUADDR
	lda #$82
	sta PPUADDR

	; Loop to write 8 tile values from SecondRowPlayerHearts
	ldx #0
WriteSecondRowHeartsLoop:
	lda SecondRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	bne WriteSecondRowHeartsLoop

	rts


; Tile data for: P2: <3 <3 <3
SecondRowPlayerHearts:
	.DB $04, $06, $08, $00
	.DB $0D, $0E, $0D, $0E ;3X4
	.DB $0D, $0E, $00, $00


WriteLeftPlayerThirdHeartsRow
	lda #$20
	sta PPUADDR
	lda #$C2
	sta PPUADDR

	; Loop to write 8 tile values from SecondRowPlayerHearts
	ldx #0
WriteThirdRowHeartsLoop:
	lda ThirdRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	bne WriteThirdRowHeartsLoop

	rts


; Tile data for: P3: <3 <3 <3
ThirdRowPlayerHearts:
	.DB $04, $07, $08, $00
	.DB $0D, $0E, $0D, $0E ;3X4
	.DB $0D, $0E, $00, $00


WriteLeftPlayerHeartBoxAttrs
	ldx #0

LeftHeartBoxAttrsLoop:
	lda #$23             ; High byte for attribute table ($23C0–$23FF)
	sta PPUADDR

	lda LeftHeartBoxAttrLo,x   ; Load low byte from table
	sta PPUADDR

	lda #@11111111       ; Attribute byte: all 4 quadrants use same palette
	sta PPUDATA

	inx
	cpx #4               ; 4 total entries (C1, C2, C9, CA)
	bne LeftHeartBoxAttrsLoop

	rts


LeftHeartBoxAttrLo:
	.DB $C1, $C2, $C9, $CA     ; Attribute bytes for left player heart box

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DrawRightBackgroundPlayer
	ldx #0

-	lda Player2BGData,x
	sta PPUADDR
	inx

	lda Player2BGData,x
	sta PPUADDR
	inx

	lda Player2BGData,x
	sta PPUDATA
	inx

	lda Player2BGData,x
	sta PPUDATA
	inx

	cpx #16                 ; 4 entries × 4 bytes
	bne -

	rts


; Format: HighAddr, LowAddr, Tile1, Tile2
Player2BGData:
	.DB $21, $3E, $1B, $1C   ; Head
	.DB $21, $5E, $1D, $1E   ; Body
	.DB $21, $7E, $0F, $0F   ; Floor
	.DB $21, $9F, $0F, $00   ; Below Floor

DrawRightPlayerBrackets
	ldx #0

-	lda RightPlayerBrackets,x
	sta PPUADDR
	inx

	lda RightPlayerBrackets,x
	sta PPUADDR
	inx

	lda RightPlayerBrackets,x
	sta PPUDATA
	inx

	cpx #12              ; total bytes (4 entries × 3)
	bne -

	rts


RightPlayerBrackets:
	.DB $20, $33, $09   ; top-left corner at $2021
	.DB $20, $3E, $0A   ; top-right corner at $202C
	.DB $20, $F3, $0B   ; bottom-left at $20E1
	.DB $20, $FE, $0C   ; bottom-right at $20EC

WriteRightPlayerFirstHeartsRow
	; Set PPU address to $2042 (start of Player 1 hearts row)
	lda #$20
	sta PPUADDR
	lda #$54
	sta PPUADDR

	; Loop to write 8 tile values from FirstRowPlayerHearts
	ldx #0
-
	lda FirstRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	; reuses firstrowplayerhearts from before
	bne -

	rts


WriteRightPlayerSecondHeartsRow
	lda #$20
	sta PPUADDR
	lda #$94
	sta PPUADDR

	; Loop to write 8 tile values from SecondRowPlayerHearts
	ldx #0
-
	lda SecondRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	; reuses secondrowplayerhearts from before
	bne -

	rts



WriteRightPlayerThirdHeartsRow
	lda #$20
	sta PPUADDR
	lda #$D4
	sta PPUADDR

	; Loop to write 8 tile values from SecondRowPlayerHearts
	ldx #0
-
	lda ThirdRowPlayerHearts,x
	sta PPUDATA
	inx
	cpx #12
	; reuses thirdrowplayerhearts from before
	bne -

	rts



WriteRightPlayerHeartBoxAttrs
	ldx #0

RightHeartBoxAttrsLoop:
	lda #$23             ; High byte for attribute table ($23C0–$23FF)
	sta PPUADDR

	lda RightHeartBoxAttrLo,x   ; Load low byte from table
	sta PPUADDR

	lda #@11111111       ; Attribute byte: all 4 quadrants use same palette
	sta PPUDATA

	inx
	cpx #4               ; 4 total entries (C1, C2, C9, CA)
	bne RightHeartBoxAttrsLoop

	rts


RightHeartBoxAttrLo:
	.DB $C6, $C7, $CE, $CF     ; Attribute bytes for left player heart box

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DrawCloudTopRows
	ldx #0

NextCloudRow:
	lda CloudTopRowData,x
	sta PPUADDR         ; High byte
	inx
	lda CloudTopRowData,x
	sta PPUADDR         ; Low byte
	inx

	; Write 10 tiles
	ldy #0
WriteTiles:
	lda CloudTopRowData,x
	sta PPUDATA
	inx
	iny
	cpy #18
	bne WriteTiles

	; Check if done: 2 full rows = 24 bytes
	cpx #40
	bne NextCloudRow

	rts


CloudTopRowData:
	.DB $21, $47, $11, $12  ; Top row of cloud
	.DB $13, $00, $00, $11
	.DB $12, $13, $00, $00
	.DB $11, $12, $13, $00
	.DB $00, $11, $12, $13

	.DB $21, $67, $14, $15 ; Bottom row of cloud
	.DB $16, $00, $00, $14
	.DB $15, $16, $00, $00
	.DB $14, $15, $16, $00
	.DB $00, $14, $15, $16
	

DrawCloudBottomRows
	ldx #0

--
	lda CloudBottomRowData,x
	sta PPUADDR         ; High byte
	inx
	lda CloudBottomRowData,x
	sta PPUADDR         ; Low byte
	inx

	; Write 10 tiles
	ldy #0
-
	lda CloudBottomRowData,x
	sta PPUDATA
	inx
	iny
	cpy #18
	bne -

	; Check if done: 2 full rows = 24 bytes
	cpx #40
	bne --

	rts



CloudBottomRowData:
	.DB $21, $84, $11, $12 ; Top row of cloud
	.DB $13, $00, $00, $11
	.DB $12, $13, $00, $00
	.DB $11, $12, $13, $00
	.DB $00, $11, $12, $13

	.DB $21, $A4, $14, $15 ; Bottom row of cloud
	.DB $16, $00, $00, $14
	.DB $15, $16, $00, $00
	.DB $14, $15, $16, $00
	.DB $00, $14, $15, $16

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DrawGrassFlameFloorTopRow
	ldx #0

	; Set PPU address to row 8
	lda FloorFirstRowData,x
	sta PPUADDR
	inx
	lda FloorFirstRowData,x
	sta PPUADDR
	inx

	; Write 32 tiles: grass (12),flames (8), grass (12)
	ldy #0
DrawTileLoop:
	lda FloorFirstRowData,x
	sta PPUDATA
	inx
	iny
	cpy #32
	bne DrawTileLoop

	rts



FloorFirstRowData:
	.DB $22, $C0           ; PPU address: $22C0 (row 8, leftmost)
	
	; 12 grass tiles (left)
	.repeat 12
	  .DB $01
	.endr

	; 8 flame void tiles (middle)
	.repeat 8
	  .DB $10
	.endr

	; 12 grass tiles (right)
	.repeat 12
	  .DB $01
	.endr

FillGrassLavaFloorBelow
	ldy #0        ; row index (0–5)

NextRow:
	lda FlameFillRows,y
	sta PPUADDR         ; High byte
	iny
	lda FlameFillRows,y
	sta PPUADDR         ; Low byte
	iny

	; --- 12 grass tiles (left) ---
	ldx #0
GrassLeft:
	lda #$01
	sta PPUDATA
	inx
	cpx #12
	bne GrassLeft

	; --- 8 flame tiles (center) ---
	ldx #0
FlamesMiddle:
	lda #$0F
	sta PPUDATA
	inx
	cpx #8
	bne FlamesMiddle

	; --- 12 grass tiles (right) ---
	ldx #0
GrassRight:
	lda #$01
	sta PPUDATA
	inx
	cpx #12
	bne GrassRight

	cpy #12        ; 6 rows * 2 bytes each = 12
	bne NextRow

	rts


FlameFillRows:
; Format: HighByte, LowByte
	.DB $22, $E0   ; row 9
	.DB $23, $00   ; row 10
	.DB $23, $20   ; row 11
	.DB $23, $40   ; row 12
	.DB $23, $60   ; row 13
	.DB $23, $80   ; row 14
	; .DB $23, $A0   ; row 15 In Nexxt is missing but idk if it's needed

WriteFloorAttributes
	ldx #0

WriteNextAttr:
	lda FloorAttributeData,x
	sta PPUADDR        ; High byte
	inx
	lda FloorAttributeData,x
	sta PPUADDR        ; Low byte
	inx
	lda FloorAttributeData,x
	sta PPUDATA        ; Attribute value
	inx

	cpx #72            ; 24 entries × 3 bytes = 72
	bne WriteNextAttr

	rts


FloorAttributeData:
	; NOTE: is $2000 plus the offset, however for attribute the offset is atOff specifically
	; Format: HighByte, LowByte, AttributeValue
	; grass
	.DB $23, $E8, $55 ;this code block cover the first two rows
	.DB $23, $E9, $55
	.DB $23, $EA, $55
	; flame
	.DB $23, $EB, $AA
	.DB $23, $EC, $AA
	; grass
	.DB $23, $ED, $55
	.DB $23, $EE, $55
	.DB $23, $EF, $55

	; grass
	.DB $23, $F0, $55 ;this code block cover next 4 rows
	.DB $23, $F1, $55
	.DB $23, $F2, $55
	; lava
	.DB $23, $F3, $AA
	.DB $23, $F4, $AA
	; grass
	.DB $23, $F5, $55
	.DB $23, $F6, $55
	.DB $23, $F7, $55
	; grass
	.DB $23, $F8, $55 ;this code block cover the remaining rows
	.DB $23, $F9, $55
	.DB $23, $FA, $55
	; lava
	.DB $23, $FB, $AA
	.DB $23, $FC, $AA
	; grass
	.DB $23, $FD, $55
	.DB $23, $FE, $55
	.DB $23, $FF, $55


; ================================================
; Clears brackets and heart HUDs for both players
; ================================================
Clear_Heart_HUDs
	; Clear Left Player Brackets ($2021, $202C, $20E1, $20EC)
	LDX #0
@clear_left_brackets:
	LDA #$20        ; High byte
	STA PPUADDR
	LDA ClearLeftBracketLo,x
	STA PPUADDR
	LDA #$00
	STA PPUDATA
	INX
	CPX #4
	BNE @clear_left_brackets

	; Clear Right Player Brackets ($2033, $203E, $20F3, $20FE)
	LDX #0
@clear_right_brackets:
	LDA #$20
	STA PPUADDR
	LDA ClearRightBracketLo,x
	STA PPUADDR
	LDA #$00
	STA PPUDATA
	INX
	CPX #4
	BNE @clear_right_brackets

	; Clear 3 Heart Rows Left Player: $2042, $2082, $20C2
	LDX #0
@clear_left_heart_rows:
	LDA ClearLeftHeartRowsHi,x
	STA PPUADDR
	LDA ClearLeftHeartRowsLo,x
	STA PPUADDR
	LDY #12
@clear_left_loop:
	LDA #$00
	STA PPUDATA
	DEY
	BNE @clear_left_loop
	INX
	CPX #3
	BNE @clear_left_heart_rows

	; Clear 3 Heart Rows Right Player: $2054, $2094, $20D4
	LDX #0
@clear_right_heart_rows:
	LDA ClearRightHeartRowsHi,x
	STA PPUADDR
	LDA ClearRightHeartRowsLo,x
	STA PPUADDR
	LDY #12
@clear_right_loop:
	LDA #$00
	STA PPUDATA
	DEY
	BNE @clear_right_loop
	INX
	CPX #3
	BNE @clear_right_heart_rows

	RTS


ClearLeftBracketLo:
	.DB $21, $2C, $E1, $EC

ClearRightBracketLo:
	.DB $33, $3E, $F3, $FE

ClearLeftHeartRowsHi:
	.DB $20, $20, $20

ClearLeftHeartRowsLo:
	.DB $42, $82, $C2

ClearRightHeartRowsHi:
	.DB $20, $20, $20

ClearRightHeartRowsLo:
	.DB $54, $94, $D4


; =========================================================

update_winner_screen_if_needed
	LDA winner_flag
	BEQ @skip

	; Disable rendering
	LDA #$00
	STA PPUMASK

	; Reset scroll latch
	LDA $2002

	; Clear only brackets and HUD
	JSR Clear_Heart_HUDs

	; Draw text and Pokéballs in center of screen
	JSR draw_top_pokeballs_row
	JSR draw_bottom_pokeballs_row
	JSR draw_winner_message_row

	; === FINAL scroll re-lock (required after any $2006/$2007 use!) ===
	LDA #$00
	STA $2005
	STA $2005

	; Re-enable rendering
	LDA #@00011110
	STA PPUMASK

@skip:
	RTS


draw_top_pokeballs_row
	; === Row 2: Top halves of Pokéballs with spacing ===
	LDA #$20
	STA PPUADDR
	LDA #$8B            ; Row 2, col 11
	STA PPUADDR
	LDX #0
@poke_top:
	LDA PokeballTopTilesWithSpaces,x
	STA PPUDATA
	INX
	CPX #8
	BNE @poke_top

	RTS


draw_bottom_pokeballs_row
	; === Row 3: Bottom halves of Pokéballs with spacing ===
	LDA #$20
	STA PPUADDR
	LDA #$AB            ; Row 3, col 11 (aligned with top row)
	STA PPUADDR
	LDX #0
@poke_bot:
	LDA PokeballBottomTilesWithSpaces,x
	STA PPUDATA
	INX
	CPX #8
	BNE @poke_bot
	RTS



draw_winner_message_row
	; === Row 5: Winner message at col 10 ===
	LDA #$20
	STA PPUADDR
	LDA #$EA
	STA PPUADDR
	LDX #0
@loop:
	LDA WinnerTextPrefix,x
	STA PPUDATA
	INX
	CPX #8
	BNE @loop

	; === Inverted logic: winner_flag tells who LOST ===
	LDA winner_flag
	CMP #$01
	BEQ @p2     ; If P1 lost, P2 won

@p1:
	LDA #$05    ; P1 won
	STA PPUDATA
	JMP @exclaim

@p2:
	LDA #$06    ; P2 won
	STA PPUDATA

@exclaim:
	LDA #$1F
	STA PPUDATA
	STA PPUDATA

	; === Set background palette for WINNER text (attribute table) ===
	LDA PPUSTATUS       ; Reset scroll latch
	LDA #$23
	STA PPUADDR
	LDA #$CA            ; Attribute byte at $23CA
	STA PPUADDR
	LDA #@00000000      ; Palette 0 for all 4 quadrants
	STA PPUDATA

	RTS


 
WinnerTextPrefix:
	.DB $20, $21, $22, $22, $23, $24 ; W I N N E R
	.DB $00, $04    ;   P 

PokeballTopTilesWithSpaces:
	.DB $25, $26, $00, $25, $26, $00, $25, $26

PokeballBottomTilesWithSpaces:
	.DB $27, $28, $00, $27, $28, $00, $27, $28
