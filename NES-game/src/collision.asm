; .segment "ZEROPAGE"
; .importzp sprite_x, sprite_y, alive_mon, active_mon
; .importzp damaged_pokemon_index, pending_hearts_update, damage_timer, damage_timer2, temp1, temp2, projectile_x, projectile_y, winner_flag

; .segment "CODE"
; .export update_collision_system, apply_damage_to_active_pokemon

; .import validate_offset_mult, play_damage_sfx

	.DEF LAVA_X_START,  96
	.DEF LAVA_X_END,    160
	.DEF LAVA_Y_START,  120

; ============================================
; Update collision system (damage + teleport)
; ============================================
update_collision_system
	LDX #$00  ; X = Player index (0 = Player 1, 1 = Player 2)

@loop_players:
	; Get Active Pokémon global index (Y = 0..5)
	JSR get_active_pokemon_index

	; Check collision based on PLAYER position
	LDA sprite_x,X
	CMP #LAVA_X_START
	BCC @no_collision
	CMP #LAVA_X_END
	BCS @no_collision

	LDA sprite_y,X
	CMP #LAVA_Y_START
	BCC @no_collision

	; --- Collision detected! Apply damage to active Pokémon Y ---

	JSR apply_damage_to_active_pokemon

@teleport:
	; --- Always teleport player after collision ---
	CPX #$00
	BEQ @player1_start

	; Player 2 teleport
	LDA #$D0
	STA sprite_x,X
	LDA #$A0
	STA sprite_y,X
	JMP @next_player

@player1_start:
	; Player 1 teleport
	LDA #$10
	STA sprite_x,X
	LDA #$A0
	STA sprite_y,X

@next_player:
	; Move to next player
	INX
	CPX #NUM_PLAYERS
	BNE @loop_players

	; After all players checked
	JSR check_players_death
	RTS

@no_collision:
	; No collision, move to next player
	INX
	CPX #NUM_PLAYERS
	BNE @loop_players

	; After all players checked
	JSR check_players_death
	JSR check_projectile_collisions
	RTS
.endproc

; ============================================
; Check if all Pokémon from a player are dead
; ============================================
check_players_death
	; --- Check Player 1 ---
	LDX #$00        ; Start at Pokémon 0
	LDY #$03        ; End at Pokémon 3 (not included)

@check_p1_loop:
	LDA alive_mon,X
	AND #HEALTH
	BNE @still_alive_p1
	INX
	CPX #$03
	BNE @check_p1_loop

	; All Player 1 Pokémon dead
	; JSR change_background_color
	LDA #$01     ; o #$02 para P2
	STA winner_flag

	RTS

@still_alive_p1:
	; --- Check Player 2 ---
	LDX #$03        ; Start at Pokémon 3
	LDY #$06        ; End at Pokémon 6 (not included)

@check_p2_loop:
	LDA alive_mon,X
	AND #HEALTH
	BNE @still_alive_p2
	INX
	CPX #$06
	BNE @check_p2_loop

	; All Player 2 Pokémon dead
	; JSR change_background_color
	LDA #$02     ; o #$02 para P2
	STA winner_flag

@still_alive_p2:
	RTS

; ============================================
; Get active Pokémon index for Player X
; ============================================
get_active_pokemon_index
	; Input: X = Player index (0 or 1)
	; Output: Y = Global Pokémon index (0..5)

	LDY active_mon,X
	JSR validate_offset_mult
	RTS


; ============================================
; Universal Damage Subroutine
; Applies 1 damage to alive_mon[Y] and sets timers
; Input:
;   - X: player index (0 = p1, 1 = p2)
;   - Y: global Pokémon index (0..5), already validated
; ============================================
apply_damage_to_active_pokemon
	; Check if Pokémon is already dead
	LDA alive_mon,Y
	AND #HEALTH
	BEQ +

	; Subtract 1 from health
	JSR play_damage_sfx
	LDA alive_mon,Y
	SEC
	SBC #$01
	STA alive_mon,Y

	; Activate damage timer
	LDA #40
	STA damage_timer,X
	JMP @set_heart_update

@set_heart_update
	TYA
	STA damaged_pokemon_index
	LDA #$01
	STA pending_hearts_update

+
	RTS

