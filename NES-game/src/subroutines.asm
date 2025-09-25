; .segment  "ZEROPAGE"
; .importzp sprite_x, sprite_y, tile_bit_mask, flip_state, p1_tile_array, pads, active_mon, damage_timer
; .importzp index_sprite, temp1, temp2, p1_animation_state, frame_counter, attack_anim_timer, attack_anim_timer, attacking_state


; .segment  "CODE"
; .export draw_2x2, draw_2x1, draw_1x1, Increment_RegY_16, Increment_RegY_4, update_animation_delay, shift_down, shift_up


update_animation_delay
; === Damage timer countdown ===
	LDX #$00
@update_damage_timer
	LDA damage_timer,X
	BEQ @next_damage_timer

	DEC damage_timer,X

@next_damage_timer
	INX
	CPX #NUM_PLAYERS
	BNE @update_damage_timer

; === Attack animation timers ===
	LDX #$00

@update_attack_timer
	LDA attack_anim_timer,X
	BEQ @next_attack

	DEC attack_anim_timer,X

	@next_attack:
	INX
	CPX #NUM_PLAYERS
	BNE @update_attack_timer

; === Update frame counter ===
	@skip_frame_reset:
	INC frame_counter
	LDA frame_counter
	CMP #CYCLE
	BNE @skip_reset1

	; Toggle posture (0 <-> 1)
	LDA p1_animation_state
	EOR #$01
	STA p1_animation_state

	LDA #0
	STA frame_counter
	
	@skip_reset1:
	LDA frame_counter
	CMP #HALF_CYCLE
	BNE @skip_reset2

	; Toggle posture (0 <-> 1)
	LDA p1_animation_state
	EOR #$01
	STA p1_animation_state
	
@skip_reset2
	RTS


draw_2x2
	LDY temp1  ;  Load Player on RegY

	LDX #$00   ;  Tile Array Index

	JSR draw_2x1
	JSR shift_down

	JSR draw_2x1
	JSR shift_up

	LDY temp2  ;  Restore Mem Offset

	RTS

; ------------- SET LDX #$00 IF USING IT BY ITSELF --------------
draw_2x1
	LDA flip_state
	BNE @invert_tiles

	;--------------------------------- Normal Row tiles
	
	LDA p1_tile_array,X
	STA index_sprite
	
	JSR draw_1x1
	JSR shift_right
	INX

	LDA p1_tile_array,X
	STA index_sprite
	JSR draw_1x1
	INX

	JSR shift_left
	LDA flip_state
	BEQ @continue

	;--------------------------------- Mirrored Row tiles

	@invert_tiles
	  LDA tile_bit_mask  ;  Enable Horizontal Flip
	  CLC
	  ADC #$40
	  STA tile_bit_mask

	  JSR shift_right
	  LDA p1_tile_array,X
	  STA index_sprite

	  JSR draw_1x1
	  INX

	  JSR shift_left
	  LDA p1_tile_array,X

	  STA index_sprite
	  JSR draw_1x1
	  INX

	  LDA tile_bit_mask  ;  Disable Horizontal Flip
	  SEC
	  SBC #$40
	  STA tile_bit_mask

	@continue:
	  RTS

draw_1x1  ; RegY shows p1/p2 | RegX Mem Offset
	TXA                   ; Store tile arrary index
	PHA
	LDX temp2             ; Load Memory offset

	LDA sprite_y,Y       ; Y position
	STA $0200,X

	LDA index_sprite      ; Tile Index
	STA $0201,X

	LDA tile_bit_mask     ; Attribte bitmask
	STA $0202,X

	LDA sprite_x,Y       ; X position
	STA $0203,X

	JSR Increment_RegX_4  ; Increment Memory Offset
	STX temp2
	PLA
	TAX                   ; Return Tile array index to RegX

	RTS

Increment_RegX_4
	INX
	INX
	INX
	INX
	RTS

Increment_RegY_4
	INY
	INY
	INY
	INY
	RTS

Increment_RegY_16
	JSR Increment_RegY_4
	JSR Increment_RegY_4
	JSR Increment_RegY_4
	JSR Increment_RegY_4
	RTS

shift_right
	LDA sprite_x,Y
	CLC
	ADC #$08
	STA sprite_x,Y
	RTS

shift_left
	LDA sprite_x,Y
	SEC
	SBC #$08
	STA sprite_x,Y
	RTS

shift_down
	LDA sprite_y,Y
	CLC
	ADC #$08
	STA sprite_y,Y
	RTS

shift_up
	LDA sprite_y,Y
	SEC
	SBC #$08
	STA sprite_y,Y
	RTS