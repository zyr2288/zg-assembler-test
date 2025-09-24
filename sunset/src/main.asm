

	.INCLUDE "constants.asm"
	
	.ORG 0
	.BASE 0
	.INCLUDE "header.asm"

	.DEF TileAddrY, $0200
	.DEF TileAddrX, $0203

	.ENUM 0
		PtrBg,         	 2
		Direction,       1
		FrameCounter,	 1
		SpriteCounter,	 1
	.ENDE

	.ORG $C000
	.BASE $10
	.INCLUDE "reset.asm"

irq_handler
	rti

nmi_handler
	pha
	txa
	pha
	tya
	pha

	lda #$00
	sta OAMADDR
	lda #$02
	sta OAMDMA
	
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL

	inc FrameCounter
	lda FrameCounter
	cmp #$0F
	beq @move
	jmp @done
@move:
	lda #$00
	sta FrameCounter  
	
	jsr move
	
	lda Direction
	eor #$01
	sta Direction
@done:
	; ppu clean up 
	lda #@10010000 
	sta PPUCTRL
	lda #@00011110
	sta PPUMASK

	pla 
	tay
	pla
	tax
	pla

	rti

main
	ldx #$00
@clrmem:
	sta $0000,x ; $0000 => $00FF
	sta $0100,x ; $0100 => $01FF
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	lda #$FF
	sta $0200,x ; $0200 => $02FF
	lda #$00
	inx
	bne @clrmem

	lda #$00
	sta Direction
	sta FrameCounter  
	sta SpriteCounter
	
	jsr load_palette
	jsr load_background
	jsr load_attribute 
	jsr load_sprite
@vblankwait:       ; wait for another vblank before continuing
	bit PPUSTATUS
	bpl @vblankwait

	lda #@10010000  ; turn on NMIs, sprites use first pattern table,bg uses second one
	sta PPUCTRL
	lda #@00011110  ; turn on screen
	sta PPUMASK
  	JMP *

load_palette
	ldx PPUSTATUS
	ldx #$3F
	stx PPUADDR
	ldx #$00
	stx PPUADDR

	ldx #$00
-	lda palettes,x
	sta PPUDATA
	
	inx
	cpx #$20
	bne -
	rts

load_sprite
	ldx #$00
-	lda sprites,x
	sta $0200,x
	inx
	cpx #$E0
	bne -
	rts

load_attribute
	lda PPUSTATUS
	lda #$23
	sta PPUADDR
	lda #$CA
	sta PPUADDR

	ldx #$00
-	lda attribute,x
	sta PPUDATA
	inx
	cpx #$40
	bne -
	rts

load_background
	lda PPUSTATUS
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$00
	ldy #$00
	lda #<background
	sta PtrBg
	lda #>background
	sta PtrBg+1
-	lda (PtrBg),y
	sta PPUDATA
	iny
	bne -
	inc PtrBg+1
	inx
	cpx #$04 
	bne -
	rts

move
  	ldx #$00
-	inc SpriteCounter
	lda SpriteCounter
	cmp #$08
	beq @changeDir
	lda Direction
	lsr
	bcs @left
@right:
	inc TileAddrX,x
	jmp @keepOn
@left:
	dec TileAddrX,x
@keepOn:
	txa
	clc
	adc #$04
	tax
	cpx #$E0
	bne -
	jmp +
@changeDir:
	lda #$00
	sta SpriteCounter
	lda Direction
	eor #$01
	sta Direction
	jmp -
+	RTS


sprites:
	.INCLUDE "sprites.asm"

background:
	.incbin "../assets/background.nam"

palettes:
	.db $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$37,$0F ; background palette
	.db $13,$14,$24,$27, $13,$05,$15,$14, $13,$02,$38,$3C, $13,$1C,$15,$14 ; sprite palette 

attribute:
	.db @00000000,@00000000,@00000000,@00000000,@00000000,@00000000,@00000000,@00000000
	.db @00000000,@00000000,@00000000,@00000000,@00000000,@00000000,@11111111,@11111111
	.db @11111111,@11111111,@11111111,@11111111,@11111111,@11111111,@11111111,@11111111
	.db @01010101,@01010101,@01010101,@11011111,@11111111,@11111111,@11111111,@11111111
	.db @01010101,@01010101,@01010101,@01010101,@11111111,@11111111,@11111111,@11111111
	.db @11110111,@01010101,@01010101,@11111101,@11111111,@11111111,@11111111,@11111111
	.db @01010101,@01010101,@01010101,@01010101,@01010101,@01010101,@00000000,@00000000
	.db @00000000,@00000000,@00000000,@00000000,@00000000,@00000000,@00000000,@00000000

	.ORG $FFFA
	.DW nmi_handler, reset_handler, irq_handler

	.incbin "../assets/graphics.chr"