; .segment  "ZEROPAGE"
; .importzp sprite_x, sprite_y, projectile_x, projectile_y, sprite_x_vels, pads, prev_pads, projectile_ceil, projectile_floor
; .importzp  alive_mon, active_mon, jump_velocity, jump_start_vels, frame_counter, attack_anim_timer

; .segment "CODE"
; .import play_jump_sfx, play_landing_thud, play_attack_sfx, play_switch_sfx
; .export switch_pokemon, move_horizontally, set_attack, jump, check_jump, validate_offset_mult, validate_offset_div


switch_pokemon
	; --- Unified SELECT press and skip dead Pokémon logic ---

	; Check if SELECT button is pressed NOW
	LDA pads,X
	AND #BTN_SELECT
	BEQ @exit_switch      ; Not pressing SELECT now, exit

	; Check if SELECT button was pressed LAST frame
	LDA prev_pads,X
	AND #BTN_SELECT
	BNE @exit_switch      ; Already pressed last frame (holding down), exit

@try_next_pokemon:
	; --- Increment active_mon ---
	INC active_mon,X

	; --- Wrap around if overflowed ---
	LDA active_mon,X
	CMP #NUM_POKEMON
	BCC @check_alive

	; Reset to 0 if exceeded
	LDA #$00
	STA active_mon,X

@check_alive:
	; --- Now check if new active_mon is alive ---

	; Correct Y index for player
	LDY active_mon,X
	CPX #$01
	BNE @correct_alive_index_switch

	; If player 2, shift to correct alive_mon
	TYA
	CLC
	ADC #$03
	TAY

@correct_alive_index_switch:
	LDA alive_mon,Y
	AND #@00000011
	BEQ @try_next_pokemon  ; If dead, skip again

	; Found alive Pokémon!
	JSR play_switch_sfx
@exit_switch:
	RTS


set_attack
	; X = jugador que lanza el ataque (0 = P1, 1 = P2)

	JSR play_attack_sfx

	; Obtener índice de Pokémon activo
	LDY active_mon,X
	JSR validate_offset_mult

	; Activar bit 3 del alive_mon para lanzar proyectil
	LDA alive_mon,Y
	ORA #(ATTACK | ATTACK_TOGGLE)
	STA alive_mon,Y

	; Posicionar el proyectil
	; --- X ---
	LDA sprite_x,X
	CPX #$00
	BEQ @p1_offset
	; Player 2 → proyectil a la izquierda
	SEC
	SBC #$10     ; 16 px a la izquierda
	JMP @set_x

@p1_offset:
	CLC
	ADC #$10     ; 16 px a la derecha

@set_x:
	STA projectile_x,X

	; --- Y ---
	LDA sprite_y,X
	CLC
	ADC #$04     ; Un poco más abajo (centro vertical)
	STA projectile_y,X
	CLC
	ADC #8
	STA projectile_floor,X

	LDA sprite_y,X
	SEC
	SBC #$14
	STA projectile_ceil,X

	; --- Start attack animation ---
	LDA #HALF_CYCLE-6
	STA attack_anim_timer,X

	RTS




move_horizontally ; X player counter
	LDA pads,X
	AND #BTN_LEFT
	BNE move_left  ;  MAY NOT WORK; MIGHT CHANGE TO VALIDATION AND JSR

	LDA pads,X
	AND #BTN_RIGHT
	BNE move_right ;  MAY NOT WORK; MIGHT CHANGE TO VALIDATION AND JSR

	RTS


move_right ; X player counter / Y active_mon
	LDY active_mon,X
	LDA sprite_x,X
	CLC
	ADC sprite_x_vels,Y
	STA sprite_x,X

	; JSR check_wrap
	JSR clamp_sprite_x_within_bounds

	RTS


move_left ; X player counter / Y active_mon
	LDY active_mon,X
	LDA sprite_x,X
	SEC
	SBC sprite_x_vels,Y
	STA sprite_x,X

	; Check if underflow happened (C flag clear)
	BCS @no_underflow

	; If carry clear, it underflowed -> Clamp to 0
	LDA #$00
	STA sprite_x,X

	@no_underflow:
	RTS


