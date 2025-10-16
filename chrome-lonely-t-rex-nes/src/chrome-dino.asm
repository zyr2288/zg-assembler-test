	; ; 1x 16KB bank of PRG code
	; .inesprg 1
	; ; 1x 8KB bank of CHR data
	; .ineschr 1
	; ; mapper 0 = NROM, no bank swapping
	; .inesmap 0
	; ; background mirroring
	; .inesmir 1

	.DEF prgRomPage, 1
	.DEF chrRomPage, 1

	.DEF mapper, 0
	.DEF fourScreen, 0 << 2		;四分屏幕，1为开启
	.DEF trainer, 0 << 3		;是否开启Trainer，1为开启
	.DEF sram, 0 << 1		;是否开启SRAM，1为开启
	.DEF mirror, 1			;0为横向镜像，1为纵向
	
	.ORG 0
	.BASE 0
	.DB $4E, $45, $53, $1A, prgRomPage, chrRomPage
	.DB ((mapper & $F) << 4) | trainer | fourScreen | sram | mirror
	.DB (mapper & $F)

	.INCLUDE "constants.asm"
	.INCLUDE "variables1.asm"
	.INCLUDE "variables2.asm"

	; PRG
	.ORG MEM_LAYOUT_PRG
	.BASE $10

	; macros
	.include "./macros/common.asm"
	.include "./macros/rendering.asm"

	; main routine
	.include "./program.asm"

	; subroutines
	.include "./subroutines/game-logic.asm"
	.include "./subroutines/game-score.asm"
	.include "./subroutines/load-resources.asm"
	.include "./subroutines/draw-background.asm"
	.include "./subroutines/scroll-background.asm"
	.include "./subroutines/draw-dino.asm"
	.include "./subroutines/handle-input.asm"
	.include "./subroutines/aabb-detection.asm"
	.include "./subroutines/clear-obstacle.asm"
	.include "./subroutines/draw-obstacle.asm"


BIN_BACKGROUNDS:
	.include "./assets/background.asm"

BIN_PALETTES:
	.include "./assets/palettes.asm"

BIN_ATTRIBUTES:
	.include "./assets/attributes.asm"

BIN_SPRITE_0:
	.include "./assets/sprite0.asm"

BIN_SPRITES:
	.include "./assets/sprites.asm"

BIN_OBSTACLES:
	.include "./assets/obstacles.asm"

BIN_HORIZON_LINE:
	.include "./assets/horizon-line.asm"

BIN_EMPTY:
	.include "./assets/empty.asm"

	.org MEM_LAYOUT_INT
	.dw NMI
	.dw RESET
	.dw 0

	.INCBIN "./assets/chr.bin"

	; .BASE $4010
	; .INCBIN "./assets/main.chr"
	
	; .BASE $5010
	; .incbin "./assets/font.chr"
