; .segment  "ZEROPAGE"
; .importzp p1_animation_state, alive_mon, tile_bit_mask


; .segment "CODE"
; .import pikachu_walk_1, pikachu_walk_2, pikachu_idle, pikachu_jump
; .import pikachu_damaged, pikachu_attack, pikachu_knockout, pikachu_projectile, set_palette_pikachu

; .export pikachu_walk_cycle, pikachu_jump_cycle, pikachu_attack_cycle
; .export pikachu_damaged_cycle, pikachu_knockout_cycle, pikachu_projectile_cycle


pikachu_walk_cycle
	JSR set_palette_pikachu

	LDA p1_animation_state
	BNE +
	
	; @first_walk:
	JSR pikachu_walk_2

	JMP ++
	
+
	JSR pikachu_walk_1

++
	RTS


pikachu_jump_cycle
	JSR set_palette_pikachu

	LDA p1_animation_state
	BNE +
	
	@idle:
	JSR pikachu_idle

	JMP ++
	
+
	JSR pikachu_jump

++
	RTS


pikachu_attack_cycle
	JSR set_palette_pikachu

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR pikachu_idle

	JMP ++
	
+
	JSR pikachu_attack

++
	RTS


pikachu_damaged_cycle
	JSR set_palette_pikachu

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR pikachu_idle

	JMP ++
	
+
	JSR pikachu_damaged

++
	RTS


pikachu_knockout_cycle
	JSR set_palette_pikachu

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR pikachu_idle

	JMP ++
	
+
	JSR pikachu_knockout

++
	RTS


pikachu_projectile_cycle ; Change
	JSR set_palette_pikachu

	LDA alive_mon,Y
	AND #ATTACK_TOGGLE
	BEQ +  ; Draw downward
	
	; Draw upward
	LDA tile_bit_mask
	EOR #@10000000
	STA tile_bit_mask
	
+
	JSR pikachu_projectile
	RTS
