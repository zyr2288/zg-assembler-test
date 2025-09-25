reset_handler
	SEI
	CLD
	LDX #$40
	STX $4017
	LDX #$FF
	TXS
	INX
	STX $2000      ; Disable NMI
	STX $2001      ; Disable rendering
	STX $4010      ; Disable DMC
	BIT $2002      ; Reset PPU status latch

	; Wait 2 full vblanks
	LDX #$02
--	BIT $2002
	BPL --
-	BIT $2002
	BMI -
	DEX
	BNE --

	; Clear OAM (sprites)
	LDX #$00
	LDA #$FF
-	STA $0200,X
	INX
	INX
	INX
	INX
	BNE -

	; Wait one more vblank just in case
-	BIT $2002
	BPL -

	JMP main