check_projectile_collisions
	LDX #$00  ; Target Player loop: 0 = P1, 1 = P2

	@loop_target:
	; Get global index for active Pokémon
	LDY active_mon,X
	JSR validate_offset_mult

	; Skip if already dead
	LDA alive_mon,Y
	AND #HEALTH
	BEQ @next_target

	STX temp1        ; Save target player (0 or 1)
	TXA
	EOR #$01         ; Switch to other player (attacker)
	TAX              ; X = attacker index

	; Check if projectile is inactive
	LDA projectile_x,X
	CLC
	ADC #8
	CMP #$F8
	BCS @skip_check  ; Projectile not active

	; --- Bounding box collision (8px) ---

	@hitbox_detection_loop:
	; Load target sprite X
	JSR check_projectile_collision

	LDX temp1
	LDY active_mon,X
	JSR validate_offset_mult

	LDA alive_mon,Y
	AND #COLLISION
	BEQ @skip_check

	; --- Collision detected ---
	LDA alive_mon,Y
	EOR #COLLISION
	STA alive_mon,Y

	JSR apply_damage_to_active_pokemon

	; Clear projectile after hit
	TXA
	EOR #$01
	TAX
	LDA #$F8
	STA projectile_x,X
	STA projectile_y,X

	; Clear attack bit from alive_mon
	LDY active_mon,X
	JSR validate_offset_mult
	LDA alive_mon,Y
	AND #@11110011  ; Clear bit 3
	STA alive_mon,Y


@skip_check
	LDX temp1
@next_target
	INX
	CPX #$02
	BNE @loop_target
	RTS

player_hitbox_creation
	; LDY temp1
	
	; Top Left tile
	JSR check_collision_tile

	LDA sprite_x,Y
	CLC
	ADC #8
	STA sprite_x,Y

	; Top Right tile
	JSR check_collision_tile

	LDA sprite_y,Y
	CLC
	ADC #8
	STA sprite_y,Y

	; Bottom Right tile
	JSR check_collision_tile

	LDA sprite_x,Y
	SEC
	SBC #8
	STA sprite_x,Y

	; Bottom Left Tile
	JSR check_collision_tile

	LDA sprite_y,Y
	SEC
	SBC #8
	STA sprite_y,Y

	RTS

check_collision_tile
	; Compare a single tile of a projectile to one sprite tile (X: projectile,Y: sprite)
	; Uses temp1/temp2 to hold projectile_x/y offset
	; Sets bit 6 of ARRRRS,Y if collision is found

	; X axis
	LDA temp1       ; projectile_x offset
	SEC
	SBC sprite_x,Y
	BCS @x_positive
	EOR #$FF
	CLC
	ADC #1
@x_positive:
	CMP #8
	BCS +       ; skip if diff >= 8

	; Y axis
	LDA temp2       ; projectile_y offset
	SEC
	SBC sprite_y,Y
	BCS @y_positive
	EOR #$FF
	CLC
	ADC #1
	@y_positive:
	CMP #8
	BCS +       ; skip if diff >= 8

	; Collision detected
	TXA
	PHA
	TYA
	PHA
	TAX
	
	LDY active_mon,X
	JSR validate_offset_mult
	
	LDA alive_mon,Y
	ORA #COLLISION
	STA alive_mon,Y
	
	PLA
	TAY
	PLA
	TAX
+	RTS

check_projectile_collision
	; Must be called with X = projectile index and Y = sprite index
	LDA temp1
	PHA
	LDY temp1

	LDA projectile_x,X
	STA temp1
	LDA projectile_y,X
	STA temp2
	JSR player_hitbox_creation   ; always check top-left (base)

	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @check_horizontal

	LDA active_mon,X
	CMP #PIKACHU
	BEQ @check_vertical

	JMP +

@check_horizontal
	; === 2x1 (horizontal) ===
	LDA projectile_x,X
	CLC
	ADC #8
	STA temp1
	LDA projectile_y,X
	STA temp2
	JSR player_hitbox_creation
	JMP +

@check_vertical
	; === 1x2 (vertical) ===
	LDA projectile_x,X
	STA temp1
	LDA projectile_y,X
	CLC
	ADC #8
	STA temp2
	JSR player_hitbox_creation

+	PLA
	STA temp1
	RTS