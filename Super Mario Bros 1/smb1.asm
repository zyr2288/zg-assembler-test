	.ORG $7FF0

	.DB "NES", $1a ; identification of the iNES header
	
	.DB 2 ; number of 16KB PRG-ROM pages
	.DB 1 ; number of 8KB CHR-ROM pages
	
	.DB 1 ; mapper/mirroring/whatever
	
	; .dsb 9, $00 ; clear the remaining bytes


	.MACRO GetOrg
	.MSG "当前org地址是 ${0}", *
	.ENDM

	; -----------------------------------------
	; Add definitions
	.INCLUDE "src/defs.asm"

	; Add RAM definitions
	.INCLUDE "src/ram.asm"
	
	.ORG $8000
	.INCLUDE "src/prg.asm"
	
	; -----------------------------------------
	; include CHR-ROM
	.INCBIN "smb1.chr"

