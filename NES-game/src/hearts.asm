; .segment "ZEROPAGE"
; .importzp alive_mon
; .importzp damaged_pokemon_index, pending_hearts_update

; .segment "CODE"
; .export update_hearts_if_needed

p1_hearts_row_hi:
	.db $20, $20, $20

p1_hearts_row_lo:
	.db $42, $82, $C2

p2_hearts_row_hi:
	.db $20, $20, $20

p2_hearts_row_lo:
	.db $54, $94, $D4

; ==========================================
; Check and update hearts display (only if needed)
; ==========================================
update_hearts_if_needed
	LDA pending_hearts_update
	BEQ @done

	; Update based on damaged Pokémon
	LDA damaged_pokemon_index
	JSR redraw_hearts_by_pokemon_index

	; Clear pending flag
	LDA #$00
	STA pending_hearts_update

@done:
	RTS


; ==========================================
; Draw hearts depending on health value
; ==========================================

draw_hearts_based_on_life
	; A = health (0–3)

	; Step 1: Check health and branch
	CMP #$02
	BEQ @draw_two
	CMP #$01
	BEQ @draw_one

@draw_zero:
	; 0 health: clear all three hearts

	; Skip 'P', number, ':', blank tile
	LDX #4
@skip_zero:
	LDA $2007
	DEX
	BNE @skip_zero

	; Draw six empty tiles
	LDA #$00
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	RTS

@draw_one:
	; 1 health: draw 1 heart, 2 empty hearts

	; Skip 'P', number, ':', blank tile
	LDX #4
@skip_one:
	LDA $2007
	DEX
	BNE @skip_one

	; Draw one full heart
	LDA #$0D
	STA PPUDATA
	LDA #$0E
	STA PPUDATA

	; Fill the rest with blanks
	LDA #$00
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	STA PPUDATA
	RTS

@draw_two:
	; 2 health: draw 2 hearts, 1 empty heart

	; Skip 'P', number, ':', blank tile
	LDX #4
@skip_two:
	LDA $2007
	DEX
	BNE @skip_two

	; Draw two full hearts
	LDA #$0D
	STA PPUDATA
	LDA #$0E
	STA PPUDATA
	LDA #$0D
	STA PPUDATA
	LDA #$0E
	STA PPUDATA

	; Fill the last heart with blanks
	LDA #$00
	STA PPUDATA
	STA PPUDATA
	RTS




; ==========================================
; Redraw hearts row based on Pokémon index (0..5)
; ==========================================
redraw_hearts_by_pokemon_index
	; A = Pokémon index (0..5)
	PHA
	TAY

	; Determine if it's Player 1 or Player 2
	CPY #$03
	BCC @player1

	; Player 2 (index 3-5)
	LDA p2_hearts_row_hi - 3,Y
	STA PPUADDR
	LDA p2_hearts_row_lo - 3,Y
	STA PPUADDR
	JMP @draw

@player1:
	; Player 1 (index 0-2)
	LDA p1_hearts_row_hi,Y
	STA PPUADDR
	LDA p1_hearts_row_lo,Y
	STA PPUADDR

@draw:
	PLA
	TAY
	LDA alive_mon,Y
	AND #@00000011
	JSR draw_hearts_based_on_life
	RTS


