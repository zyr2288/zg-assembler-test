; vim: set syntax=asm_ca65:
; vim:fileencoding=utf-8:foldmethod=marker

; .segment "HEADER"
	.ORG $BFF0
	.BASE 0

    .DB $4E, $45, $53, $1A
    .DB 1
    .DB 1
    .DB $00, $00

; .export Main
; .segment "CODE"
	.ORG $C000
Main
    rti

; .segment "STARTUP"

POSITION = 	$00
SUBPOSITION = 	$01
SPEEDHI = 	$02
SPEEDLOW = 	$03
JUSTFLAPPED = 	$04
ISDEAD =	$05
SCROLL = 	$06
RNG = 		$07
OLDRNG = 	$09
NEWRNG = 	$0a
PIPEIDHI = 	$0b
PIPEIDLOW = 	$0c
OLDPIPEIDHI = 	$0d
OLDPIPEIDLOW = 	$0e
PIPEABSOLUTEY = $0f


RESET ; {{{
    SEI ; Disable Interupts
    CLD ; Turn off decimal as its not supported on the NES


    ldx #@1000000 ; Disable sound IRQ
    stx $4017
    ldx #$00
    stx $4010     ; Disable PCM

    ; Initialize the stack
    ldx #$FF
    txs

    ; Random data for RNG
    lda SUBPOSITION
    sta RNG

    ; Clear PPU registers
    ldx #$00
    stx $2000
    stx $2001

    ; Wait for VBlank
-	bit $2002
    bpl -

    ; Clear the memory
    txa
CLEARMEMORY: ; Clear the memory from $0000 to $07ff
    sta $0000,x
    sta $0100,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    lda #$FF
    sta $0200,x
    lda #$00
    inx
    cpx #$00
    bne CLEARMEMORY

    ; Prepair PPU for writting palette data.
    lda #$3f
    sta $2006
    lda #$00
    sta $2006

    ldx #$00
LOADPALETTES:
    lda PALETTEDATA,x
    sta $2007
    inx
    cpx #$20
    bne LOADPALETTES

    clc
    ldy #$20
    ldx #$06
DRAWPIPEINIT:
    sty $2006
    stx $2006
    lda #$40
    sta $2007
    lda #$41
    sta $2007
    txa
    adc #$20
    tax
    tya
    adc #$00
    cmp #$24
    tay
    bcc DRAWPIPEINIT

LOADBACKGROUND:
    lda $2002 ; Read PPU status to reset high/low latch
    lda #$23
    sta $2006
    lda #$80
    sta $2006
    ldx #$00
LOADBACKGROUND1:
    txa
    and #$01
    tay
    lda ROW1,y
    sta $2007
    inx
    cpx #$20
    bne LOADBACKGROUND1
    ldx #$00
LOADBACKGROUND2:
    txa
    and #$01
    tay
    lda ROW2,y
    sta $2007
    inx
    cpx #$20
    bne LOADBACKGROUND2

    lda $2002 ; Read PPU status to reset high/low latch
    lda #$23
    sta $2006
    lda #$86
    sta $2006

    ldx #$50
    stx $2007
    inx
    stx $2007


    lda $2002 ; Read PPU status to reset high/low latch
    lda #$23
    sta $2006
    lda #$f8
    sta $2006
    ldx #$00
    lda #@00000101
LOADBACKGROUNDCOLOR:
    sta $2007
    inx
    cpx #$08
    bne LOADBACKGROUNDCOLOR

    lda $2002
    lda #$23
    ldx #$df
    ldy #$00
    sta $2006
    stx $2006

    sty $2007
    

    ; Reset scroll
    lda #$00
    sta $2005
    sta $2005

    ; Enable Interupts
    cli

    lda #@10010000
    sta $2000 		; When VBlank occurs call NMI

    lda #@00011100 	; Show sprites and background
    sta $2001

    ; Initialize valubles
    lda #$00
    sta POSITION
    sta SUBPOSITION
    sta SPEEDHI
    sta SPEEDLOW
    sta JUSTFLAPPED

    INFLOOP: 
    inc NEWRNG
    jmp INFLOOP
; }}}

