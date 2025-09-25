.INCLUDE "constants.asm"
.INCLUDE "header.asm"

; .segment  "ZEROPAGE"
	.ENUM $12
		; Player pools
		sprite_x,			NUM_PLAYERS
		sprite_y,			NUM_PLAYERS
		active_mon,			NUM_PLAYERS
		pads,				NUM_PLAYERS
		prev_pads,			NUM_PLAYERS
		jump_velocity,		NUM_PLAYERS
		attack_anim_timer,	NUM_PLAYERS
		damage_timer,		NUM_PLAYERS  ; Timer for damage animation

		; Projectile pools
		projectile_x,		NUM_PLAYERS
		projectile_y,		NUM_PLAYERS
		projectile_ceil,	NUM_PLAYERS
		projectile_floor,	NUM_PLAYERS

		; Pokemon pools
		sprite_x_vels, NUM_POKEMON
		jump_start_vels, NUM_POKEMON

		alive_mon, 6
		; alive_mon bitmask
		; 7. DEATH SOUND PLAYED
		; 6. Collision
		; 5. Jumping (in air)
		; 4. 1 / 0 -> (Go up / down)
		; 3. Projectile launched
		; 2. 1 / 0 -> (Go up / down)
		; 1-0. Health

		; MUSIC
		music_index, 1
		note_timer, 1

		; WINNER SCREEN
		winner_flag, 1 ; 0 = no one, 1 = P1, 2 = P2

		; HEALTH
		pending_hearts_update, 1
		damaged_pokemon_index, 1


		tile_bit_mask, 1  ; Stores the bitmak of the current sprite being drawn
		flip_state, 1  ; Stores flip status (0 = normal, 1 = mirrored)
		p1_animation_state, 1
		frame_counter, 1
		sleeping, 1

		; --------Draw vars--------
		index_sprite, 1
		temp1, 1  ; Memory offset / array index managers for drawing sprites
		temp2, 1  ; Intermediary variable
		temp3, 1  ; Intermediary variable
		projectile_bit_mask, 2


		; Player 1 sprite 2x2
		p1_tile_array, 4
	.ENDE

; .exportzp sprite_x, sprite_y, sprite_x_vels, projectile_x, projectile_y, tile_bit_mask, flip_state, p1_tile_array, pads, prev_pads
; .exportzp index_sprite, temp1, temp2, temp3, p1_animation_state, attack_anim_timer, frame_counter, jump_velocity, jump_start_vels
; .exportzp  alive_mon, active_mon, projectile_ceil, projectile_floor, winner_flag
; .exportzp pending_hearts_update, damaged_pokemon_index, damage_timer, music_index, note_timer

; .segment "CODE"
; .import update_animation_delay, update_players, update_projectiles, init_BGM


; We'll import external subroutines for loading backgrounds,
; as well as reading controllers for P1 and P2.
; .import Load_Background
; .import read_controllers
; .import update_collision_system, update_hearts_if_needed, update_winner_screen_if_needed, update_music, update_landing_thud
; .export palettes, pallet_lengths, pallet_notes

	.ORG $8000
	.BASE $10
	
	.INCLUDE "reset.asm"
	.INCLUDE "audio.asm"
	.INCLUDE "player/player.asm"
	.INCLUDE "hearts.asm"
	.INCLUDE "collision.asm"
	.INCLUDE "controllers.asm"

irq_handler
	RTI

nmi_handler
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA $2002                   ; Read PPU status to clear VBlank flag
	BIT $2002  

	JSR update_animation_delay


	LDA #$00
	STA OAMADDR
	LDA #$02
	STA OAMDMA

	; Update background hearts if needed
	JSR update_hearts_if_needed

	; Update the winner screen if needed
	JSR update_winner_screen_if_needed

	; Reset scroll
	LDA #$00
	STA $2005
	STA $2005

	LDA #$00
	STA sleeping

	; restore registers
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	
	RTI

main
	JSR init

	; write a palette
	LDX PPUSTATUS
	LDX #$3f
	STX PPUADDR
	LDX #$00
	STX PPUADDR
load_palettes
	LDA palettes,X
	STA PPUDATA
	INX
	CPX #$20
	BNE load_palettes


; Load the background from your routine
	JSR Load_Background

	; Clear winner flag
	LDA #$00
	STA winner_flag

vblankwait       ; wait for another vblank before continuing
	BIT PPUSTATUS
	BPL vblankwait

	LDA #@10010000  ; turn on NMIs, sprites use first pattern table
	STA PPUCTRL
	LDA #@00011110  ; turn on screen
	STA PPUMASK


; Place Game Logic updates and logic below
main_loop
	LDY #$00
	LDX #$00

	JSR read_controllers

	JSR update_players
	JSR update_projectiles

	JSR update_collision_system
	JSR update_music
	JSR update_landing_thud

	INC sleeping
sleep_loop
	LDA sleeping
	BNE sleep_loop

	JMP main_loop

