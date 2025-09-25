; .segment  "ZEROPAGE"
; .importzp temp1, pads, prev_pads


; .segment "CODE"
; .export read_controllers


read_controllers
	; First, copy current pads to prev_pads BEFORE updating them
	LDA pads
	STA prev_pads
	LDA pads + 1
	STA prev_pads + 1

	; Now read new inputs
	LDA #$01
	STA CONTROLLER1
	LDA #$00
	STA CONTROLLER1
	
	JSR .read_controller1
	LDA temp1
	STA pads

	JSR .read_controller2

	LDX #$01
	LDA temp1
	STA pads,X
	DEX

	RTS

.read_controller1
	LDX #8
	LDA #$00
	STA temp1 ; Store controller inputs

-	LDA CONTROLLER1
	LSR
	ROL temp1
	DEX
	BNE -

	RTS

.read_controller2
	LDX #8
	LDA #$00
	STA temp1 ; Store controller inputs
-	LDA CONTROLLER2
	LSR
	ROL temp1
	DEX
	BNE -
	RTS