NMI:

    lda $2002
    lda #$02 	; Load sprite range
    sta $4014

    lda ISDEAD
    cmp #$01
    bcc GAMELOOP

    ; Read input
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta $4016
    lsr        ; now A is 0
    ; By storing 0 into $4016, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from $4016.
    sta $4016
    lda $4016

    clc
    cmp #$41
    bcs TRS
	
	; bgrSBtlg
    lda #@00111011
    sta $2001
    jmp PLACEPLAYER

TRS:
    SEI
    lda #$00
    sta ISDEAD
    jmp RESET

GAMELOOP:
    inc SCROLL
    lda SCROLL
    sta $2005
    lda #$00
    sta $2005

    ; Read input
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta $4016
    lsr        ; now A is 0
    ; By storing 0 into $4016, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from $4016.
    sta $4016
    lda $4016

    clc
    cmp #$41
    bcs FLAP

    lda #$00
    sta JUSTFLAPPED

CALCULATESPEED:
    clc
    ; Calculate gravity
    ; low byte
    lda SPEEDLOW
    adc #$10
    sta SPEEDLOW
    ; high byte
    lda SPEEDHI
    adc #$00
    sta SPEEDHI
    tax ; store low byte in X for quick acces
    
    cmp #128
    bcs NEGATIVESPEED

APPLYSPEED:
    ; Apply low speed
    lda SUBPOSITION
    adc SPEEDLOW
    sta SUBPOSITION
    ; Apply high speed
    lda POSITION
    adc SPEEDHI
    sta POSITION

CHECKHEIGHT:
    ; Max height
    clc
    lda POSITION
    cmp #$10
    bcc MAXHEIGHT

    ; Min height
    cmp #$cf
    bcc PLACEPLAYERINIT
    lda #$01
    sta ISDEAD

PLACEPLAYERINIT:
    ldx #$00
PLACEPLAYER:
    txa
    and #@00000011
    cmp #$01
    lda PLAYERSPRITE,x
    bcc APPLYOFFSET
POSTOFFSET:
    sta $0200,x
    inx
    cpx #$10
    bne PLACEPLAYER

    lda SCROLL
    cmp #$2f
    beq FINDNEWPIPE
    cmp #$30
    beq NEWPIPERIGHTJMP
    cmp #$df
    bcs COLLISIONCHECKJMP
    cmp #$38
    beq NEWPIPELEFTJMP


    jmp INFLOOP 


APPLYOFFSET: ; {{{
    clc
    adc POSITION
    jmp POSTOFFSET

    ; }}}

FLAP: ; {{{
    lda JUSTFLAPPED
    cmp #$01
    bcs CALCULATESPEED

    lda #$01
    sta JUSTFLAPPED

    
    lda #$80
    sta SPEEDLOW
    lda #$fe
    sta SPEEDHI

    jmp APPLYSPEED

; }}}

NEGATIVESPEED: ; {{{
    clc

    ; Low byte
    lda SUBPOSITION
    adc SPEEDLOW
    STA SUBPOSITION

    ; High byte
    txa
    adc POSITION
    sta POSITION
    
    jmp CHECKHEIGHT

    ; }}}

MAXHEIGHT: ; {{{
    lda #$11
    sta POSITION
    sta SUBPOSITION
    lda #$00
    sta SPEEDLOW
    sta SPEEDHI

    jmp PLACEPLAYERINIT

; }}}


NEWPIPELEFTJMP:
    jmp NEWPIPELEFT

COLLISIONCHECKJMP:
    jmp COLLISIONCHECK

NEWPIPERIGHTJMP:
    jmp NEWPIPERIGHT