init
	JSR init_BGM
	; -- Initialize general vars --
	LDA #$00
	LDX #$00
	LDY #$00
	STA frame_counter
	TAX
	TAY
	STA p1_animation_state
	STA tile_bit_mask
	STA flip_state

	; -- Initialize active Pokémon for both players --
	STA active_mon,X
	STA attack_anim_timer,X
	STA damage_timer,X
	INX
	STA active_mon,X
	STA attack_anim_timer,X
	STA damage_timer,X
	DEX

	; -- Set initial sprite positions --
	LDA #$10
	STA sprite_x,X
	LDA #$A0
	STA sprite_y,X
	INX
	; LDA #$70
	LDA #$D0
	STA sprite_x,X
	LDA #$A0
	STA sprite_y,X
	DEX

	; -- Initialize horizontal movement speeds per Pokémon --
	LDY #$00
@set_horizontal_speeds
	LDA horizontal_speeds_table,Y
	STA sprite_x_vels,Y
	INY
	CPY #NUM_POKEMON
	BNE @set_horizontal_speeds

	; -- Initialize starting jump velocities per Pokémon --
	LDY #$00
@set_jump_velocities
	LDA jump_velocities_table,Y
	STA jump_start_vels,Y
	INY
	CPY #NUM_POKEMON
	BNE @set_jump_velocities

	; -- Initialize alive_mon flags (alive + ground) --
	LDX #5
@set_alive_flags
	LDA #HEALTH
	STA alive_mon,X
	DEX
	BPL @set_alive_flags

	; -- Initialize current jump_velocity of players to 0 --
	LDX #$00
@clear_jump_velocity
	LDA #$00
	STA jump_velocity,X
	INX
	CPX #NUM_PLAYERS
	BNE @clear_jump_velocity

	; -- Initialize attack state and timers --
	LDX #$00
@clear_attack_flags
	LDA #$00
	STA attack_anim_timer,X
	INX
	CPX #NUM_PLAYERS
	BNE @clear_attack_flags


	; --- Clear pending heart update properly ---
	LDA #$00
	STA pending_hearts_update
	STA damaged_pokemon_index

	RTS

	.INCLUDE "sprites/bulbasaur-sprites.asm"
	.INCLUDE "sprites/pikachu-sprites.asm"
	.INCLUDE "sprites/charmander-sprites.asm"
	
	.INCLUDE "anims/bulbasaur-anim.asm"
	.INCLUDE "anims/pikachu-anim.asm"
	.INCLUDE "anims/charmander-anim.asm"
	
	.INCLUDE "projectiles/projectiles.asm"
	.INCLUDE "projectiles/proj_movement.asm"
	
	.INCLUDE "player/draw_players.asm"
	.INCLUDE "player/movement.asm"
	
	
	.INCLUDE "background_subroutines.asm"
	.INCLUDE "subroutines.asm"

; -- Horizontal movement speeds per Pokémon (Charmander, Bulbasaur, Pikachu) --
horizontal_speeds_table
	.DB $02  ; Charmander medium speed
	.DB $02  ; Bulbasaur slow speed
	.DB $03  ; Pikachu fast speed

; -- Initial jump starting velocities per Pokémon (higher = smaller jump) --
jump_velocities_table
	.DB $F7  ; Charmander medium-high jump
	.DB $F8  ; Bulbasaur medium jump
	.DB $F6  ; Pikachu high jump

;------------------------------------------------------------------------
; .segment "VECTORS"
; .addr nmi_handler, reset_handler, irq_handler

; .segment "RODATA"
palettes
	; Background
	.DB $2c, $11, $30, $0F ; light blue, blue, white, black 
	.DB $2c, $19, $09, $17 ; light blue, green, dark green, brown
	.DB $2c, $27, $16, $30 ; light blue, orange, dark orange, white 
	.DB $2c, $15, $30, $0F ; light blue, pink, white, black 

	; Sprites
	.DB $2c, $16, $27, $0f         ; Charmander Color Palette
	.DB $2c, $0F, $2A, $19         ; Bulbasaur Color Palette
	.DB $2c, $27, $15, $0f         ; Pikachu Color Palette
	.DB $2c, $16, $27, $0f


; can change vars name later
pallet_notes
	; NES pitch values (C5=0xA1, E5=0x8F, G5=0x80, A4=0xAB, etc.)
	.DB $A1, $91, $80, $91, $8F, $91, $A1, $A1
	.DB $BE, $AB, $A1, $BE, $AB, $9C, $00  ; $00 = End

pallet_lengths
	.DB 15, 15, 30, 15, 15, 30, 15, 15
	.DB 15, 15, 15, 30, 15, 30, 0

	.ORG $FFFA
	.DW nmi_handler, reset_handler, irq_handler

;------------------------------------------------------------------------
; .segment "CHR"
	.INCBIN "graphics.chr"