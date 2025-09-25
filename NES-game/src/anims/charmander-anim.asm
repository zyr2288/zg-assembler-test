; .segment  "ZEROPAGE"
; .importzp p1_animation_state, tile_bit_mask, flip_state


; .segment "CODE"
; .import charmander_walk_1, charmander_walk_2, charmander_idle, charmander_jump,  set_palette_charmander
; .import charmander_damaged, charmander_attack, charmander_knockout, charmander_projectile_1, charmander_projectile_2

; .export charmander_walk_cycle, charmander_jump_cycle, charmander_attack_cycle
; .export charmander_damaged_cycle, charmander_knockout_cycle, charmander_projectile_cycle


charmander_walk_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
; @first_walk:
	JSR charmander_walk_2

	JMP ++
	
+
	JSR charmander_walk_1

++
	RTS


charmander_jump_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR charmander_idle

	JMP ++
	
+
	JSR charmander_jump

++
	RTS


charmander_attack_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR charmander_idle

	JMP ++
	
+
	JSR charmander_attack

++
	RTS


charmander_damaged_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR charmander_idle

	JMP ++
	
+
	JSR charmander_damaged

++
	RTS


charmander_knockout_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR charmander_idle

	JMP ++
	
+
	JSR charmander_knockout

++
	RTS


charmander_projectile_cycle
	JSR set_palette_charmander

	LDA p1_animation_state
	BNE +
	
	; @second_projectile:
	JSR charmander_projectile_2

	JMP ++
	
+
	JSR charmander_projectile_1

++
	RTS