FINDNEWPIPE:
    ; Copy current pipe id to old pipe id
    clc
    lda PIPEIDHI
    sta OLDPIPEIDHI
    lda PIPEIDLOW
    sta OLDPIPEIDLOW

    ; Get new rng value
    lda RNG
    sta OLDRNG
    lda NEWRNG
    sta RNG

    ; Clamp RNG to 0-15
    and #$0f

    sta $ff

    lda #$20
    sta PIPEIDHI
    sta PIPEABSOLUTEY
    lda #$66
    sta PIPEIDLOW

    ldx #$00
    cpx $ff
    beq GO2INF
FINDNEWPIPEID:
    lda PIPEIDLOW
    adc #$20
    sta PIPEIDLOW
    lda PIPEIDHI
    adc #$00
    sta PIPEIDHI
    lda PIPEABSOLUTEY
    adc #$8
    sta PIPEABSOLUTEY

    inx

    cpx $ff
    bne FINDNEWPIPEID

GO2INF:
    jmp INFLOOP

NEWPIPELEFT: ; {{{
    lda $2002 ; Read PPU status to reset high/low latch
    clc
    lda #@00000000 	; Hide sprites and background
    sta $2001

    lda SCROLL
    sta $2005
    lda #$00
    sta $2005

    ; Over draw old data
    lda OLDPIPEIDHI
    sta $ff
    sta $2006
    lda OLDPIPEIDLOW
    sta $fe
    sta $2006
    
    lda #$40
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$40
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$40
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$40
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$40
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$40
    sta $2007

PLACEPIPELEFT:
    lda PIPEIDHI
    sta $ff
    sta $2006
    lda PIPEIDLOW
    sta $fe
    sta $2006
    
    lda #$34
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$30
    sta $2007

    lda SCROLL
    sta $2005
    lda #$00
    sta $2005

    lda #@00011100 	; Show sprites and background
    sta $2001

    jmp INFLOOP

    ; }}}



NEWPIPERIGHT: ; {{{
    lda $2002 ; Read PPU status to reset high/low latch
    clc
    lda #@00000000 	; Hide sprites and background
    sta $2001

    lda SCROLL
    sta $2005
    lda #$00
    sta $2005

    ; Over draw old data
    lda OLDPIPEIDHI
    sta $ff
    sta $2006
    ldx OLDPIPEIDLOW
    inx
    stx $fe
    stx $2006
    
    lda #$41
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$41
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$41
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$41
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$41
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$41
    sta $2007

PLACEPIPERIGHT:
    lda PIPEIDHI
    sta $ff
    sta $2006
    ldx PIPEIDLOW
    inx
    stx $fe
    stx $2006
    
    lda #$35
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007


    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$00
    sta $2007

    lda $fe
    adc #$20
    sta $fe
    lda $ff
    adc #$00
    sta $ff
    sta $2006
    lda $fe
    sta $2006

    lda #$31
    sta $2007

    lda SCROLL
    sta $2005
    lda #$00
    sta $2005

    lda #@00011100 	; Show sprites and background
    sta $2001

    jmp INFLOOP

COLLISIONCHECK:
    lda POSITION
    cmp PIPEABSOLUTEY
    bcc KILL
    clc
    lda PIPEABSOLUTEY
    adc #$10
    cmp POSITION
    bcc KILL

    jmp INFLOOP

KILL:
    lda #$01
    sta ISDEAD

    jmp INFLOOP

    ; }}}

; Sprite data
PLAYERSPRITE:
    .DB $00, $00, $00, $40
    .DB $00, $01, $00, $48
    .DB $08, $10, $00, $40
    .DB $08, $11, @00000001, $48

PALETTEDATA:
    .DB $31, $0a, $1a, $3a, 	$31, $07, $17, $19, 	$31, $0d, $28, $27, 	$00, $34, $24, $14 	; background palettes
    .DB $31, $0d, $28, $20, 	$31, $16, $28, $20, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	; sprite palettes

ROW1:
    .DB $32, $33
ROW2:
    .DB $42, $43
    
; .segment "VECTORS"
	.ORG $FFFA
    .DW NMI
    .DW RESET
	.DW 0

; .segment "CHARS"
.incbin "../gfx/sprites.chr"
.incbin "../gfx/background.chr"
