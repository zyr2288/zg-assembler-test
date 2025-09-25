; .segment  "ZEROPAGE"
; .importzp sprite_x, sprite_y, tile_bit_mask, flip_state, p1_tile_array
; .importzp index_sprite, temp1, temp2


; .segment "CODE"
; .import draw_1x1, draw_2x2

; .export bulbasaur_walk_1, bulbasaur_walk_2, bulbasaur_idle, bulbasaur_jump
; .export bulbasaur_damaged, bulbasaur_attack, bulbasaur_dead, bulbasaur_projectile, set_palette_bulbasaur


bulbasaur_walk_1
	LDX #$00

	LDA #$04 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$05 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$14 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$15 ; Tile bottom right
	STA p1_tile_array,X

	JSR draw_2x2
	RTS


bulbasaur_walk_2
	LDX #$00

	LDA #$04 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$25 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$34 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$35 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


bulbasaur_idle
	JSR set_palette_bulbasaur
	LDX #$00

	LDA #$04 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$05 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$54 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$55 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


bulbasaur_jump
	LDX #$00

	LDA #$04 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$05 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$74 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$75 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


bulbasaur_damaged
	JSR set_palette_bulbasaur
	LDX #$00

	LDA #$64 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$65 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$74 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$75 ; Tile bottom right
	STA p1_tile_array,X

	JSR draw_2x2
	RTS



bulbasaur_attack
	JSR set_palette_bulbasaur
	LDX #$00

	LDA #$84 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$05 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$54 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$55 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


bulbasaur_dead
	JSR set_palette_bulbasaur
	LDX #$00

	LDA #$A4 ; Tile top left
	STA p1_tile_array,X
	INX

	LDA #$A5 ; Tile top right
	STA p1_tile_array,X
	INX

	LDA #$B4 ; Tile bottom left
	STA p1_tile_array,X
	INX

	LDA #$B5 ; Tile bottom right
	STA p1_tile_array,X
	INX

	JSR draw_2x2
	RTS


bulbasaur_projectile
	LDA #$06
	STA index_sprite

	JSR draw_1x1
	RTS


set_palette_bulbasaur
	LDA #$01 ; Bulbasaur color palette
	STA tile_bit_mask

	RTS
