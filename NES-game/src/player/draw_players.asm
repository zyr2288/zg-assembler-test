; .segment "ZEROPAGE"
; .importzp sprite_x, sprite_y, tile_bit_mask, flip_state, p1_tile_array, pads, active_mon, damage_timer, temp1, temp2, index_sprite, alive_mon
; .importzp attack_anim_timer

; .segment "CODE"
; .export draw_player, draw_jump, draw_horizontal, draw_idle, draw_dead, draw_damaged_pokemon, draw_attack

; .import bulbasaur_idle, bulbasaur_walk_cycle, bulbasaur_jump_cycle, bulbasaur_dead
; .import bulbasaur_damaged_cycle, bulbasaur_attack, bulbasaur_damaged, bulbasaur_dead_cycle

; .import charmander_idle, charmander_walk_cycle, charmander_jump_cycle, charmander_knockout
; .import charmander_damaged_cycle, charmander_attack, charmander_damaged, charmander_knockout_cycle

; .import pikachu_idle, pikachu_walk_cycle, pikachu_jump_cycle, pikachu_knockout
; .import pikachu_damaged_cycle, pikachu_attack, pikachu_damaged, pikachu_knockout_cycle
; .import check_jump


draw_player
	STX temp1
	STY temp2
	
	; -- Check Damage First --
	LDA damage_timer,X
	BEQ @check_attacking  ; If damaged, skip normal
	
	JSR draw_damaged_pokemon
	JMP @exit_player_draw

	; -- Check attack animation --
	@check_attacking:
	LDA attack_anim_timer,X
	BEQ @check_alive_status

	; LDY temp2
	JSR draw_attack
	JMP @exit_player_draw
	
@check_alive_status:
	; -- Continue normal drawing --
	LDY active_mon,X
	CPX #$01
	BNE @correct_alive_index

	; If Player 2, shift to alive_mon[3..5]
	TYA
	CLC
	ADC #$03
	TAY

@correct_alive_index:
	LDA alive_mon,Y
	AND #HEALTH
	BEQ @draw_this_player_dead  ; If health = 0, draw death animation

	; --- Not dead: normal movement checks ---
	JSR check_jump
	BEQ @check_movement_input

	; If jumping, draw jump animation
	LDY temp2
	JSR draw_jump
	JMP @exit_player_draw

@check_movement_input:
	LDY temp2

	; Check for horizontal movement
	LDA pads,X
	AND #(BTN_LEFT | BTN_RIGHT)
	BNE @draw_player_walk

	; Else idle
	JSR draw_idle
	JMP @exit_player_draw

@draw_player_walk:
	JSR draw_horizontal
	JMP @exit_player_draw

@draw_this_player_dead:
	LDY temp2
	JSR draw_dead

@exit_player_draw:
	LDX temp1
	RTS



; -------- ONLY DRAW NORMAL SPRITES NOW --------
draw_jump
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_jump

	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @draw_bulbasaur_jump

	JMP @draw_pikachu_jump

@draw_charmander_jump:
	JSR charmander_jump_cycle
	RTS

@draw_bulbasaur_jump:
	JSR bulbasaur_jump_cycle
	RTS

@draw_pikachu_jump:
	JSR pikachu_jump_cycle
	RTS


draw_horizontal
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_walk

	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @draw_bulbasaur_walk

	JMP @draw_pikachu_walk

@draw_charmander_walk:
	JSR charmander_walk_cycle
	RTS

@draw_bulbasaur_walk:
	JSR bulbasaur_walk_cycle
	RTS

@draw_pikachu_walk:
	JSR pikachu_walk_cycle
	RTS


draw_idle
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_idle

	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @draw_bulbasaur_idle

	; Otherwise Pikachu
	JMP @draw_pikachu_idle

@draw_charmander_idle:
	JSR charmander_idle
	RTS

@draw_bulbasaur_idle:
	JSR bulbasaur_idle
	RTS

@draw_pikachu_idle:
	JSR pikachu_idle
	RTS



draw_dead
	; Determine which Pokémon's death animation to draw
	LDA active_mon,X

	; Charmander?
	CMP #CHARMANDER
	BEQ @draw_charmander_dead

	; Bulbasaur?
	CMP #BULBASAUR
	BEQ @draw_bulbasaur_dead

	; Otherwise, Pikachu
	JMP @draw_pikachu_dead

@draw_charmander_dead:
	JSR charmander_knockout
	JMP @exit_dead_draw

@draw_bulbasaur_dead:
	JSR bulbasaur_dead
	JMP @exit_dead_draw

@draw_pikachu_dead:
	JSR pikachu_knockout

@exit_dead_draw:
	RTS


; ----------- DAMAGE DRAW -----------

draw_damaged_pokemon
	; LDA damage_timer,X
	; BEQ @no_damage

	; Damage active for Player 1
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_damage

	CMP #BULBASAUR
	BEQ @draw_bulbasaur_damage

	JMP @draw_pikachu_damage

@draw_charmander_damage
	JSR charmander_damaged
	RTS

@draw_bulbasaur_damage
	JSR bulbasaur_damaged
	RTS

@draw_pikachu_damage
	JSR pikachu_damaged
	RTS

@no_damage:
	RTS


draw_attack
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_attack

	CMP #BULBASAUR
	BEQ @draw_bulbasaur_attack

	JMP @draw_pikachu_attack

@draw_charmander_attack:
	JSR charmander_attack
	RTS

@draw_bulbasaur_attack:
	JSR bulbasaur_attack
	RTS

@draw_pikachu_attack:
	JSR pikachu_attack
	RTS

