; .segment  "ZEROPAGE"
; .importzp flip_state, prev_pads, pads, active_mon, alive_mon

; .segment "CODE"
; .export update_players
; .import check_jump, jump, move_horizontally, switch_pokemon, set_attack, validate_offset_mult, validate_offset_div, draw_player, play_death_sfx

update_player
	; --- First, check if Pokémon is dead ---
	JSR check_jump
	BEQ @check_dead

	JSR jump
	; @check_dead
	; ; --- If NOT dead normal controls ---
	; JSR validate_offset_mult

	; LDA alive_mon,Y
	; AND #HEALTH

	; PHP
	; PHA
	; JSR validate_offset_div
	; PLA
	; PLP

	; BEQ @check_switch_input

@check_dead
	; -- Check if Pokémon has 0 health (dead) --
	JSR validate_offset_mult
	LDA alive_mon,Y
	AND #@00000011          ; Mask bits 1–0 (Health)
	BNE @check_horizontal_input  ; If not zero → not dead → continue

	; -- Check if death sound was already played --
	LDA alive_mon,Y
	AND #@10000000          ; Check bit 7 (death sound played)
	BNE @check_switch_input ; Already played → skip

	; -- Play death sound now --
	JSR play_death_sfx

	; -- Set "death sound played" flag (bit 7) --
	LDA alive_mon,Y
	ORA #@10000000
	STA alive_mon,Y

	JMP @check_switch_input


@check_horizontal_input
	; on right / left call horizontal
	LDA pads,X
	AND #(BTN_LEFT | BTN_RIGHT)
	BEQ @check_attack

	JSR move_horizontally

	; initiate attack
@check_attack
	; on B start attack
	JSR validate_offset_mult

	LDA alive_mon,Y
	AND #ATTACK
	BNE @check_jump_input

	; Rising edge detection
	LDA prev_pads,X
	AND #BTN_B
	BNE @check_jump_input  ; was pressed last frame

	LDA pads,X
	AND #BTN_B
	BEQ @check_jump_input  ; not pressed this frame

	; Trigger attack
	JSR set_attack


@check_jump_input
	; on A call jump
	LDA pads,X
	AND #BTN_A
	BEQ @check_switch_input

	JSR check_jump
	BNE @check_switch_input

	JSR jump

@check_switch_input
	; on SELECT switch mons
	JSR validate_offset_mult
	
	LDA alive_mon,Y
	AND #ATTACK

	PHP
	PHA
	JSR validate_offset_div
	PLA
	PLP
	BNE +

	LDA pads,X
	AND #BTN_SELECT
	BEQ +

	JSR check_jump
	BNE +

	JSR switch_pokemon

+
	RTS


update_player_setup
	TXA
	STA flip_state
	
	TYA   ; Sprite draw offset stored in stack
	PHA

	LDY active_mon,X  ;  Set active pokemon to RegY
	JSR validate_offset_mult
	JSR update_player

	PLA
	TAY   ; Sprite draw offset restored from stack

	JSR draw_player
	RTS


update_players
	; Player 1
	LDX #$00
	JSR update_player_setup

	; Player 2
	LDX #$01  ;  (Flipped)
	JSR update_player_setup

	RTS

