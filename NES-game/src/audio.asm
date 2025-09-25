; .segment "ZEROPAGE"
; Variables
	.ENUM $10
		landing_thud_active,	1
		landing_thud_timer,		1
	.ENDE
; landing_thud_active: .res 1
; landing_thud_timer:  .res 1
; .importzp frame_counter, music_index, note_timer


; .segment"CODE"
; .export init_BGM, play_jump_sfx, update_music, play_damage_sfx, play_death_sfx, play_landing_thud, update_landing_thud, play_attack_sfx, play_switch_sfx
; .import pallet_lengths, pallet_notes


init_BGM
	LDA #@00001111       ; Enable Pulse 1 + 2 + Triangle + Noise
	STA SOUND_CTRL

	LDA #$00
	STA music_index

	JSR play_next_note   ; Start first note immediately
	RTS


; USING PULSE 2
play_jump_sfx
	; Pulse 2 jump sound
	LDA #@10010110      ; 50@ duty, constant volume = 15
	STA $4004           ; Pulse 2 control

	LDA #$E8            ; Lower pitch
	STA $4006           ; Timer low byte

	LDA #@00000000
	STA $4007           ; Reload (short note)

	RTS


; USING NOISE
play_damage_sfx
	; Enable noise channel
	LDA #@10001111       ; Constant volume = 15, no sweep
	STA $400C            ; Noise channel volume

	LDA #$00             ; Noise period (lower = higher pitch)
	STA $400E

	LDA #@00001111       ; Short duration
	STA $400F            ; Start noise

	RTS



play_landing_thud
	; Initialize triangle thud
	LDA #1
	STA landing_thud_active

	LDA #5              ; 5-frame descent
	STA landing_thud_timer

	; Set linear counter with control flag
	LDA #@10000010      ; Bit 7 = 1 (disable length counter), reload = 2
	STA $4008

	; Start with a higher pitch (low timer = high frequency)
	LDA #$FF            ; Adjust this for desired starting pitch
	STA $400A

	LDA #@00000000      ; Timer high = 0, triggers reload
	STA $400B

	RTS


update_landing_thud
	; Call this every frame from your sound update routine
	LDA landing_thud_active
	BEQ +           ; Do nothing if not active

	; Gradually deepen pitch
	LDA $400A
	CLC
	ADC #$10            ; Increase timer (lower pitch)
	STA $400A

	; Keep $400B write to retrigger linear reload
	LDA #@00001000
	STA $400B

	; Decrease the frame timer
	DEC landing_thud_timer
	BNE +

	; Disable triangle channel (let it shut down naturally)
	LDA #0
	STA landing_thud_active
	STA $4008
	STA $400A
	STA $400B

+	RTS


play_next_note
	LDX music_index
	LDA pallet_notes,X
	BEQ @restart

	STA $4002          ; Timer low
	
	LDA #$00
	STA $4003          ; Trigger reload
	
	LDA #@10010101     ; Volume = 1, 50@ duty, constant volume
	STA $4000

	LDA pallet_lengths,X
	STA note_timer

	INC music_index
	RTS

@restart:
	LDA #$00
	STA music_index
	JMP play_next_note


play_death_sfx
	; Death = lower, heavier noise with much longer sustain

	LDA #@10001111       ; Constant volume = 15
	STA $400C            ; Noise control

	LDA #@00101100       ; Lower-pitched noise (period = $0C)
	STA $400E            ; Frequency + mode

	LDA #@01111111       ; Longest possible duration
	STA $400F            ; Length counter

	RTS


play_attack_sfx
	; Pulse 1 "pew" sound effect
	LDA #@10010111      ; 50@ duty, constant volume = 7  
	STA $4000           ; Pulse 1 control

	LDA #$C8            ; Set initial frequency (low timer = high pitch)
	STA $4002           ; Timer low byte

	LDA #@00000000      ; Trigger reload
	STA $4003           ; Timer high byte (also triggers reload)

	RTS


play_switch_sfx
	LDA #@10001111        ; Constant volume = 15 (full volume)
	STA $400C             ; Noise control (set volume)
	
	LDA #@00100000        ; Medium-pitched noise (period = $20 for smoother swoosh)
	STA $400E             ; Frequency + mode (set pitch and noise type)
	
	LDA #@01111000        ; Longer duration (sustained swoosh)
	STA $400F             ; Length counter (control how long the sound lasts)
	RTS

update_music
	DEC note_timer
	BNE +
	JSR play_next_note
+	RTS

