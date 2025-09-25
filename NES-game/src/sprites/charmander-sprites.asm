; .segment  "ZEROPAGE"
; .importzp sprite_x, sprite_y, flip_state, p1_tile_array, tile_bit_mask
; .importzp index_sprite, temp1, temp2


; .segment "CODE"
; .import draw_1x1, draw_2x1, draw_2x2
; .export charmander_walk_1, charmander_walk_2, charmander_idle, charmander_jump, set_palette_charmander
; .export charmander_damaged, charmander_attack, charmander_knockout, charmander_projectile_1, charmander_projectile_2


charmander_walk_1
	LDX #$00

	LDA #$E2 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$E3 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$F2 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$F3 ; Tile bottom right
	STA p1_tile_array,X

	JSR draw_2x2
	RTS


charmander_walk_2
	LDX #$00

	LDA #$E4 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$E5 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$F4 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$F5 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_idle
	JSR set_palette_charmander
	LDX #$00

	LDA #$E0 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$E1 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$F0 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$F1 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_jump
	LDX #$00

	LDA #$E6 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$E7 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$F6 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$F7 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_damaged
	JSR set_palette_charmander
	LDX #$00

	LDA #$EA ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$EB ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$FA ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$FB ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_attack
	JSR set_palette_charmander
	LDX #$00

	LDA #$E8 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$E9 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$F8 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$F9 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_knockout
	JSR set_palette_charmander
	LDX #$00

	LDA #$EC ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$ED ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$FC ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$FD ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


charmander_projectile_1
	LDX #$00

	LDA #$EE ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$EF ; Tile top Right
	STA p1_tile_array,X

	; Set Mem Offset to RegX
	STY temp2
	LDY temp1

	LDX #$00

	JSR draw_2x1

	LDY temp2
	RTS


charmander_projectile_2
	LDX #$00

	LDA #$FE ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$FF ; Tile top Right
	STA p1_tile_array,X

	; Set Mem Offset to RegX
	STY temp2
	LDY temp1

	LDX #$00

	JSR draw_2x1

	LDY temp2
	RTS


set_palette_charmander
	LDA #$00
	STA tile_bit_mask

	RTS
