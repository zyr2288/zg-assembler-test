; .segment  "ZEROPAGE"
; .importzp sprite_x, sprite_y, flip_state, p1_tile_array, tile_bit_mask, p1_animation_state
; .importzp index_sprite, temp1, temp2


; .segment "CODE"
; .import draw_1x1, draw_2x2, Increment_RegX_4, shift_down, shift_up
; .export pikachu_walk_1, pikachu_walk_2, pikachu_idle, pikachu_jump
; .export pikachu_damaged, pikachu_attack, pikachu_knockout, pikachu_projectile, set_palette_pikachu


pikachu_walk_1
	LDX #$00

	LDA #$C2 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$C3 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$D2 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$D3 ; Tile bottom right
	STA p1_tile_array,X

	JSR draw_2x2
	RTS


pikachu_walk_2
	LDX #$00

	LDA #$C4 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$C5 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$D4 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$D5 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_idle
	LDX #$00
	JSR set_palette_pikachu

	LDA #$C0 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$C1 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$D0 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$D1 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_jump
	LDX #$00

	LDA #$C6 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$C7 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$D6 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$D7 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_damaged
	JSR set_palette_pikachu
	LDX #$00

	LDA #$CA ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$CB ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$DA ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$DB ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_attack
	JSR set_palette_pikachu
	LDX #$00
	
	LDA #$C8 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$C9 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$D8 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$D9 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_knockout
	JSR set_palette_pikachu
	LDX #$00

	LDA #$CC ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$CD ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$DC ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$DD ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


pikachu_projectile
	LDY temp1  ;  Load Player on RegY

	LDA #$CE
	STA index_sprite
	
	LDA p1_animation_state
	BNE @Flipped

	@Normal:
	JSR draw_1x1
	JSR shift_down

	LDA tile_bit_mask
	EOR #@01000000
	STA tile_bit_mask

	JSR draw_1x1
	JSR shift_up

	JMP @exit_projectile

	@Flipped:
	JSR shift_down
	JSR draw_1x1

	LDA tile_bit_mask
	EOR #@01000000
	STA tile_bit_mask

	JSR shift_up
	JSR draw_1x1

	@exit_projectile:
	LDY temp2  ;  Restore Memory Offset
	RTS


set_palette_pikachu
	LDA #$02 ; Pikachu color palette
	STA tile_bit_mask

	RTS
