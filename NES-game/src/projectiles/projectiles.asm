; .segment  "ZEROPAGE"

	.DEF FLOOR, $A0 + 16

; .importzp sprite_x, sprite_y, projectile_x, projectile_y, flip_state, active_mon, alive_mon, temp1, temp2


; .segment "CODE"
; .export update_projectiles
; .import Increment_RegY_4, validate_offset_mult
; .import charmander_projectile_cycle, bulbasaur_projectile_cycle, pikachu_projectile_cycle
; .import update_charmander_projectile, update_bulbasaur_projectile, update_pikachu_projectile


update_projectile
	; Check what to update
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @charmander_projectile_update

	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @bulbasaur_projectile_update

	; Pikachu projectile
	JSR update_pikachu_projectile
	JMP @exit_update_projectile

	; Charmander projectile
	@charmander_projectile_update:
	JSR update_charmander_projectile
	JMP @exit_update_projectile

	; Bulbasaur projectile
	@bulbasaur_projectile_update:
	JSR update_bulbasaur_projectile
	JMP @exit_update_projectile

	@exit_update_projectile:
	RTS


update_projectile_setup
	TXA
	STA flip_state
	
	TYA   ; Sprite draw offset stored in stack
	PHA

	LDY active_mon,X  ;  Set active pokemon projectile to RegY
	JSR validate_offset_mult
	
	JSR update_projectile

	PLA
	TAY   ; Sprite draw offset restored from stack

	JSR draw_projectile
	RTS


check_firing
	; Check if attack incoming first else clear OAM of this sprite
	TYA
	PHA  ;  Store Mem Offset
	
	LDY active_mon,X
	JSR validate_offset_mult
	
	JSR check_bounds

	LDA alive_mon,Y
	AND #ATTACK
	BEQ @clear_projectile

	PLA  ;  Retrieve Mem Offset
	TAY

	JSR update_projectile_setup
	JMP @exit_check_firing

	@clear_projectile:
	PLA
	TAY

	JSR clear_projectile_oam

	@exit_check_firing:
	RTS


update_projectiles
	; Player 1
	LDX #$00
	JSR check_firing

	; Player 2
	LDX #$01  ;  (Flipped)
	JSR check_firing  ;  Prob go straight into update projectiles

	RTS


check_bounds
	LDA active_mon,X
	CMP #PIKACHU
	BEQ @check_vertical_boundary
	
@check_horizontal_boundary:
	JSR bound_horizontal

	JMP @exit_boundary_check

@check_vertical_boundary:
	JSR  bound_vertical

@exit_boundary_check:
	RTS


bound_vertical
	LDA alive_mon,Y
	AND #ATTACK_TOGGLE
	BEQ @check_down

@check_top:
	LDA projectile_y,X
	CMP #8
	BCS @exit_vertical_check

	; Flip leaf/shock direction (toggle bit)
	LDA alive_mon,Y
	EOR #ATTACK_TOGGLE
	STA alive_mon,Y

	; Reflect X for effect (leaf/shock wave bounce)
	LDA #$FF
	SEC
	SBC projectile_x,X
	STA projectile_x,X

	JMP @exit_vertical_check

@check_down:
	LDA projectile_y,X
	CLC
	ADC #16
	CMP #FLOOR
	BCC @exit_vertical_check

	; Clear attack bits (turn off projectile)
	LDA alive_mon,Y
	AND #@11110011
	STA alive_mon,Y

	; Fully remove projectile from screen (fix lingering damage bug)
	LDA #$FF
	STA projectile_x,X
	STA projectile_y,X

@exit_vertical_check:
	RTS



bound_horizontal
	CPX #0
	BNE @check_left_border

	LDA active_mon,X
	CMP #CHARMANDER
	BNE @bulbasaur_projectile_check

	; Check Charmander's projectile P1
	@charmander_projectile_check:
	LDA projectile_x,X
	CLC
	ADC #16
	CMP #$F8
	BCS deactivate_attack
	
	JMP @exit_horizontal_bound
	
	; Check Bulbasaur's projectile P1
	@bulbasaur_projectile_check:
	LDA projectile_x,X
	CLC
	ADC #8
	CMP #$F8
	BCS deactivate_attack

	JMP @exit_horizontal_bound

	; Check projectile P2
	@check_left_border:
	LDA projectile_x,X
	CMP #$08
	BCC deactivate_attack

	@exit_horizontal_bound:
	RTS


deactivate_attack
	; Clear projectile bit in alive_mon
	LDA alive_mon,Y
	AND #@11110011
	STA alive_mon,Y

	; Move projectile off screen
	LDA #$FF
	STA projectile_x,X
	STA projectile_y,X
	RTS


draw_projectile
	STX temp1  ;  Store Player
	STY temp2  ;  Store Memory Offset

	; Set Projectile X for draw
	LDA sprite_x,X
	PHA
	LDA projectile_x,X
	STA sprite_x,X

	; Set Projectile Y for draw
	LDA sprite_y,X
	PHA
	LDA projectile_y,X
	STA sprite_y,X

	; Select projectile
	LDA active_mon,X
	CMP #CHARMANDER
	BEQ @draw_charmander_projectile

	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @draw_bulbasaur_projectile
	
	JMP @draw_pikachu_projectile


	; Charmander Projectile
@draw_charmander_projectile:
	JSR charmander_projectile_cycle
	JMP @exit_projectile_draw_selection


	; Bulbasaur Projectile
@draw_bulbasaur_projectile:
	JSR bulbasaur_projectile_cycle
	JMP @exit_projectile_draw_selection


	; Pikachu Projectile
@draw_pikachu_projectile:
	LDY active_mon,X
	JSR validate_offset_mult
	JSR pikachu_projectile_cycle

@exit_projectile_draw_selection:
	LDX temp1

	; Reset Sprite Y
	PLA
	STA sprite_y,X

	; Reset Sprite X
	PLA
	STA sprite_x,X

	RTS


clear_projectile_oam
	JSR clear_tile

	LDA active_mon,X  ;  Continue if projectile not Bulbasaur's
	CMP #BULBASAUR
	BEQ @exit_clear_oam

	JSR Increment_RegY_4
	JSR clear_tile

	@exit_clear_oam:  ;  Mem offset has to be increased even without draw to appropriately clear section of OAM
	JSR Increment_RegY_4
	RTS


clear_tile
	LDA #$F8
	STA $0200,Y      ; Y position

	LDA #$00
	STA $0201,Y      ; tile number
	STA $0202,Y      ; attributes
	STA $0203,Y      ; X position

	RTS
