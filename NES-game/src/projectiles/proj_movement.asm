; .segment  "ZEROPAGE"

	.DEF CHARMANDER_SPEED,   3
	.DEF BULBASAUR_SPEED_X,  2
	.DEF BULBASAUR_SPEED_Y,  2
	.DEF PIKACHU_SPEED,      5

; .importzp projectile_x, projectile_y, active_mon, alive_mon, projectile_ceil, projectile_floor


; .segment "CODE"
; .export update_charmander_projectile, update_bulbasaur_projectile, update_pikachu_projectile


update_charmander_projectile
	; Check p1 -> right / p2 -> left
	CPX #0 ; Check for P1 / P2
	BNE @flip_movement

	JSR move_projectile_right
	JMP @exit_charmander_projectile

	@flip_movement:
	JSR move_projectile_left

	@exit_charmander_projectile:
	RTS


update_bulbasaur_projectile
	; Vertical component
	LDA alive_mon,Y
	AND #ATTACK_TOGGLE
	BEQ @move_leaf_down

	@move_leaf_up:
	JSR move_projectile_up

	LDA projectile_y,X
	CMP projectile_ceil,X
	BCS @horizontal_leaf

	LDA alive_mon,Y
	EOR #ATTACK_TOGGLE
	STA alive_mon,Y

	@move_leaf_down:
	JSR move_projectile_down

	LDA projectile_y,X
	CMP projectile_floor,X
	BCC @horizontal_leaf

	LDA alive_mon,Y
	EOR #ATTACK_TOGGLE
	STA alive_mon,Y
	
	; Horizontal component
	@horizontal_leaf:
	; Check p1 -> right / p2 -> left
	CPX #0 ; Check for P1 / P2
	BNE @flip_movement_bulbasaur_projectile

	JSR move_projectile_right
	JMP @exit_bulbasaur_projectile

	@flip_movement_bulbasaur_projectile:
	JSR move_projectile_left
	
	@exit_bulbasaur_projectile:
	RTS


update_pikachu_projectile
	LDA alive_mon,Y
	AND #ATTACK_TOGGLE
	BEQ @move_shock_down

	@move_shock_up:
	JSR move_projectile_up
	JMP @exit_pikachu_projectile

	@move_shock_down:
	JSR move_projectile_down

	@exit_pikachu_projectile:
	RTS


move_projectile_left
	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @move_bulbasaur_projectile_left

	@move_charmander_projectile_left:
	LDA projectile_x,X
	SEC
	SBC #CHARMANDER_SPEED
	STA projectile_x,X

	JMP @exit_proj_left

	@move_bulbasaur_projectile_left:
	LDA projectile_x,X
	SEC
	SBC #BULBASAUR_SPEED_X
	STA projectile_x,X

	@exit_proj_left:
	RTS


move_projectile_right
	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @move_bulbasaur_projectile_right

	@move_charmander_projectile_right:
	LDA projectile_x,X
	CLC
	ADC #CHARMANDER_SPEED
	STA projectile_x,X

	JMP @exit_proj_right

	@move_bulbasaur_projectile_right:
	LDA projectile_x,X
	CLC
	ADC #BULBASAUR_SPEED_X
	STA projectile_x,X

	@exit_proj_right:
	RTS


move_projectile_down
	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @move_bulbasaur_projectile_down

	@move_pikachu_projectile_down:
	LDA projectile_y,X
	CLC
	ADC #PIKACHU_SPEED
	STA projectile_y,X

	JMP @exit_proj_down

	@move_bulbasaur_projectile_down:
	LDA projectile_y,X
	CLC
	ADC #BULBASAUR_SPEED_Y
	STA projectile_y,X

	@exit_proj_down:
	RTS


move_projectile_up
	LDA active_mon,X
	CMP #BULBASAUR
	BEQ @move_bulbasaur_projectile_up

	@move_pikachu_projectile_up:
	LDA projectile_y,X
	SEC
	SBC #PIKACHU_SPEED
	STA projectile_y,X

	JMP @exit_proj_up

	@move_bulbasaur_projectile_up:
	LDA projectile_y,X
	SEC
	SBC #BULBASAUR_SPEED_Y
	STA projectile_y,X

	@exit_proj_up:
	RTS
