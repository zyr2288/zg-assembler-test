; .segment  "ZEROPAGE"
; .importzp p1_animation_state, tile_bit_mask, flip_state, frame_counter, temp1, temp2


; .segment "CODE"
; .import bulbasaur_walk_1, bulbasaur_walk_2, bulbasaur_idle, bulbasaur_jump
; .import bulbasaur_damaged, bulbasaur_attack, bulbasaur_dead, bulbasaur_projectile, set_palette_bulbasaur

; .export bulbasaur_walk_cycle, bulbasaur_jump_cycle, bulbasaur_attack_cycle
; .export bulbasaur_damaged_cycle, bulbasaur_dead_cycle, bulbasaur_projectile_cycle


bulbasaur_walk_cycle
	JSR set_palette_bulbasaur

	LDA p1_animation_state
	BNE +
	
	JSR bulbasaur_walk_2

	JMP ++
	
+
	JSR bulbasaur_walk_1

++
	RTS


bulbasaur_jump_cycle
	JSR set_palette_bulbasaur

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR bulbasaur_idle

	JMP ++
	
+
	JSR bulbasaur_jump

++
	RTS


bulbasaur_attack_cycle
	JSR set_palette_bulbasaur

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR bulbasaur_idle

	JMP ++
	
+
	JSR bulbasaur_attack

++
	RTS


bulbasaur_damaged_cycle
	JSR set_palette_bulbasaur

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR bulbasaur_idle

	JMP ++
	
+
	JSR bulbasaur_damaged

++
	RTS


bulbasaur_dead_cycle
	JSR set_palette_bulbasaur

	LDA p1_animation_state
	BNE +
	
	; @idle:
	JSR bulbasaur_idle

	JMP ++
	
+
	JSR bulbasaur_dead

++
	RTS


bulbasaur_projectile_cycle
	JSR set_palette_bulbasaur

	STY temp2
	LDY temp1

	LDA flip_state
	BNE +
	
; @Normal
	LDA frame_counter
	CMP #$1B           ;  Compare every 27 frames
	BCS .state_4

	LDA frame_counter
	CMP #$12           ;  Compare every 18 frames
	BCS .state_3

	LDA frame_counter
	CMP #$09           ;  Compare every 9 frames
	BCS .state_2
	
	JMP .state_1

+
	LDA frame_counter
	CMP #$1B           ;  Compare every 27 frames
	BCS .state_1

	LDA frame_counter
	CMP #$12           ;  Compare every 18 frames
	BCS .state_2

	LDA frame_counter
	CMP #$09           ;  Compare every 9 frames
	BCS .state_3
	
	JMP .state_4

.state_4  ;  Horizontally flipped
	LDA tile_bit_mask  ;  Enable Horizontal Flip
	CLC
	ADC #$40
	STA tile_bit_mask

	JSR bulbasaur_projectile
	
	LDA tile_bit_mask  ;  Disable Horizontal Flip
	SEC
	SBC #$40
	STA tile_bit_mask
	
	JMP +++

.state_3  ;  Vertically and Horizontally flipped
	LDA tile_bit_mask  ;  Enable Vertical & Horizontal Flip
	CLC
	ADC #$C0
	STA tile_bit_mask

	JSR bulbasaur_projectile
	
	LDA tile_bit_mask  ;  Disable Vertical & Horizontal Flip
	SEC
	SBC #$C0
	STA tile_bit_mask

	JMP +++

.state_2  ;  Vertically flipped
	LDA tile_bit_mask  ;  Enable Vertical Flip
	CLC
	ADC #$80
	STA tile_bit_mask

	JSR bulbasaur_projectile
	
	LDA tile_bit_mask  ;  Disable Vertical Flip
	SEC
	SBC #$80
	STA tile_bit_mask

	JMP +++

.state_1  ;  Normal
	JSR bulbasaur_projectile

+++
	LDY temp2

	RTS