clamp_sprite_x_within_bounds
	; Clamp sprite_x between 0 and $F0

	LDA sprite_x,X
	CMP #$F0
	BCC @check_underflow  ; If less than $F0, might have underflow

	; If sprite_x >= $F0, clamp to $F0
	LDA #$F0
	STA sprite_x,X
	RTS

	@check_underflow:
	LDA sprite_x,X
	CMP #$00
	BCS +  ; If sprite_x >= 0, it's fine

	; If sprite_x < 0 (underflow), clamp to $00
	LDA #$00
	STA sprite_x,X
+	RTS


jump
	; Check if already jumping
	JSR check_jump
	BNE @continue_jump

	; --- Start a new jump ---
	JSR play_jump_sfx
	JSR validate_offset_mult

	; Set "jumping" (bit 5) and "going up" (bit 4) flags
	LDA alive_mon,Y
	ORA #(JUMP | JUMP_TOGGLE)
	STA alive_mon,Y

	JSR validate_offset_div

	; Initialize jump velocity from jump_start_vels pool
	; LDY active_mon,X
	LDA jump_start_vels,Y
	STA jump_velocity,X

@continue_jump:
	; --- Continue the current jump ---
	JSR validate_offset_mult

	; Check if still moving upward
	LDA alive_mon,Y
	AND #JUMP_TOGGLE

	PHP
	PHA
	JSR validate_offset_div
	PLA
	PLP

	; Branch depending on movement phase
	BNE @apply_upward_movement
	BEQ @apply_downward_movement

@apply_upward_movement:
	JSR move_up
	JMP +

@apply_downward_movement:
	JSR move_down

+	RTS


check_jump        ; Y (player counter * active_mon)
	;  check if jumping
	JSR validate_offset_mult

	LDA alive_mon,Y
	AND #JUMP

	PHP
	PHA
	JSR validate_offset_div
	PLA
	PLP
	
	RTS


move_up
	; Apply upward movement to sprite
	LDA sprite_y,X
	CLC
	ADC jump_velocity,X
	STA sprite_y,X

	; Apply gravity if odd frame
	LDA jump_velocity,X
	CLC
	ADC #$01
	STA jump_velocity,X

	@no_gravity:
	; Check if upward velocity reached 0
	LDA jump_velocity,X
	BPL @begin_fall

	RTS

	@begin_fall:
	; Switch from going up to falling
	JSR validate_offset_mult
	
	LDA alive_mon,Y
	EOR #JUMP_TOGGLE
	STA alive_mon,Y
	
	JSR validate_offset_div

	RTS


move_down
	; Apply downward movement to sprite
	LDA sprite_y,X
	CLC
	ADC jump_velocity,X
	STA sprite_y,X

	; Slower gravity: every 2 frames
	LDA frame_counter
	AND #@00000001   ; Check if frame is odd
	BEQ @no_gravity_down

	; Apply gravity if odd frame
	LDA jump_velocity,X
	CLC
	ADC #$01
	STA jump_velocity,X

@no_gravity_down
	; Check if landed
	LDA sprite_y,X
	CMP #$A0
	BCC @exit_fall

	; Landed
	LDA #$A0
	STA sprite_y,X

	; Clear "jumping" bit
	JSR validate_offset_mult

	LDA alive_mon,Y
	EOR #(JUMP | JUMP_TOGGLE)
	STA alive_mon,Y
	
	JSR validate_offset_div

	; Reset vertical velocity
	LDA #$00
	STA jump_velocity,X

	JSR play_landing_thud

@exit_fall
	RTS



multiply_alive_move_offset_3
	TYA
	CLC
	ADC #$03
	TAY
	RTS

validate_offset_mult
	CPX #$00           ;   Check if p1 / p2
	BEQ @exit_mult_val
	CPY #NUM_POKEMON   ;   Check Y > 3
	BCS @exit_mult_val
	
	JSR multiply_alive_move_offset_3

	@exit_mult_val:
	RTS


divide_alive_move_offset_3
	TYA
	SEC
	SBC #$03
	TAY

	RTS


validate_offset_div
	CPY #NUM_POKEMON
	BCC @exit_div_val    ;   Y <= 2
	
	JSR divide_alive_move_offset_3

	@exit_div_val:
	RTS
