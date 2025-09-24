	.DEF .prgRomPage, 1
	.DEF .chrRomPage, 1

	.DEF .mapper, 0
	.DEF .fourScreen, 0 << 2		;四分屏幕，1为开启
	.DEF .trainer, 0 << 3		;是否开启Trainer，1为开启
	.DEF .sram, 0 << 1		;是否开启SRAM，1为开启
	.DEF .mirror, 0			;0为横向镜像，1为纵向
	
	.DB $4E, $45, $53, $1A, .prgRomPage, .chrRomPage
	.DB ((.mapper & $F) << 4) | .trainer | .fourScreen | .sram | .mirror
	.DB (.mapper & $F)