	; 可以运行的基础代码，不要更改
	
	.INCLUDE "defs.asm"
	
	.BASE 0
	.ORG 0
	.HEX 4E 45 53 1A 01 01 00 00 00 00 00 00 00 00 00 00
	
	.ORG $C000
	.BASE $10
	
	.DB "COPYRIGHT 1981 1985 NAMCO LTD.", $D, $A
	.DB "ALL RIGHTS RESERVED           ", $D, $A
	
StaffString
	.DB "RYOUITI OOKUBO  TAKEFUMI HYOUDOUJUNKO OZAWA     "

RESET
	SEI
	LDA #@00010000
	STA PPU_CTRL_REG1
	CLD
	LDX #2

-	LDA PPU_STATUS
	BPL -
	LDA #@00000110
	STA PPU_CTRL_REG2
	DEX
	BNE -
	
	LDX #$7F
	TXS
	JSR Reset_ScreenStuff
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	JSR Set_PPU

BEGIN
	JSR Draw_TitleScreen
	LDA #0
	STA Construction_Flag

New_Scroll
	JSR Null_Upper_NT
	JSR Scroll_TitleScrn
	
Title_Loaded
	JSR Title_Screen_Loop
	JSR Load_DemoLevel
	JSR BonusLevel_ButtonCheck
	JMP New_Scroll

Construction
	LDA Construction_Flag
	BNE Skip_LoadFrame
	JSR Screen_Off
	JSR Make_GrayFrame
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU

Skip_LoadFrame
	JSR Null_Status
	LDA #$10
	STA tank.x
	LDA #$18
	STA tank.y
	LDA #$84
	STA tank.status
	LDA #0
	STA tank.type
	STA Spr_Attrib
	STA Track_Pos
	STA BkgOccurence_Flag
	STA byte_7B
	STA TSA_BlockNumber
	STA Scroll_Byte
	STA PPU_REG1_Stts
	STA player.blinkTimer
	STA player.blinkTimer+1
	LDA Construction_Flag
	BNE Construction_Loop
	JSR DraW_Normal_HQ

Construction_Loop
	JSR NMI_Wait
	JSR Move_Tank
	JSR Check_BorderReach
	LDA Frame_Counter
	AND #$10
	BEQ Skip_Status_Handle
	JSR TanksStatus_Handle

Skip_Status_Handle
	LDA Joypad1_Buttons
	AND #$F0
	BNE loc_C13E
	LDA Joypad1_Differ
	AND #1
	BEQ loc_C120
	LDA BkgOccurence_Flag
	BNE loc_C111
	INC BkgOccurence_Flag
	JMP Construct_Draw_TSA

loc_C111
	INC TSA_BlockNumber
	LDA TSA_BlockNumber
	CMP #$E
	BNE Construct_Draw_TSA
	LDA #0
	STA TSA_BlockNumber
	JMP Construct_Draw_TSA

loc_C120
	LDA Joypad1_Differ
	AND #2
	BEQ loc_C13E
	LDA BkgOccurence_Flag
	BNE loc_C12F
	INC BkgOccurence_Flag
	JMP Construct_Draw_TSA

loc_C12F
	DEC TSA_BlockNumber
	LDA TSA_BlockNumber
	CMP #$FF
	BNE Construct_Draw_TSA
	LDA #$D
	STA TSA_BlockNumber
	JMP Construct_Draw_TSA

loc_C13E
	LDA Joypad1_Buttons
	AND #3
	BEQ Construct_StartCheck

Construct_Draw_TSA
	JSR Draw_TSA_On_Tank

Construct_StartCheck
	LDA Joypad1_Differ
	AND #8
	BNE End_Construction
	JMP Construction_Loop

End_Construction
	LDA #$20
	STA Spr_Attrib
	INC Construction_Flag
	JMP Title_Loaded

Start_StageSelScrn
	JSR NMI_Wait
	JSR Sound_Stop
	LDA #$1C
	STA PPU_Addr_Ptr
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	STA Pause_Flag
	LDA #4
	STA BkgPal_Number
	JSR FillNT_with_Grey

StageSelect_Loop
	JSR Draw_StageNumString
	LDA EnterGame_Flag
	BNE Start_Level
	LDA Joypad1_Differ
	AND #8
	BNE Start_Level
	LDA Joypad1_Differ
	AND #1
	BNE Inc_LevelNum
	LDA Joypad1_Buttons
	AND #1
	BEQ Check_B
	LDA Frame_Counter
	AND #7
	BNE Check_B

Inc_LevelNum
	LDA #0
	STA Frame_Counter
	INC Level_Number
	LDA Level_Number
	CMP #$24
	BNE StageSelect_Loop
	LDA #$23
	STA Level_Number
	JMP StageSelect_Loop

Check_B
	LDA Joypad1_Differ
	AND #2
	BNE Dec_LevelNum
	LDA Joypad1_Buttons
	AND #2
	BEQ StageSelect_Loop
	LDA Frame_Counter
	AND #7
	BNE StageSelect_Loop

Dec_LevelNum
	LDA #0
	STA Frame_Counter
	DEC Level_Number
	BNE StageSelect_Loop
	LDA #1
	STA Level_Number
	JMP StageSelect_Loop

Start_Level
	LDA #1
	STA Snd_Battle1
	STA Snd_Battle2
	STA Snd_Battle3
	LDA Construction_Flag
	BNE Skip_Lvl_Load
	JSR Make_GrayFrame
	LDA Level_Number
	JSR level.Load
	JSR DraW_Normal_HQ
	JMP +

Skip_Lvl_Load
	JSR Draw_Naked_HQ

+
	LDA #0
	STA ScrBuffer_Pos
	JSR Copy_AttribToScrnBuff
	JSR FillNT_with_Black
	LDA #0
	STA BkgPal_Number
	JSR NMI_Wait
	JSR SetUp_LevelVARs

Battle_Engine
	JSR NMI_Wait
	LDA Pause_Flag
	BNE Skip_Battle_Loop
	JSR Battle_Loop

Skip_Battle_Loop
	JSR Bonus_Draw
	JSR Draw_All_BulletGFX
	JSR TanksStatus_Handle
	LDA Joypad1_Differ
	AND #8
	BEQ Skip_Pause_Switch
	LDA #1
	EOR Pause_Flag
	STA Pause_Flag
	STA Snd_Pause

Skip_Pause_Switch
	JSR Draw_Pause
	JSR LevelEnd_Check
	BEQ Battle_Engine
	LDA #0
	STA Seconds_Counter
	STA Frame_Counter
	STA Snd_Move
	STA Snd_Engine
	LDA gameOverStr.timer
	BEQ AfterDeath_BattleRun
	LDA #$FE
	STA Seconds_Counter

AfterDeath_BattleRun
	JSR NMI_Wait
	JSR FreezePlayer_OnHQDestroy
	JSR Battle_Loop
	JSR Bonus_Draw
	JSR TanksStatus_Handle
	JSR Draw_All_BulletGFX
	JSR Swap_Pal_Colors
	LDA Seconds_Counter
	CMP #2
	BNE AfterDeath_BattleRun
	JSR Sound_Stop
	JSR Draw_Pts_Screen
	INC Level_Number
	LDA Level_Number
	CMP #71
	BNE Ckeck_FirstFinish
	LDA #1
	STA Level_Number
	LDA #0
	STA Level_Mode

Ckeck_FirstFinish
	LDA Level_Number
	CMP #36
	BNE Check_GameOver
	LDA #1
	STA Level_Mode

Check_GameOver
	LDA player.lives
	CLC
	ADC player.lives + 1
	BEQ Make_GameOver
	LDA HQ_Status
	CMP #$80
	BNE Make_GameOver
	JMP Start_StageSelScrn

Make_GameOver
	JSR Draw_Brick_GameOver
	JSR Update_HiScore
	TYA
	BEQ Skip_RecordShow
	JSR Draw_Record_HiScore
	JSR Clear_NT

Skip_RecordShow
	JMP BEGIN


Clear_NT
	JSR Screen_Off
	JSR Null_NT_Buffer
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	RTS

FreezePlayer_OnHQDestroy
	LDA HQ_Status
	CMP #$80
	BEQ +
	LDA #0
	STA Joypad1_Buttons
	STA Joypad2_Buttons
	STA Joypad1_Differ
	STA Joypad2_Differ

+
	RTS


Null_both_HiScore
	LDX #HiScore_1P_String
	JSR Null_8Bytes_String
	LDX #HiScore_2P_String
	JSR Null_8Bytes_String

Init_Level_VARs
	LDA #0
	STA player.type
	STA player.type + 1
	LDA #0
	STA player.addLifeFlag
	STA player.addLifeFlag + 1
	STA EnterGame_Flag
	LDA #3
	STA player.lives
	STA player.lives + 1
	STA EnemyRespawn_PlaceIndex
	LDA CursorPos
	BNE +
	LDA #0
	STA player.lives + 1

+
	LDA #1
	STA Level_Number
	LDA #0
	STA Level_Mode
	RTS

Battle_Loop
	JSR Ice_Detect
	JSR Ice_Move
	JSR Motion_Handle
	JSR HideHiBit_Under_Tank
	JSR AllBulletsStatus_Handle
	JSR HQ_Handle
	JSR Invisible_Timer_Handle
	JSR Make_Player_Shot
	JSR Make_Enemy_Shot
	JSR Respawn_Handle
	JSR Bullet_Fly_Handle
	JSR BulletToBullet_Impact_Handle
	JSR BulletToTank_Impact_Handle
	JSR Bonus_Handle
	JSR GameOver_Str_Move_Handle
	JSR Play_Snd_Move
	JSR Draw_Player_Lives
	JSR Swap_Pal_Colors
	RTS

Swap_Pal_Colors
	LDA Frame_Counter
	AND #$3F
	BEQ switch
	CMP #$20
	BNE exit
	LDA #1
	STA BkgPal_Number
	RTS

switch
	LDA #2
	STA BkgPal_Number

exit
	RTS


SetUp_LevelVARs
	JSR Hide_All_Bullets
	JSR Null_Status
	LDA #$F0
	STA gameOverStr.y
	LDA #0
	STA gameOverStr.timer
	LDA player.lives
	BEQ +
	LDX #0
	JSR Make_Respawn

+
	LDA player.lives + 1
	BEQ Set_VARs
	LDX #1
	JSR Make_Respawn

Set_VARs
	LDA #20
	STA Enemy_Reinforce_Count
	STA Enemy_Counter
	LDA #0
	STA Enemy_TypeNumber
	STA Seconds_Counter
	STA Construction_Flag
	STA HQArmour_Timer
	STA player.blinkTimer
	STA player.blinkTimer+1
	STA player.invisibleTimer
	STA player.invisibleTimer + 1
	STA Respawn_Timer
	STA bouns.x
	STA enemy.freezeTimer
	STA EnemyRespawn_PlaceIndex
	JSR Null_KilledEnms_Count
	JSR Draw_Reinforcemets
	JSR NMI_Wait
	JSR Draw_IP
	JSR Draw_LevelFlag
	JSR Load_Enemy_Count
	LDA #$80
	STA HQ_Status
	LDA #1
	STA Snd_Engine
	STA EnterGame_Flag
	LDA Level_Mode
	CMP #1
	BNE ++
	LDA #35
	JMP Respawn_Delay_Calc

++
	LDA Level_Number

Respawn_Delay_Calc
	ASL
	ASL
	STA Temp
	LDA #190
	SEC
	SBC Temp
	STA Respawn_Delay
	LDA CursorPos
	BEQ +++
	LDA Respawn_Delay
	SEC
	SBC #20
	STA Respawn_Delay

+++
	RTS


Load_DemoLevel
	LDA #1
	STA Pause_Flag
	LDA #0
	STA BkgPal_Number
	JSR Init_Level_VARs
	LDA #3
	STA player.lives + 1
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	STA Seconds_Counter
	STA Frame_Counter
	JSR Make_GrayFrame
	LDA #$FF
	STA Level_Number
	JSR level.Load
	LDA #30
	STA Level_Number
	LDA #2
	STA Level_Mode
	JSR Screen_Off
	LDX #$1A
	STX Block_X
	LDY #$46
	STY Block_Y
	LDA #>string.aBattle
	STA HighStrPtr_Byte
	LDA #<string.aBattle
	STA LowStrPtr_Byte
				;
	JSR Draw_BrickStr
	LDX #$3C
	STX Block_X
	LDY #$78
	STY Block_Y		;
				;
	LDA #>string.aCity
	STA HighStrPtr_Byte
	LDA #<string.aCity
	STA LowStrPtr_Byte
				;
	JSR Draw_BrickStr
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	JSR SetUp_LevelVARs
	JSR DraW_Normal_HQ
	JSR NMI_Wait
	LDA #5
	STA TanksOnScreen
	RTS


BonusLevel_ButtonCheck

	JSR NMI_Wait
	LDA Joypad1_Differ
	AND #@110
	BNE Button_Pressed
	
DemoLevel_Loop
	JSR Demo_AI
	JSR Battle_Loop
	JSR Bonus_Draw
	JSR TanksStatus_Handle
	JSR Draw_All_BulletGFX
	JSR LevelEnd_Check
	BEQ BonusLevel_ButtonCheck

End_Demo
	LDA #0
	STA ScrBuffer_Pos
	RTS

Button_Pressed
	PLA
	PLA
	LDA #0
	STA ScrBuffer_Pos
	JSR Null_Upper_NT
	JMP Title_Loaded

Draw_Record_HiScore
	JSR Screen_Off
	LDA #$1C
	STA PPU_Addr_Ptr
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	JSR Null_NT_Buffer
	LDX #$10
	STX Block_X
	LDY #$32
	STY Block_Y
	LDA #>string.aHiscore
	STA HighStrPtr_Byte
	LDA #<string.aHiscore
	STA LowStrPtr_Byte
	JSR Draw_BrickStr
	JSR Draw_RecordDigit
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	LDA #0
	STA Seconds_Counter
	LDA #1
	STA Snd_RecordPts1
	STA Snd_RecordPts2
	STA Snd_RecordPts3

-
	JSR NMI_Wait
	LDA Frame_Counter
	AND #3
	CLC
	ADC #5
	STA BkgPal_Number
	LDA Snd_RecordPts1
	BNE -
	LDA #0
	STA BkgPal_Number
	RTS


Show_Secret_Msg
	JSR Screen_Off
	LDA #$1C
	STA PPU_Addr_Ptr
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	JSR Null_NT_Buffer
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	JSR Wait_1Second
	JSR Wait_1Second
	LDA #>string.aThisProgramWas
	STA HighPtr_Byte
	LDA #<string.aThisProgramWas
	STA LowPtr_Byte
	LDX #8
	LDY #8
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aWrittenBy
	STA HighPtr_Byte
	LDA #<string.aWrittenBy
	STA LowPtr_Byte
	LDX #8
	LDY #$A
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aOpenkreach
	STA HighPtr_Byte
	LDA #<string.aOpenkreach
	STA LowPtr_Byte
	LDX #8
	LDY #$C
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aWhoLovesNoriko
	STA HighPtr_Byte
	LDA #<string.aWhoLovesNoriko
	STA LowPtr_Byte
	LDX #8
	LDY #$E
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aDot
	STA HighPtr_Byte
	LDA #<string.aDot
	STA LowPtr_Byte
	LDX #8
	LDY #$10
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aDot
	STA HighPtr_Byte
	LDA #<string.aDot
	STA LowPtr_Byte
	LDX #9
	LDY #$10
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aDot
	STA HighPtr_Byte
	LDA #<string.aDot
	STA LowPtr_Byte
	LDX #$A
	LDY #$10
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aDot
	STA HighPtr_Byte
	LDA #<string.aDot
	STA LowPtr_Byte
	LDX #$B
	LDY #$10
	JSR String_to_Screen_Buffer
	JSR Wait_1Second
	LDA #>string.aDot
	STA HighPtr_Byte
	LDA #<string.aDot
	STA LowPtr_Byte
	LDX #$C
	LDY #$10
	JSR String_to_Screen_Buffer
	JSR Draw_Drop
	JSR Screen_Off
	JSR Make_GrayFrame
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	RTS


Wait_1Second
	LDA #0
	STA Frame_Counter

loc_C56B
	JSR NMI_Wait
	LDA Frame_Counter
	AND #$3F
	BNE loc_C56B
	RTS

Draw_Drop
	LDA #$78
	STA Block_X
	LDA #$1E
	STA Block_Y
	LDA #0
	STA Counter

-
	JSR Draw_RespawnPic
	JSR Draw_RespawnPic
	JSR Draw_RespawnPic
	JSR Draw_RespawnPic
	INC Counter
	LDA Counter
	CMP #7
	BNE -

--
	JSR NMI_Wait
	INC Block_Y
	LDA #$9D
	STA Spr_TileIndex
	LDA #1
	STA TSA_Pal
	LDX Block_X
	LDY Block_Y
	JSR Draw_WholeSpr
	LDA Block_Y
	CMP #$F8
	BNE --
	RTS


Draw_RespawnPic
	JSR NMI_Wait
	LDA #3
	STA TSA_Pal
	LDA #3
	SEC
	SBC Counter
	BPL +
	EOR #$FF
	CLC
	ADC #1

+
	STA Temp
	LDA #3
	SEC
	SBC Temp
	ASL
	ASL
	CLC
	ADC #$A1
	STA Spr_TileIndex
	LDX Block_X
	LDY Block_Y
	JSR Draw_WholeSpr
	RTS

Draw_Brick_GameOver
	JSR Screen_Off
	LDA #$1C
	STA PPU_Addr_Ptr
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts
	JSR Null_NT_Buffer
	LDX #$3C
	STX Block_X
	LDY #$46
	STY Block_Y
	LDA #>string.aGame
	STA HighStrPtr_Byte
	LDA #<string.aGame
	STA LowStrPtr_Byte
	JSR Draw_BrickStr
	LDX #$3C
	STX Block_X
	LDY #$78
	STY Block_Y
	LDA #>string.aOver
	STA HighStrPtr_Byte
	LDA #<string.aOver
	STA LowStrPtr_Byte
	JSR Draw_BrickStr
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	LDA #0
	STA Seconds_Counter
	LDA #1
	STA Snd_GameOver1
	STA Snd_GameOver2
	STA Snd_GameOver3

Next_Frame
	JSR NMI_Wait
	LDA Joypad1_Differ
	AND #$C
	BNE End_Draw_Brick_GameOver
	LDA Snd_GameOver1
	BNE Next_Frame

End_Draw_Brick_GameOver
	JSR Screen_Off
	JSR Null_NT_Buffer
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	JSR Sound_Stop
	RTS

Demo_AI
	LDA #1
	STA Counter

-
	LDX Counter
	LDA bouns.x
	BEQ NoBonus
	LDA BonusPts_TimeCounter
	BNE NoBonus

Take_Bonus
	LDA bouns.x
	STA AI_X_Aim
	LDA bouns.y
	STA AI_Y_Aim
	JSR Load_AI_Status
	JMP Load_Direction_DemoAI

NoBonus
	LDA tank.status+2,X
	BPL +
	CMP #$E0
	BCS +
	LDA tank.x+2,X
	STA AI_X_Aim
	LDA tank.y+2,X
	STA AI_Y_Aim
	JSR Load_AI_Status
	JMP Load_Direction_DemoAI

+
	LDA tank.status+4,X
	BPL ++
	CMP #$E0
	BCS ++
	LDA tank.x+4,X
	STA AI_X_Aim
	LDA tank.y+4,X
	STA AI_Y_Aim
	JSR Load_AI_Status
	JMP Load_Direction_DemoAI

++
	LDA tank.status+3,X
	BPL EnemiesNotActing
	CMP #$E0
	BCS EnemiesNotActing
	LDA tank.x+3,X
	STA AI_X_Aim
	LDA tank.y+3,X
	STA AI_Y_Aim
	JSR Load_AI_Status
	JMP Load_Direction_DemoAI

EnemiesNotActing
	LDA #0
	JMP SaveButton_DemoAI

Load_Direction_DemoAI
	AND #3
	TAY
	LDA Tank_Direction,Y

SaveButton_DemoAI
	LDX Counter
	STA Joypad1_Buttons,X
	STA Joypad1_Differ,X
	LDA tank.y,X
	CMP #$C8
	BCC Next_Demo_AI
	LDA Joypad1_Differ,X
	AND #$F0
	STA Joypad1_Differ,X

Next_Demo_AI
	DEC Counter
	BPL -
	RTS
Tank_Direction	.DB $13,$43,$23,$83

Draw_TSA_On_Tank
	LDA TSA_BlockNumber
	AND #$F
	LDX tank.x
	LDY tank.y
	JSR Draw_TSABlock
	RTS

Move_Tank
	LDA Joypad1_Buttons
	AND #$F0
	BEQ ArrowNotPressed
	INC byte_7B
	LDA #0
	STA BkgOccurence_Flag
	JMP +

ArrowNotPressed
	LDA #0
	STA byte_7B

+
	LDA byte_7B
	CMP #$14
	BEQ loc_C6FB
	LDA Joypad1_Differ
	AND #$F0
	BEQ End_Move_Tank
	LDA Joypad1_Differ
	JSR Button_To_DirectionIndex
	BMI End_Move_Tank
	JMP loc_C704

loc_C6FB
	LDA #$F
	STA byte_7B
	LDA Joypad1_Buttons
	JSR Button_To_DirectionIndex

loc_C704
	TAY
	LDA Coord_X_Increment,Y
	ASL
	ASL
	ASL
	ASL
	CLC
	ADC tank.x
	STA tank.x
	LDA Coord_Y_Increment,Y
	ASL
	ASL
	ASL
	ASL
	CLC
	ADC tank.y
	STA tank.y

End_Move_Tank
	RTS

Null_KilledEnms_Count
	LDX #7
	LDA #0

-
	STA Enmy_KlledBy1P_Count,X
	DEX
	BPL -
	RTS

LevelEnd_Check
	LDA HQ_Status
	BEQ Init_GameOverStr
	LDA Enemy_Counter
	BEQ ExitLevel
	LDA player.lives
	CLC
	ADC player.lives + 1
	BNE PlayLevel

Init_GameOverStr
	LDA #$70
	STA gameOverStr.x
	LDA #$F0
	STA gameOverStr.y
	LDA #0
	STA gameOverStr.scrollType
	LDA #$11
	STA gameOverStr.timer
	LDA #0
	STA Frame_Counter

ExitLevel
	LDA #1
	RTS

PlayLevel
	LDA #0
	RTS

Zero_Page_Viewer
	LDA ZeroPage_Offset
	JSR Num_To_NumString
	LDA #$30
	STA Char_Index_Base
	LDA #0
	STA HighPtr_Byte
	LDA #Num_String+4
	STA LowPtr_Byte
	LDX #9
	LDY #2
	JSR Save_Str_To_ScrBuffer
	LDX ZeroPage_Offset
	LDA 0,X
	JSR Num_To_NumString
	LDA #0
	STA HighPtr_Byte
	LDA #Num_String+4
	STA LowPtr_Byte
	LDX #$D
	LDY #2
	JSR Save_Str_To_ScrBuffer
	LDA #0
	STA Char_Index_Base
	LDA Joypad1_Differ
	AND #4
	BEQ SkipInc_Zero_Page_Viewer
	INC ZeroPage_Offset

SkipInc_Zero_Page_Viewer
	LDA Joypad1_Differ
	AND #2
	BEQ ScipDec_Zero_Page_Viewer
	DEC ZeroPage_Offset

ScipDec_Zero_Page_Viewer
	LDA Joypad1_Differ
	AND #1
	BEQ End_Zero_Page_Viewer
	LDA ZeroPage_Offset
	CLC
	ADC #$10
	STA ZeroPage_Offset

End_Zero_Page_Viewer
	RTS


Scroll_TitleScrn
	LDA #0
	STA Scroll_Byte
	STA PPU_REG1_Stts

-
	JSR NMI_Wait
	INC Scroll_Byte
	LDA Joypad1_Differ
	AND #@1100
	BNE +
	LDA Scroll_Byte
	CMP #$F0
	BNE -
	RTS

+
	PLA
	PLA
	JMP Title_Loaded

Draw_Player_Lives
	LDA #1
	STA Counter
	STA byte_6B
	LDA #$6E
	STA Char_Index_Base
	LDA #>string.PlayerLives_Icon
	STA HighPtr_Byte
	LDA #<string.PlayerLives_Icon
	STA LowPtr_Byte
	LDX #$1D
	LDY #$12
	JSR String_to_Screen_Buffer
	LDA Level_Mode
	CMP #2
	BEQ Draw_2P_Lives
	LDA CursorPos
	BNE Draw_2P_Lives
	LDA #0
	STA Counter
	JMP Draw_1P_Lives

Draw_2P_Lives
	LDA #>string.PlayerLives_Icon
	STA HighPtr_Byte
	LDA #<string.PlayerLives_Icon
	STA LowPtr_Byte
	LDX #$1D
	LDY #$15
	JSR String_to_Screen_Buffer

Draw_1P_Lives
	LDX Counter
	LDA player.lives,X
	SEC
	SBC #1
	BPL Draw_LivesDigit
	LDA #0

Draw_LivesDigit
	JSR ByteTo_Num_String
	LDY #$36
	LDX #$19
	JSR PtrToNonzeroStrElem
	LDA Counter
	STA Temp
	ASL
	CLC
	ADC Temp
	CLC
	ADC #$12
	TAY
	JSR Save_Str_To_ScrBuffer
	DEC Counter
	BPL Draw_1P_Lives
	LDA #0
	STA Char_Index_Base
	STA byte_6B
	RTS


Draw_IP
	LDA #>string.I_p
	STA HighPtr_Byte
	LDA #<string.I_p
	STA LowPtr_Byte
	LDX #$1D
	LDY #$11
	JSR String_to_Screen_Buffer
	LDA Level_Mode
	CMP #2
	BEQ Draw_IIP
	LDA CursorPos
	BEQ +

Draw_IIP
	LDA #>string.II_p
	STA HighPtr_Byte
	LDA #<string.II_p
	STA LowPtr_Byte
	LDX #$1D
	LDY #$14
	JSR String_to_Screen_Buffer

+
	RTS


Draw_LevelFlag
	JSR NMI_Wait
	LDA #>string.LevelFlag_Upper_Icons
	STA HighPtr_Byte
	LDA #<string.LevelFlag_Upper_Icons
	STA LowPtr_Byte
	LDX #$1D
	LDY #$17
	JSR String_to_Screen_Buffer
	LDA #>string.LevelFlag_Lower_Icons
	STA HighPtr_Byte
	LDA #<string.LevelFlag_Lower_Icons
	STA LowPtr_Byte
	LDX #$1D
	LDY #$18
	JSR String_to_Screen_Buffer
	LDA #$6E
	STA Char_Index_Base
	LDA Level_Number
	JSR ByteTo_Num_String
	LDY #$36
	LDX #$19
	JSR PtrToNonzeroStrElem
	LDY #$19
	JSR Save_Str_To_ScrBuffer
	LDA #0
	STA Char_Index_Base
	RTS


PointAt_RightScrnColumn
	PHA
	AND #1
	CLC
	ADC #29
	TAX
	PLA
	LSR
	CLC
	ADC #3
	TAY
	RTS


ReinforceToRAM
	JSR PointAt_RightScrnColumn
	LDA #>string.Reinforcement_Icons
	STA HighPtr_Byte
	LDA #<string.Reinforcement_Icons
	STA LowPtr_Byte
	JSR String_to_Screen_Buffer
	RTS

Draw_EmptyTile
	JSR PointAt_RightScrnColumn
	LDA #>string.Empty_Tile
	STA HighPtr_Byte
	LDA #<string.Empty_Tile
	STA LowPtr_Byte
	JSR String_to_Screen_Buffer
	RTS


Draw_Reinforcemets
	LDA #18
	STA Counter

-
	LDA Counter
	JSR ReinforceToRAM
	DEC Counter
	DEC Counter
	BPL -
	RTS

Check_BorderReach
	LDA tank.x
	CMP #$D8
	BCC +
	LDA #$D8
	STA tank.x

+
	LDA tank.x
	CMP #$18
	BCS ++
	LDA #$18
	STA tank.x

++
	LDA tank.y
	CMP #$D8
	BCC +++
	LDA #$D8
	STA tank.y

+++
	LDA tank.y
	CMP #$18
	BCS End_Check_BorderReach
	LDA #$18
	STA tank.y

End_Check_BorderReach
	RTS

Draw_Pause
	LDA Pause_Flag
	BEQ End_Draw_Pause
	LDA Frame_Counter
	AND #$10
	BEQ End_Draw_Pause
	LDA #3
	STA TSA_Pal
	LDA #0
	STA Spr_Attrib
	LDX #$64
	LDY #$80
	LDA #$17
	STA Spr_TileIndex
	JSR SaveSprTo_SprBuffer
	LDX #$6C
	LDY #$80
	LDA #$19
	STA Spr_TileIndex
	JSR SaveSprTo_SprBuffer
	LDX #$74
	LDY #$80
	LDA #$1B
	STA Spr_TileIndex
	JSR SaveSprTo_SprBuffer
	LDX #$7C
	LDY #$80
	LDA #$1D
	STA Spr_TileIndex
	JSR SaveSprTo_SprBuffer
	LDX #$84
	LDY #$80
	LDA #$1F
	STA Spr_TileIndex
	JSR SaveSprTo_SprBuffer
	LDA #$20
	STA Spr_Attrib

End_Draw_Pause
	RTS

Draw_Fixed_GameOver
	LDA #3
	STA TSA_Pal
	LDA #0
	STA Spr_Attrib
	LDX gameOverStr.x
	LDY gameOverStr.y
	LDA #$79
	STA Spr_TileIndex
	JSR Draw_WholeSpr
	LDA gameOverStr.x
	CLC
	ADC #$10
	TAX
	LDY gameOverStr.y
	LDA #$7D
	STA Spr_TileIndex
	JSR Draw_WholeSpr
	LDA #$20
	STA Spr_Attrib
	RTS

GameOver_Str_Move_Handle
	LDA gameOverStr.timer
	BEQ End_GameOver_Str_Move
	LDA Level_Mode
	CMP #2
	BEQ End_GameOver_Str_Move
	LDA Frame_Counter
	AND #$F
	BNE Check_Motion
	DEC gameOverStr.timer
	BNE Check_Motion

Hide_String
	LDA #$F0
	STA gameOverStr.y

Check_Motion
	LDA gameOverStr.timer
	CMP #10
	BCC Stopped_Motion
	LDA gameOverStr.scrollType
	TAY
	LDA Coord_X_Increment,Y
	CLC
	ADC gameOverStr.x
	STA gameOverStr.x
	LDA Coord_Y_Increment,Y
	CLC
	ADC gameOverStr.y
	STA gameOverStr.y

Stopped_Motion
	JSR Draw_Fixed_GameOver

End_GameOver_Str_Move
	RTS


Make_GrayFrame
	LDA #2
	STA Block_X
	STA Block_Y
	LDA #$1A
	STA Counter
	STA Counter2
	JSR Draw_GrayFrame
	RTS


Title_Screen_Loop
	LDA #3
	STA BkgPal_Number
	JSR Null_Status
	LDA #$48
	STA tank.x
	JSR CurPos_To_PixelCoord
	LDA #$83
	STA tank.status
	LDA #0
	STA Seconds_Counter
	STA tank.type
	STA Track_Pos
	STA player.blinkTimer
	STA player.blinkTimer+1
	STA Scroll_Byte
	STA Joy_Counter
	LDA #2
	STA PPU_REG1_Stts

-
	JSR NMI_Wait
	LDA Frame_Counter
	AND #3
	BNE +
	LDA Track_Pos
	EOR #4
	STA Track_Pos

+
	JSR TanksStatus_Handle
	LDA Joypad1_Differ
	AND #4
	BEQ ++
	INC CursorPos
	LDA #0
	STA Seconds_Counter

++
	LDA Joypad1_Buttons
	AND #$20
	BEQ +++
	LDA Joypad2_Differ
	AND #1
	BEQ +++
	LDA #$10
	CLC
	ADC Joy_Counter
	STA Joy_Counter

+++
	LDA Joypad1_Buttons
	AND #$80
	BEQ Check_Max_CurPos
	LDA Joypad2_Differ
	AND #2
	BEQ Check_Max_CurPos
	DEC Joy_Counter

Check_Max_CurPos
	LDA CursorPos
	CMP #3
	BCC Plus
	LDA #0
	STA CursorPos

Plus
	JSR CurPos_To_PixelCoord
	LDA Seconds_Counter
	CMP #10
	BNE Start_Check
	LDA Construction_Flag
	BNE Start_Check
	RTS

Start_Check
	LDA Joypad1_Differ
	AND #8
	BEQ -
	LDA Construction_Flag
	CMP #7
	BNE Start_Pressed
	LDA Joy_Counter
	CMP #$74
	BNE Start_Pressed
	JSR Show_Secret_Msg

Start_Pressed
	LDA #0
	STA BkgPal_Number
	PLA
	PLA
	LDA CursorPos
	ASL
	TAY
	LDA Title_JumpTable,Y
	STA LowPtr_Byte
	LDA Title_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)
Title_JumpTable
	.DW Selected_1player
	.DW Selected_2players
	.DW Selected_Construction

Selected_1player
	LDA #5
	JMP accept

Selected_2players
	LDA #7
accept
	STA TanksOnScreen
	JSR Null_both_HiScore
	JMP Start_StageSelScrn

Selected_Construction
	LDA #7
	STA TanksOnScreen
	JMP Construction

CurPos_To_PixelCoord
	LDA CursorPos
	ASL
	ASL
	ASL
	ASL
	CLC
	ADC #$8B
	STA tank.y
	RTS

Draw_StageNumString
	JSR NMI_Wait
	LDX #$C
	LDY #$E
	JSR CoordTo_PPUaddress
	LDX ScrBuffer_Pos
	CLC
	ADC #$1C
	STA Screen_Buffer,X
	INX
	TYA
	STA Screen_Buffer,X
	INX
	LDA #$23
	STA Screen_Buffer,X
	INX
	LDA #$24
	STA Screen_Buffer,X
	INX
	LDA #$25
	STA Screen_Buffer,X
	INX
	LDA #$26
	STA Screen_Buffer,X
	INX
	LDA #$27
	STA Screen_Buffer,X
	INX
	LDA #$11
	STA Screen_Buffer,X
	INX
	LDA #$11
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	LDA #$6E
	STA Char_Index_Base
	LDA Level_Number
	JSR ByteTo_Num_String
	LDY #Num_String+1
	LDX #$E
	JSR PtrToNonzeroStrElem
	LDY #$E
	JSR Save_Str_To_ScrBuffer
	LDA #0
	STA Char_Index_Base
	RTS

DraW_Normal_HQ
	LDA #>string.Normal_HQ_TSA
	STA HighPtr_Byte
	LDA #<string.Normal_HQ_TSA
	STA LowPtr_Byte
	LDX #$C
	LDY #$18
	JSR String_to_Screen_Buffer
	LDA #>string.NormalLine2
	STA HighPtr_Byte
	LDA #<string.NormalLine2
	STA LowPtr_Byte
	LDX #$C
	LDY #$19
	JSR String_to_Screen_Buffer
	LDA #>string.NormalLine3
	STA HighPtr_Byte
	LDA #<string.NormalLine3
	STA LowPtr_Byte
	LDX #$C
	LDY #$1A
	JSR String_to_Screen_Buffer
	LDA #>string.Normalline4
	STA HighPtr_Byte
	LDA #<string.Normalline4
	STA LowPtr_Byte
	LDX #$C
	LDY #$1B
	JSR String_to_Screen_Buffer
	LDX ScrBuffer_Pos
	LDA #$23
	STA Screen_Buffer,X
	INX
	LDA #$F3
	STA Screen_Buffer,X
	INX
	LDA #0
	STA NT_Buffer+$3F3
	STA Screen_Buffer,X
	INX
	LDA NT_Buffer+$3F4
	AND #$CC
	STA NT_Buffer+$3F4
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	RTS


Draw_Naked_HQ
	LDA #>string.Naked_HQ_TSA_FirstLine
	STA HighPtr_Byte
	LDA #<string.Naked_HQ_TSA_FirstLine
	STA LowPtr_Byte
	LDX #$E
	LDY #$1A
	JSR String_to_Screen_Buffer
	LDA #>string.Naked_HQ_TSA_SecndLine
	STA HighPtr_Byte
	LDA #<string.Naked_HQ_TSA_SecndLine
	STA LowPtr_Byte
	LDX #$E
	LDY #$1B
	JSR String_to_Screen_Buffer

	LDX ScrBuffer_Pos
	LDA #$23
	STA Screen_Buffer,X
	INX
	LDA #$F3
	STA Screen_Buffer,X
	INX
	LDA NT_Buffer + $3F3
	AND #@111111
	STA NT_Buffer + $3F3
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	RTS

Draw_ArmourHQ
	LDA #>string.Armour_HQ_TSA_Line1
	STA HighPtr_Byte
	LDA #<string.Armour_HQ_TSA_Line1
	STA LowPtr_Byte
	LDX #$C
	LDY #$18
	JSR String_to_Screen_Buffer
	
	LDA #>string.Armour_HQ_TSA_Line2
	STA HighPtr_Byte
	LDA #<string.Armour_HQ_TSA_Line2
	STA LowPtr_Byte
	LDX #$C
	LDY #$19
	JSR String_to_Screen_Buffer
	
	LDA #>string.Armour_HQ_TSA_Line3
	STA HighPtr_Byte
	LDA #<string.Armour_HQ_TSA_Line3
	STA LowPtr_Byte
	LDX #$C
	LDY #$1A
	JSR String_to_Screen_Buffer
	
	LDA #>string.Armour_HQ_TSA_Line4
	STA HighPtr_Byte
	LDA #<string.Armour_HQ_TSA_Line4
	STA LowPtr_Byte
	LDX #$C
	LDY #$1B
	JSR String_to_Screen_Buffer
	
	LDX ScrBuffer_Pos
	LDA #$23
	STA Screen_Buffer,X
	INX
	LDA #$F3
	STA Screen_Buffer,X
	INX
	LDA #$3F
	STA NT_Buffer + $3F3
	STA Screen_Buffer,X
	INX
	LDA NT_Buffer + $3F4
	AND #$CC
	ORA #$33
	STA NT_Buffer + $3F4
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	RTS

Draw_Destroyed_HQ
	LDA #>string.DestroyedHQ_TSA_Line1
	STA HighPtr_Byte
	LDA #<string.DestroyedHQ_TSA_Line1
	STA LowPtr_Byte
	LDX #$E
	LDY #$1A
	JSR String_to_Screen_Buffer
	LDA #>string.DestroyedHQ_TSA_Line2
	STA HighPtr_Byte
	LDA #<string.DestroyedHQ_TSA_Line2
	STA LowPtr_Byte
	LDX #$E
	LDY #$1B
	JSR String_to_Screen_Buffer
	RTS


Copy_AttribToScrnBuff
	LDY #0
	LDA #$23
	STA HighPtr_Byte
	LDA #$C0
	STA LowPtr_Byte

-
	JSR NMI_Wait
	LDX ScrBuffer_Pos
	LDA HighPtr_Byte
	STA Screen_Buffer,X
	INX
	LDA LowPtr_Byte
	STA Screen_Buffer,X
	INX
	LDA NT_Buffer+$3C0,Y
	INY
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	LDA #1
	JSR Inc_Ptr_on_A
	CPY #$40
	BNE -
	RTS

FillScr_Single_Row
	LDX #0
	JSR CoordTo_PPUaddress
	STA HighPtr_Byte
	STY LowPtr_Byte
	LDX ScrBuffer_Pos
	LDA HighPtr_Byte
	CLC
	ADC #$1C
	STA Screen_Buffer,X
	INX
	LDA LowPtr_Byte
	STA Screen_Buffer,X
	INX
	LDY #0

-
	LDA Iterative_Byte
	BNE +
	LDA (LowPtr_Byte),Y

+
	STA Screen_Buffer,X
	INX
	INY
	CPY #$20
	BNE -
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	RTS

FillNT_with_Grey
	LDA #$11
	STA Iterative_Byte
	LDA #0
	STA Block_Y

-
	JSR NMI_Wait
	LDY Block_Y
	JSR FillScr_Single_Row
	LDA #$1D
	SEC
	SBC Block_Y
	TAY
	JSR FillScr_Single_Row
	INC Block_Y
	LDA Block_Y
	CMP #$10
	BNE -
	RTS

FillNT_with_Black
	LDA #0
	STA Iterative_Byte
	LDA #$F
	STA Block_Y

-
	JSR NMI_Wait
	LDY Block_Y
	JSR FillScr_Single_Row
	LDA #$1D
	SEC
	SBC Block_Y
	TAY
	JSR FillScr_Single_Row
	DEC Block_Y
	LDA Block_Y
	CMP #$FF
	BNE -
	RTS


Draw_Pts_Screen
	JSR Draw_Pts_Screen_Template
	LDX #$1E
	JSR DrawTankColumn_XTimes
	LDA Enmy_KlledBy1P_Count
	CLC
	ADC Enmy_KlledBy1P_Count+1
	CLC
	ADC Enmy_KlledBy1P_Count+2
	CLC
	ADC Enmy_KlledBy1P_Count+3
	STA TotalEnmy_KilledBy1P
	LDA Enmy_KlledBy2P_Count
	CLC
	ADC Enmy_KlledBy2P_Count+1
	CLC
	ADC Enmy_KlledBy2P_Count+2
	CLC
	ADC Enmy_KlledBy2P_Count+3
	STA TotalEnmy_KilledBy2P
	LDA #0
	STA Counter

DrawPtsScrn_NxtTank
	JSR NMI_Wait
	JSR Draw_Tank_Column
	LDX #Temp_1PPts_String
	JSR Null_8Bytes_String
	LDX #Temp_2PPts_String
	JSR Null_8Bytes_String
	LDA #0
	STA BrickChar_X
	STA BrickChar_Y

DrawPtsScrn_NxtCount
	JSR NMI_Wait
	JSR Draw_Tank_Column
	LDA #0
	STA EndCount_Flag
	LDX Counter
	LDA TankKill_Pts,X
	JSR Num_To_NumString
	LDX Counter
	LDA Enmy_KlledBy1P_Count,X
	BEQ ++
	LDA #1
	STA Snd_PtsCount1
	STA Snd_PtsCount2
	DEC Enmy_KlledBy1P_Count,X
	INC BrickChar_X
	LDX #2
	JSR Add_Score
	LDA #1
	STA EndCount_Flag
	JSR Add_Life

++
	LDX Counter
	LDA Enmy_KlledBy2P_Count,X
	BEQ +++
	LDA #1
	STA Snd_PtsCount1
	STA Snd_PtsCount2
	DEC Enmy_KlledBy2P_Count,X
	INC BrickChar_Y
	LDX #3
	JSR Add_Score
	LDA #1
	STA EndCount_Flag
	JSR Add_Life

+++
	LDY #HiScore_1P_String+1
	LDX #5
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDX #1
	LDY #Temp_1PPts_String+1
	JSR PtrToNonzeroStrElem
	LDA Counter
	ASL
	CLC
	ADC Counter
	CLC
	ADC #$C
	TAY
	JSR Save_Str_To_ScrBuffer
	LDX Counter
	LDA BrickChar_X
	JSR ByteTo_Num_String
	LDX #8
	LDY #Num_String+1
	JSR PtrToNonzeroStrElem
	LDA Counter
	ASL
	CLC
	ADC Counter
	CLC
	ADC #$C
	TAY
	JSR Save_Str_To_ScrBuffer
	LDA CursorPos
	BEQ +
	LDY #HiScore_2P_String+1
	LDX #$17
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDX #$13
	LDY #Temp_2PPts_String+1
	JSR PtrToNonzeroStrElem
	LDA Counter
	ASL
	CLC
	ADC Counter
	CLC
	ADC #$C
	TAY
	JSR Save_Str_To_ScrBuffer
	LDX Counter
	LDA BrickChar_Y
	JSR ByteTo_Num_String
	LDX #$E
	LDY #Num_String+1
	JSR PtrToNonzeroStrElem
	LDA Counter
	ASL
	CLC
	ADC Counter
	CLC
	ADC #$C
	TAY
	JSR Save_Str_To_ScrBuffer

+
	LDX #8
	JSR DrawTankColumn_XTimes

loc_CDDD
	LDA EndCount_Flag
	BEQ ++++
	JMP DrawPtsScrn_NxtCount

++++
	INC Counter
	LDA Counter
	CMP #4
	BEQ loc_CDF4
	LDX #$14
	JSR DrawTankColumn_XTimes
	JMP DrawPtsScrn_NxtTank

loc_CDF4
	LDX #$1E
	JSR DrawTankColumn_XTimes
	LDA TotalEnmy_KilledBy1P
	JSR ByteTo_Num_String
	LDY #Num_String+1
	LDX #8
	JSR PtrToNonzeroStrElem
	LDY #$17
	JSR Save_Str_To_ScrBuffer
	LDA CursorPos
	BEQ +++++
	LDA TotalEnmy_KilledBy2P
	JSR ByteTo_Num_String
	LDY #Num_String+1
	LDX #$E
	JSR PtrToNonzeroStrElem
	LDY #$17
	JSR Save_Str_To_ScrBuffer

+++++
	LDX #$F
	JSR DrawTankColumn_XTimes
	LDA CursorPos
	BNE DrawPtsScrn_CheckHQ
	JMP End_Draw_Pts_Screen

DrawPtsScrn_CheckHQ
	LDA HQ_Status
	BNE DrawPtsScrn_CheckNum
	JMP End_Draw_Pts_Screen

DrawPtsScrn_CheckNum
	LDA TotalEnmy_KilledBy2P
	CMP TotalEnmy_KilledBy1P
	BCS DrawPtsScrn_CheckLives
	LDA player.lives
	BEQ DrawPtsScrn_CheckLives
	LDA #0
	JSR Num_To_NumString
	LDX #0
	JSR Add_Score
	LDY #HiScore_1P_String+1
	LDX #5
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDY #Num_String+1
	LDX #1
	JSR PtrToNonzeroStrElem
	LDY #$1A
	JSR Save_Str_To_ScrBuffer
	LDA #>string.aBonus
	STA HighPtr_Byte
	LDA #<string.aBonus
	STA LowPtr_Byte
	LDX #3
	LDY #$19
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #8
	LDY #$1A
	JSR String_to_Screen_Buffer
	LDA #1
	STA Snd_BonusPts
	STA byte_31C
	STA byte_31D
	JSR Add_Life
	JMP End_Draw_Pts_Screen

DrawPtsScrn_CheckLives
	LDA TotalEnmy_KilledBy1P
	CMP TotalEnmy_KilledBy2P
	BCS End_Draw_Pts_Screen
	LDA player.lives + 1
	BEQ End_Draw_Pts_Screen
	LDA #0
	JSR Num_To_NumString
	LDX #1
	JSR Add_Score
	LDY #HiScore_2P_String+1
	LDX #$17
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDY #Num_String+1
	LDX #$14
	JSR PtrToNonzeroStrElem
	LDY #$1A
	JSR Save_Str_To_ScrBuffer
	LDA #>string.aBonus
	STA HighPtr_Byte
	LDA #<string.aBonus
	STA LowPtr_Byte
	LDX #$16
	LDY #$19
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #$1B
	LDY #$1A
	JSR String_to_Screen_Buffer
	LDA #1
	STA Snd_BonusPts
	STA byte_31C
	STA byte_31D
	JSR Add_Life

End_Draw_Pts_Screen
	LDX #Enmy_KlledBy2P_Count+1
	JSR DrawTankColumn_XTimes
	LDA #0
	STA PPU_REG1_Stts
	STA Char_Index_Base
	STA byte_6B
	LDA #0
	STA BkgPal_Number
	RTS

Draw_Pts_Screen_Template
	JSR NMI_Wait
	LDA #1
	STA byte_6B
	LDA #$24
	STA PPU_Addr_Ptr
	LDA #0
	STA Scroll_Byte
	LDA #@10
	STA PPU_REG1_Stts
	LDA #$30
	STA Char_Index_Base
	LDA #3
	STA BkgPal_Number
	JSR Screen_Off
	JSR Null_NT_Buffer
	JSR Fill_Attrib_Table
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	LDA #>string.aHikscore
	STA HighPtr_Byte
	LDA #<string.aHikscore
	STA LowPtr_Byte
	LDX #8
	LDY #3
	JSR String_to_Screen_Buffer
	LDY #HiScore_String+1
	LDX #$12
	JSR PtrToNonzeroStrElem
	LDY #3
	JSR Save_Str_To_ScrBuffer
	LDA #>string.aStage
	STA HighPtr_Byte
	LDA #<string.aStage
	STA LowPtr_Byte
	LDX #$C
	LDY #5
	JSR String_to_Screen_Buffer
	LDA Level_Number
	JSR ByteTo_Num_String
	LDY #Num_String+1
	LDX #$E
	JSR PtrToNonzeroStrElem
	LDY #5
	JSR Save_Str_To_ScrBuffer
	JSR NMI_Wait
	LDA #>string.aKplayer
	STA HighPtr_Byte
	LDA #<string.aKplayer
	STA LowPtr_Byte
	LDX #3
	LDY #7
	JSR String_to_Screen_Buffer
	LDY #HiScore_1P_String+1
	LDX #5
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDA #>string.Arrow_Left
	STA HighPtr_Byte
	LDA #<string.Arrow_Left
	STA LowPtr_Byte
	LDX #$E
	LDY #$C
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Left
	STA HighPtr_Byte
	LDA #<string.Arrow_Left
	STA LowPtr_Byte
	LDX #$E
	LDY #$F
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Left
	STA HighPtr_Byte
	LDA #<string.Arrow_Left
	STA LowPtr_Byte
	LDX #$E
	LDY #$12
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Left
	STA HighPtr_Byte
	LDA #<string.Arrow_Left
	STA LowPtr_Byte
	LDX #$E
	LDY #$15
	JSR String_to_Screen_Buffer
	LDA CursorPos
	BEQ Skip_ScndPlayerDraw
	JSR NMI_Wait
	LDA #>string.a_kplayer
	STA HighPtr_Byte
	LDA #<string.a_kplayer
	STA LowPtr_Byte
	LDX #$15
	LDY #7
	JSR String_to_Screen_Buffer
	LDY #HiScore_2P_String+1
	LDX #$17
	JSR PtrToNonzeroStrElem
	LDY #9
	JSR Save_Str_To_ScrBuffer
	LDA #>string.Arrow_Right
	STA HighPtr_Byte
	LDA #<string.Arrow_Right
	STA LowPtr_Byte
	LDX #$11
	LDY #$C
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Right
	STA HighPtr_Byte
	LDA #<string.Arrow_Right
	STA LowPtr_Byte
	LDX #$11
	LDY #$F
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Right
	STA HighPtr_Byte
	LDA #<string.Arrow_Right
	STA LowPtr_Byte
	LDX #$11
	LDY #$12
	JSR String_to_Screen_Buffer
	LDA #>string.Arrow_Right
	STA HighPtr_Byte
	LDA #<string.Arrow_Right
	STA LowPtr_Byte
	LDX #$11
	LDY #$15
	JSR String_to_Screen_Buffer

Skip_ScndPlayerDraw
	JSR NMI_Wait
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #8
	LDY #$C
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #8
	LDY #$F
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #8
	LDY #$12
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #8
	LDY #$15
	JSR String_to_Screen_Buffer
	LDA CursorPos
	BEQ Skip_ScndPlayerPtsDraw
	JSR NMI_Wait
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #$1A
	LDY #$C
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #$1A
	LDY #$F
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #$1A
	LDY #$12
	JSR String_to_Screen_Buffer
	LDA #>string.aPts
	STA HighPtr_Byte
	LDA #<string.aPts
	STA LowPtr_Byte
	LDX #$1A
	LDY #$15
	JSR String_to_Screen_Buffer

Skip_ScndPlayerPtsDraw
	JSR NMI_Wait
	LDA #>string.aLine
	STA HighPtr_Byte
	LDA #<string.aLine
	STA LowPtr_Byte
	LDX #$C
	LDY #$16
	JSR String_to_Screen_Buffer
	LDA #>string.aTotal
	STA HighPtr_Byte
	LDA #<string.aTotal
	STA LowPtr_Byte
	LDX #6
	LDY #$17
	JSR String_to_Screen_Buffer
	RTS

Draw_Tank_Column
	LDA #2
	STA TSA_Pal
	LDY #$64
	LDA #$80
	JSR Draw_Spr_InColumn
	LDY #$7C
	LDA #$A0
	JSR Draw_Spr_InColumn
	LDY #$94
	LDA #$C0
	JSR Draw_Spr_InColumn
	LDY #$AC
	LDA #$E0
	JSR Draw_Spr_InColumn
	RTS

Fill_Attrib_Table
	LDA #$50
	STA NT_Buffer+$3C0
	STA NT_Buffer+$3C1
	STA NT_Buffer+$3C2
	STA NT_Buffer+$3C3
	STA NT_Buffer+$3C8
	STA NT_Buffer+$3C9
	STA NT_Buffer+$3CA
	STA NT_Buffer+$3CD
	STA NT_Buffer+$3CE
	STA NT_Buffer+$3CF
	LDA #$A0
	STA NT_Buffer+$3C4
	STA NT_Buffer+$3C5
	STA NT_Buffer+$3C6
	STA NT_Buffer+$3C7
	LDA #$A
	STA NT_Buffer+$3D0
	STA NT_Buffer+$3D1
	STA NT_Buffer+$3D2
	STA NT_Buffer+$3D5
	STA NT_Buffer+$3D6
	STA NT_Buffer+$3D7
	LDA #5
	STA NT_Buffer+$3F0
	STA NT_Buffer+$3F1
	STA NT_Buffer+$3F2
	STA NT_Buffer+$3F5
	STA NT_Buffer+$3F6
	STA NT_Buffer+$3F7
	RTS

Draw_Spr_InColumn
	STA Spr_TileIndex
	LDX #$81
	JSR Draw_WholeSpr
	RTS

Add_Life
	LDA HQ_Status
	CMP #$80
	BNE End_Add_Life
	LDA player.addLifeFlag
	BNE +
	LDA HiScore_1P_String+2
	CMP #2
	BCC +
	INC player.lives
	INC player.addLifeFlag
	JMP Play_SndAncillaryLife

+
	LDA CursorPos
	BEQ End_Add_Life
	LDA player.addLifeFlag+1
	BNE End_Add_Life
	LDA HiScore_2P_String+2
	CMP #2
	BCC End_Add_Life
	INC player.lives + 1
	INC player.addLifeFlag+1

Play_SndAncillaryLife
	LDA #1
	STA Snd_Ancillary_Life1
	STA Snd_Ancillary_Life2

End_Add_Life
	RTS


Null_Upper_NT
	JSR Screen_Off
	LDA #3
	STA BkgPal_Number
	LDA #$1C
	STA PPU_Addr_Ptr
	JSR Null_NT_Buffer
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	RTS


Draw_TitleScreen
	JSR Screen_Off
	LDA #$24
	STA PPU_Addr_Ptr
	JSR Null_NT_Buffer
	LDX #$1A
	STX Block_X
	LDY #$2E
	STY Block_Y
	LDA #>string.aBattle
	STA HighStrPtr_Byte
	LDA #<string.aBattle
	STA LowStrPtr_Byte
	JSR Draw_BrickStr
	LDX #$3C
	STX Block_X
	LDY #$56
	STY Block_Y
	LDA #>string.aCity
	STA HighStrPtr_Byte
	LDA #<string.aCity
	STA LowStrPtr_Byte
	JSR Draw_BrickStr
	JSR Store_NT_Buffer_InVRAM
	JSR Set_PPU
	LDA #$30
	STA Char_Index_Base
	LDA #>string.aK
	STA HighPtr_Byte
	LDA #<string.aK
	STA LowPtr_Byte
	LDX #2
	LDY #3
	JSR String_to_Screen_Buffer
	LDY #$16
	LDX #4
	JSR PtrToNonzeroStrElem
	LDY #3
	JSR Save_Str_To_ScrBuffer
	LDA #>string.aHik
	STA HighPtr_Byte
	LDA #<string.aHik
	STA LowPtr_Byte
	LDX #$B
	LDY #3
	JSR String_to_Screen_Buffer
	LDY #$3E
	LDX #$E
	JSR PtrToNonzeroStrElem
	LDY #3
	JSR Save_Str_To_ScrBuffer
	LDA CursorPos
	BEQ +
	LDA #>string.a_k
	STA HighPtr_Byte
	LDA #<string.a_k
	STA LowPtr_Byte
	LDX #$15
	LDY #3
	JSR String_to_Screen_Buffer
	LDY #$1E
	LDX #$17
	JSR PtrToNonzeroStrElem
	LDY #3
	JSR Save_Str_To_ScrBuffer

+
	LDA #0
	STA Char_Index_Base
	JSR NMI_Wait
				;
	LDA #>string.a1Player
	STA HighPtr_Byte
	LDA #<string.a1Player
	STA LowPtr_Byte
	LDX #$B
	LDY #$11
	JSR String_to_Screen_Buffer
	LDA #>string.a2Players
	STA HighPtr_Byte
	LDA #<string.a2Players
	STA LowPtr_Byte
	LDX #$B
	LDY #$13
	JSR String_to_Screen_Buffer
	LDA #>string.aConstruction
	STA HighPtr_Byte
	LDA #<string.aConstruction
	STA LowPtr_Byte
	LDX #$B
	LDY #$15
	JSR String_to_Screen_Buffer
	JSR NMI_Wait
	LDA #>string.aNAMCOT
	STA HighPtr_Byte
	LDA #<string.aNAMCOT
	STA LowPtr_Byte
	LDX #$B
	LDY #$17
	JSR String_to_Screen_Buffer
	LDA #>string.Copyrights
	STA HighPtr_Byte
	LDA #<string.Copyrights
	STA LowPtr_Byte
	LDX #4
	LDY #$19
	JSR String_to_Screen_Buffer
	JSR NMI_Wait
	
	LDA #>string.aAllRightsReserved
	STA HighPtr_Byte
	LDA #<string.aAllRightsReserved
	STA LowPtr_Byte
	LDX #6
	LDY #$1B
	JSR String_to_Screen_Buffer
	RTS

DrawTankColumn_XTimes
	JSR NMI_Wait
	TXA
	PHA
	JSR Draw_Tank_Column
	PLA
	TAX
	DEX
	BNE DrawTankColumn_XTimes
	RTS

string.aWrittenBy		.DB "WRITTEN BY",$FF
string.aNAMCOT			.DB "`abcdefgh",$FF
string.aBattle			.DB "BATTLE",$FF
string.aCity			.DB "CITY",$FF
string.aK			.DB $5E,$6B,$FF
string.a_k			.DB $5F,$6B,$FF
string.I_p			.DB $58,$13,$FF
string.II_p			.DB $5A,$13,$FF
string.aHik			.DB "HIk",$FF
string.aHiscore			.DB "HISCORE",$FF
string.aHikscore		.DB "HIkSCORE",$FF
string.a1Player			.DB "1 PLAYER",$FF 
string.a2Players		.DB "2 PLAYERS",$FF
string.aKplayer			.DB "^kPLAYER",$FF
string.a_kplayer		.DB "_kPLAYER",$FF
string.aConstruction		.DB "CONSTRUCTION",$FF
string.Copyrights		.DB "@ 1980 1985 NAMCO LTDi",$FF
string.aThisProgramWas		.DB "THIS PROGRAM WAS", $FF
string.aAllRightsReserved	.DB "ALL RIGHTS RESERVED", $FF
string.aOpenkreach		.DB "OPENkREACH",$FF
string.aDot			.DB $69,$FF
string.PlayerLives_Icon		.DB $14,$FF

string.aGame			.DB "GAME",$FF
string.aOver			.DB "OVER",$FF
string.aWhoLovesNoriko		.DB "WHO LOVES NORIKO",	$FF
string.aPts			.DB "PTS",$FF

string.Reinforcement_Icons	.DB $6A,$6A,$FF
string.LevelFlag_Upper_Icons	.DB $6C,$FC,$FF
string.LevelFlag_Lower_Icons	.DB $6D,$FD,$FF
string.Empty_Tile		.DB $11,$FF

string.Normal_HQ_TSA		.HEX 00 00 00 00 00 00 FF
string.NormalLine2		.HEX 00 0F 0F 0F 0F 00 FF
string.NormalLine3		.HEX 00 0F C8 CA 0F 00 FF
string.Normalline4		.HEX 00 0F C9 CB 0F 00 FF

string.Armour_HQ_TSA_Line1	.HEX 00 00 00 00 00 00 FF
string.Armour_HQ_TSA_Line2	.HEX 00 10 10 10 10 00 FF
string.Armour_HQ_TSA_Line3	.HEX 00 10 C8 CA 10 00 FF
string.Armour_HQ_TSA_Line4	.HEX 00 10 C9 CB 10 00 FF

string.Naked_HQ_TSA_FirstLine		.HEX C8 CA FF
string.Naked_HQ_TSA_SecndLine		.HEX C9 CB FF

string.DestroyedHQ_TSA_Line1		.HEX CC CE FF
string.DestroyedHQ_TSA_Line2		.HEX CD CF FF

string.Arrow_Left			.HEX 5B FF
string.Arrow_Right			.HEX 5D FF

string.aTotal			.DB "TOTAL",$FF
string.aLine			.DB $5C,$5C,$5C,$5C,$5C,$5C,$5C,$5C,$FF
string.aBonus			.DB "BONUS",$15,$FF
string.aStage			.DB "STAGE",$FF

TankKill_Pts			.HEX 10 20 30 40

Coord_X_Increment		.HEX 00 FF 00 01
Coord_Y_Increment		.HEX FF 00 01 00
;
	
	.ORG $D400

NMI
	PHA
	TXA
	PHA
	TYA
	PHA
	PHP
	LDA #0
	STA PPU_SPR_ADDR
	
	LDA #2
	STA SPR_DMA
	
	LDA PPU_STATUS
	JSR Update_Screen
	LDA BkgPal_Number
	BMI Skip_PalLoad
	JSR Load_Bkg_Pal

Skip_PalLoad
	LDA PPU_REG1_Stts
	ORA #@10110000
	STA PPU_CTRL_REG1
	
	LDA #0
	STA PPU_SCROLL_REG
	
	LDA Scroll_Byte
	STA PPU_SCROLL_REG
	
	LDA #@00011110
	STA PPU_CTRL_REG2
	
	JSR Read_Joypads
	JSR Spr_Invisible
	JSR Play_Sound
	
	INC Frame_Counter
	
	LDA Frame_Counter
	AND #$3F
	BNE NMI.End
	INC Seconds_Counter

NMI.End
	PLP
	PLA
	TAY
	PLA
	TAX
	PLA
	RTI

random.GetA
	TXA
	PHA
	LDA random.lowAddr
	ASL
	ASL
	ASL
	SEC
	SBC random.lowAddr
	CLC
	ADC Seconds_Counter
	INC random.highAddr
	LDX random.highAddr
	ADC Temp,X
	STA random.lowAddr
	PLA
	TAX
	LDA random.lowAddr
	RTS


Set_PPU
	JSR VBlank_Wait
	LDA #@10110000
	STA PPU_CTRL_REG1
	RTS


Screen_Off
	JSR NMI_Wait
	LDA #@00010000
	STA PPU_CTRL_REG1
				;
	LDA #@00000110
	STA PPU_CTRL_REG2
	RTS


Null_NT_Buffer			;+清空屏幕
	LDA #0
	TAX
-
	STA NT_Buffer,X
	STA NT_Buffer + $100,X
	STA NT_Buffer + $200,X
	STA NT_Buffer + $300,X
	INX
	BNE -
	RTS
	;-清空屏幕

Reset_ScreenStuff		;+重置 Stuff
	LDA #0
	STA Char_Index_Base
	STA byte_6B
	STA ScrBuffer_Pos
	STA SprBuffer_Position
	STA Pause_Flag
	LDA #$FF
	STA BkgPal_Number
	JSR Load_Pals
	LDA #4
	STA Gap
	LDA #$20
	STA Spr_Attrib
	JSR Null_NT_Buffer
	JSR Spr_Invisible
	LDX #HiScore_1P_String
	JSR Null_8Bytes_String
	LDX #HiScore_2P_String
	JSR Null_8Bytes_String
	JSR StaffStr_Check
	BNE HotBoot
	LDX #HiScore_String
	JSR Null_8Bytes_String
	LDA #2
	STA HiScore_String+2
	LDA #0
	STA CursorPos

HotBoot
	LDA #$1C
	STA PPU_Addr_Ptr
	JSR Store_NT_Buffer_InVRAM
	LDA #$24
	STA PPU_Addr_Ptr
	JSR Store_NT_Buffer_InVRAM
	JSR StaffStr_Store
	JSR Sound_Stop
	RTS

StaffStr_Store
	LDX #$F
-
	LDA StaffString,X
	STA StaffString_RAM,X
	DEX
	BPL -
	RTS

StaffStr_Check
	LDX #$F

-
	LDA StaffString_RAM,X
	CMP StaffString,X
	BNE ColdBoot
	DEX
	BPL -
	LDA #1
	RTS

ColdBoot
	LDA #0
	RTS
	;-重置 Stuff

Load_Pals
	JSR VBlank_Wait
	JSR Spr_Pal_Load
	LDA #0
	JSR Load_Bkg_Pal
	RTS


Load_Bkg_Pal
	ASL
	ASL
	ASL
	ASL
	TAX
	LDY #$10
	LDA #$3F
	STA PPU_ADDRESS
	LDA #0
	STA PPU_ADDRESS

-
	LDA PaletteFrame2,X
	STA PPU_DATA
	INX
	DEY
	BNE -
	LDA #$FF
	STA BkgPal_Number
	LDA #$3F
	STA PPU_ADDRESS
	LDA #0
	STA PPU_ADDRESS
	STA PPU_ADDRESS
	STA PPU_ADDRESS
	RTS


Spr_Pal_Load
	LDX #0
	LDY #$10
	LDA #$3F
	STA PPU_ADDRESS
	STY PPU_ADDRESS

-
	LDA SpritePalette,X
	STA PPU_DATA
	INX
	DEY
	BNE -
	RTS
SpritePalette	.HEX 0F 18 27 38 0F 0A 1B 3B 0F 0C 10 20 0F 04 16 20
PaletteFrame2	.HEX 0F 17 06 00 0F 3C 10 12 0F 29 09 0B 0F 00 10 20
LevelPalette	.HEX 0F 17 06 00 0F 3C 12 12 0F 29 09 0B 0F 00 10 20
PaletteFrame1	.HEX 0F 17 06 00 0F 12 3C 12 0F 29 09 0B 0F 00 10 20
TitleScrPalette	.HEX 0F 16 16 30 0F 3C 10 16 0F 29 09 27 0F 00 10 20
LevelSelPalette	.HEX 0F 17 06 00 0F 3C 10 00 0F 29 09 00 0F 00 10 00
		.HEX 0F 0F 06 00 0F 3C 10 00 0F 29 09 00 0F 00 10 00
PaletteMisc1	.HEX 0F 12 06 00 0F 3C 10 00 0F 29 09 00 0F 00 10 00
		.HEX 0F 00 06 00 0F 3C 10 00 0F 29 09 00 0F 00 10 00
PaletteMisc2	.HEX 0F 30 06 00 0F 3C 10 00 0F 29 09 00 0F 00 10 00


VBlank_Wait
-
	LDA PPU_STATUS
	BPL -
	RTS


CoordTo_PPUaddress
	LDA #0
	STA Temp
	TYA
	LSR
	ROR Temp
	LSR
	ROR Temp
	LSR
	ROR Temp
	PHA
	TXA
	ORA Temp
	TAY
	PLA
	ORA #4
	RTS

AttribToScrBuffer
	JSR TSA_Pal_Ops
	LDX ScrBuffer_Pos
	LDA #$23
	STA Screen_Buffer,X
	INX
	TYA
	CLC
	ADC #$C0
	STA Screen_Buffer,X
	INX
	LDA NT_Buffer+$3C0,Y
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	RTS


TSA_Pal_Ops
	LDA TSA_Pal
	JSR OR_Pal
	JSR OR_Pal
	JSR OR_Pal
	STA CHR_Byte
	TYA
	AND #2
	BNE +
	TXA
	AND #2
	BEQ ++
	LDA #$F3
	JMP End_TSA_Pal_Ops

++
	LDA #$FC
	JMP End_TSA_Pal_Ops

+
	TXA
	AND #2
	BEQ +++
	LDA #$3F
	JMP End_TSA_Pal_Ops

+++
	LDA #$CF

End_TSA_Pal_Ops
	STA byte_1
	TYA
	ASL
	AND #$F8
	STA Temp
	TXA
	LSR
	LSR
	CLC
	ADC Temp
	TAY
	LDA byte_1
	EOR #$FF
	AND CHR_Byte
	STA CHR_Byte
	LDA NT_Buffer+$3C0,Y
	AND byte_1
	ORA CHR_Byte
	STA NT_Buffer+$3C0,Y
	RTS

OR_Pal
	ASL
	ASL
	ORA TSA_Pal
	RTS


Read_Joypads
	LDX #1
	STX JOYPAD_PORT1
	LDY #0
	STY JOYPAD_PORT1

--
	STY Temp
	LDY #8

-
	LDA JOYPAD_PORT1,X
	AND #3
	CMP #1
	ROR Temp
	DEY
	BNE -
	LDA Joypad1_Buttons,X
	EOR #$FF
	AND Temp
	STA Joypad1_Differ,X
	LDA Temp
	STA Joypad1_Buttons,X
	DEX
	BPL --
	RTS


String_to_Screen_Buffer
	JSR CoordTo_PPUaddress
	STA HighStrPtr_Byte
	CLC
	ADC PPU_Addr_Ptr
	LDX ScrBuffer_Pos
	STA Screen_Buffer,X
	INX
	TYA
	STA Screen_Buffer,X
	INX
	STA LowStrPtr_Byte
	LDY #0

-
	LDA (LowPtr_Byte),Y
	STA Screen_Buffer,X
	INX
	CMP #$FF
	BEQ +
	STA (LowStrPtr_Byte),Y
	INY
	JMP -

+
	STX ScrBuffer_Pos
	RTS

Save_Str_To_ScrBuffer
	JSR CoordTo_PPUaddress
	CLC
	ADC PPU_Addr_Ptr
	LDX ScrBuffer_Pos
	STA Screen_Buffer,X
	INX
	TYA
	STA Screen_Buffer,X
	INX
	LDY #0

-
	LDA (LowPtr_Byte),Y
	BMI +
	CLC
	ADC Char_Index_Base

+
	STA Screen_Buffer,X
	INX
	CMP #$FF
	BEQ ++
	INY
	JMP -

++
	STX ScrBuffer_Pos
	RTS

GetCoord_InTiles
	JSR XnY_div_8


CoordsToRAMPos
	JSR CoordTo_PPUaddress
	STA HighPtr_Byte
	STY LowPtr_Byte
	LDY #0
	RTS

XnY_div_8
	TYA
	LSR
	LSR
	LSR
	TAY
	TXA
	LSR
	LSR
	LSR
	TAX
	RTS

Get_SprCoord_InTiles
	STX Spr_X
	STY Spr_Y
	JSR GetCoord_InTiles

Temp_Coord_shl
	LDA #1
	STA Temp
	LDA Spr_Y
	AND #4
	BEQ +
	ASL Temp
	ASL Temp

+
	LDA Spr_X
	AND #4
	BEQ ++
	ASL Temp

++
	RTS

Check_Object
	LDA Temp
	ORA #$F0
	AND (LowPtr_Byte),Y
	RTS

Draw_Destroyed_Brick
	LDA Temp
	EOR #$FF
	AND (LowPtr_Byte),Y
	JSR Draw_Tile
	RTS


NT_Buffer_Process_XOR
	LDA (LowPtr_Byte),Y
	AND #@11110000
	BNE +
	LDA Temp
	EOR #$FF
	AND (LowPtr_Byte),Y
	STA (LowPtr_Byte),Y

+
	RTS
	LDA Temp
	ORA (LowPtr_Byte),Y
	JSR Draw_Tile
	RTS


NT_Buffer_Process_OR
	LDA (LowPtr_Byte),Y
	AND #@11110000
	BNE +
	LDA Temp
	ORA (LowPtr_Byte),Y
	STA (LowPtr_Byte),Y
+		RTS


Save_to_VRAM
	LDA HighPtr_Byte
	CLC
	ADC PPU_Addr_Ptr
	STA PPU_ADDRESS
	LDA LowPtr_Byte
	STA PPU_ADDRESS
	LDA (LowPtr_Byte),Y
	STA PPU_DATA
	RTS


Draw_Tile
	STA (LowPtr_Byte),Y
	STX Spr_X
	LDX ScrBuffer_Pos
	LDA HighPtr_Byte
	CLC
	ADC #$1C
	STA Screen_Buffer,X
	INX
	LDA LowPtr_Byte
	STA Screen_Buffer,X
	INX
	LDA (LowPtr_Byte),Y
	STA Screen_Buffer,X
	INX
	LDA #$FF
	STA Screen_Buffer,X
	INX
	STX ScrBuffer_Pos
	LDX Spr_X
	RTS


Inc_Ptr_on_A
	CLC
	ADC LowPtr_Byte
	STA LowPtr_Byte
	BCC +
	INC HighPtr_Byte
+		RTS

Store_NT_Buffer_InVRAM
	LDA #0
	STA LowPtr_Byte
	TAY
	LDA #4
	STA HighPtr_Byte

-
	JSR Save_to_VRAM
	LDA #1
	JSR Inc_Ptr_on_A
	LDA HighPtr_Byte
	CMP #8
	BNE -
	RTS


Draw_GrayFrame
	LDX #0
	LDA #$11

Fill_NTBuffer
	STA NT_Buffer,X
	STA NT_Buffer+$100,X
	STA NT_Buffer+$200,X
	STA NT_Buffer+$300,X
	INX
	BNE Fill_NTBuffer
	LDA #0
	LDX #$C0

Fill_NTAttribBuffer
	STA NT_Buffer+$300,X
	INX
	BNE Fill_NTAttribBuffer
	LDX Block_X
	LDY Block_Y
	JSR CoordTo_PPUaddress
	STA HighPtr_Byte
	STY LowPtr_Byte

Draw_BlackRow
	LDY Counter2
	DEY

--
	LDA #0
	STA (LowPtr_Byte),Y
	DEY
	BPL --
	DEC Counter
	BEQ +
	LDA #$20
	JSR Inc_Ptr_on_A
	JMP Draw_BlackRow

+
	RTS


Draw_TSABlock
	PHA
	STA Temp
	JSR XnY_div_8
	STX Spr_X
	STY Spr_Y
	LDY Temp
	LDA TSABlock_PalNumber,Y
	STA TSA_Pal
	LDY Spr_Y
	JSR AttribToScrBuffer
	LDA Spr_Y
	AND #$FE
	TAY
	LDA Spr_X
	AND #$FE
	TAX
	JSR CoordsToRAMPos
	PLA
	ASL
	ASL
	TAX
	LDA TSA_data_start,X
	INX
	JSR Draw_Tile
	LDA #1
	JSR Inc_Ptr_on_A
	LDA TSA_data_start,X
	INX
	JSR Draw_Tile
	LDA #$1F
	JSR Inc_Ptr_on_A
	LDA TSA_data_start,X
	INX
	JSR Draw_Tile
	LDA #1
	JSR Inc_Ptr_on_A
	LDA TSA_data_start,X
	INX
	JSR Draw_Tile
	RTS


Draw_Char
	STX BrickChar_X
	TAX
	TYA
	CLC
	ADC #$20
	STA BrickChar_Y
	LDA #0
	STA LowPtr_Byte
	LDA #$10
	STA HighPtr_Byte

Add_10
	DEX
	BMI +
	LDA #$10
	JSR Inc_Ptr_on_A
	JMP Add_10

+
	LDA HighPtr_Byte
	STA PPU_ADDRESS
	LDA LowPtr_Byte
	STA PPU_ADDRESS
				;
	LDA PPU_DATA
	LDA #8
	STA Counter

Read_CHRByte
	LDA PPU_DATA
	PHA
	DEC Counter
	BNE Read_CHRByte
				;
				;
	LDA #8
	STA Counter

NextByte
	PLA
	STA CHR_Byte
	LDA #$80
	STA Mask_CHR_Byte

Next_Bit
	LDX BrickChar_X
	LDY BrickChar_Y
	JSR Get_SprCoord_InTiles
	LDA CHR_Byte
	AND Mask_CHR_Byte
	BEQ Empty_Pixel
	JSR NT_Buffer_Process_OR
	JMP ++

Empty_Pixel
	JSR NT_Buffer_Process_XOR

++
	LDA BrickChar_X
	CLC
	ADC #4
	STA BrickChar_X
	LSR Mask_CHR_Byte
	BCC Next_Bit
	LDA BrickChar_X
	SEC
	SBC #$20
	STA BrickChar_X
	LDA BrickChar_Y
	SEC
	SBC #4
	STA BrickChar_Y
	DEC Counter
	BNE NextByte
	RTS


Draw_BrickStr
	LDY #0
	STY String_Position

New_Char
	LDA (LowStrPtr_Byte),Y
	CMP #$FF
	BEQ EOS
	INY
	STY String_Position
	LDX Block_X
	LDY Block_Y
	CLC
	ADC Char_Index_Base
	JSR Draw_Char
	LDA Block_X
	CLC
	ADC #$20
	STA Block_X
	LDY String_Position
	JMP New_Char

EOS
	RTS

NMI_Wait	;+等待NMI
	LDA Frame_Counter
-	CMP Frame_Counter
	BEQ -
	RTS
	;-等待NMI

Update_Screen
	LDX ScrBuffer_Pos
	LDA #0
	STA Screen_Buffer,X
	TAX

-
	CPX ScrBuffer_Pos
	BEQ Update_Screen_End
	LDA Screen_Buffer,X
	INX
	STA PPU_ADDRESS
	LDA Screen_Buffer,X
	INX
	STA PPU_ADDRESS

--
	LDA Screen_Buffer,X
	INX
	CMP #$FF
	BNE ++
	LDA Screen_Buffer,X
	CMP #$FF
	BNE -
	LDA $17F,X

++
	STA PPU_DATA
	JMP --

Update_Screen_End
	LDA #0
	STA ScrBuffer_Pos
	RTS

PtrToNonzeroStrElem
	LDA 0,Y
	BNE +
	INY
	INX
	JMP PtrToNonzeroStrElem

+
	CMP #$FF
	BNE +++
	LDA byte_6B
	BNE ++
	DEX
	DEY

++
	DEX
	DEY

+++
	LDA #0
	STA HighPtr_Byte
	STY LowPtr_Byte
	RTS

Draw_RecordDigit
	LDA #$10
	STA Block_X
	LDA #$64
	STA Block_Y
	LDA #$30
	STA Char_Index_Base
	LDY #HiScore_String

-
	LDA 0,Y
	BNE +
	INY
	LDA Block_X
	CLC
	ADC #$20
	STA Block_X
	JMP -

+
	LDA #0
	STA HighStrPtr_Byte
	STY LowStrPtr_Byte
	JSR Draw_BrickStr
	LDA #0
	STA Char_Index_Base
	RTS

Update_HiScore
	LDX #0
	LDY #0

loc_D981
	LDA HiScore_1P_String,X
	CMP HiScore_String,X
	BNE loc_D98F
	INX
	CPX #7
	BEQ loc_D99E
	JMP loc_D981

loc_D98F
	BMI loc_D99E
	LDX #0

loc_D993
	LDA HiScore_1P_String,X
	STA HiScore_String,X
	INX
	CPX #7
	BNE loc_D993
	LDY #1

loc_D99E
	LDX #0

loc_D9A0
	LDA HiScore_2P_String,X
	CMP HiScore_String,X
	BNE loc_D9AE
	INX
	CPX #7
	BEQ locret_D9BD
	JMP loc_D9A0

loc_D9AE
	BMI locret_D9BD
	LDX #0

loc_D9B2
	LDA HiScore_2P_String,X
	STA HiScore_String,X
	INX
	CPX #7
	BNE loc_D9B2
	LDY #$FF

locret_D9BD
	RTS

Add_Score
	TXA
	ASL
	ASL
	ASL
	CLC
	ADC #6
	TAX
	LDY #6
	CLC

-
	LDA Num_String,Y
	ADC HiScore_1P_String,X
	CMP #$A
	BMI +
	SEC
	SBC #$A
	SEC
	JMP ++

+
	CLC

++
	STA HiScore_1P_String,X
	DEX
	DEY
	BPL -
	RTS

Num_To_NumString
	STA Temp
	LDX #Num_String
	JSR Null_8Bytes_String
	LDA Temp
	BEQ +
	AND #$F
	STA Num_String+5
	LDA Temp
	LSR
	LSR
	LSR
	LSR
	STA Num_String+4
	RTS

+
	LDA #1
	STA Num_String+3
	RTS


Null_8Bytes_String
	LDA #0
	STA 0,X
	STA 1,X
	STA 2,X
	STA 3,X
	STA 4,X
	STA 5,X
	STA 6,X
	LDA #$FF
	STA 7,X
	RTS


ByteTo_Num_String
	STA Temp
	LDX #Num_String
	JSR Null_8Bytes_String
	LDA Temp

Check_Max
	CMP #10
	BCC loc_DA28
	SEC
	SBC #10
	INC Num_String+5
	JMP Check_Max

loc_DA28
	STA Num_String+6
	RTS

SaveSprTo_SprBuffer
	TXA
	STA Spr_X
	CLC
	ADC #3
	TAX
	TYA
	SEC
	SBC #8
	STA Spr_Y
	JSR GetCoord_InTiles
	LDA (LowPtr_Byte),Y
	CMP #$22
	BNE Skip_Attrib
	LDA TSA_Pal
	ORA Spr_Attrib
	STA TSA_Pal

Skip_Attrib
	LDX SprBuffer_Position
	LDA Spr_Y
	STA SprBuffer,X
	LDA Spr_TileIndex
	STA SprBuffer+1,X
	LDA TSA_Pal
	STA SprBuffer+2,X
	LDA Spr_X
	STA SprBuffer+3,X
	TXA
	CLC
	ADC Gap
	STA SprBuffer_Position
	RTS

Indexed_SaveSpr
	ASL
	CLC
	ADC Spr_TileIndex
	STA Spr_TileIndex
	TXA
	SEC
	SBC #5
	TAX
	JSR SaveSprTo_SprBuffer
	RTS

Spr_TileIndex_Add
	ASL
	ASL
	ASL
	CLC
	ADC Spr_TileIndex
	STA Spr_TileIndex

Draw_WholeSpr
	STX Temp_X
	STY Temp_Y
	TXA
	SEC
	SBC #8
	TAX
	JSR SaveSprTo_SprBuffer
	INC Spr_TileIndex
	INC Spr_TileIndex

	LDX Temp_X
	LDY Temp_Y
	JSR SaveSprTo_SprBuffer
	RTS

Spr_Invisible
	LDX SprBuffer_Position
	LDA Gap
	EOR #$FF
	CLC
	ADC #1
	STA Gap

-
	TXA
	CLC
	ADC Gap
	TAX
	LDA #$F0
	STA SprBuffer,X
	CPX #4
	BNE -
	STX SprBuffer_Position
	RTS

Relation_To_Byte
	BEQ End_RelationToByte
	BCS +
	LDA #$FF
	JMP End_RelationToByte
+
	LDA #1

End_RelationToByte
	RTS


TSABlock_PalNumber	; 方格颜色
	.HEX 00 00 00 00 00 03 03 03 03 03 01 02 03 00 00 00

TSA_data_start		; 方格 Tile 数据
	.HEX 00 0F 00 0F 
	.HEX 00 00 0F 0F 
	.HEX 0F 00 0F 00 
	.HEX 0F 0F 00 00 
	.HEX 0F 0F 0F 0F 
	.HEX 20 10 20 10 
	.HEX 20 20 10 10 
	.HEX 10 20 10 20 
	.HEX 10 10 20 20 
	.HEX 10 10 10 10 
	.HEX 12 12 12 12 
	.HEX 22 22 22 22 
	.HEX 21 21 21 21 
	.HEX 00 00 00 00 
	.HEX 00 00 00 00 
	.HEX 00 00 00 00
;
;

Play_Snd_Move
	LDA Snd_Move
	BEQ No_MoveSound
	LDX #0
	JSR Detect_Motion
	BNE End_Play_Snd_Move
	LDX #1
	JSR Detect_Motion
	BNE End_Play_Snd_Move
	LDA #0
	STA Snd_Move
	RTS

No_MoveSound
	LDX #0
	JSR Detect_Motion
	BNE +
	LDX #1
	JSR Detect_Motion
	BEQ End_Play_Snd_Move

+
	LDA #1
	STA Snd_Move

End_Play_Snd_Move
	RTS

Detect_Motion
	LDA Joypad1_Buttons,X
	AND #$F0
	BEQ End_Detect_Motion
	LDA tank.status,X
	BEQ End_Detect_Motion
	LDA #1
	RTS

End_Detect_Motion
	LDA #0
	RTS


Respawn_Handle
	LDA Respawn_Timer
	BEQ +
	DEC Respawn_Timer
	RTS

+
	LDA Enemy_Reinforce_Count
	BEQ End_Respawn_Handle
	LDA TanksOnScreen
	STA Counter

-
	LDX Counter
	LDA tank.status,X
	BNE ++
	LDA Respawn_Delay
	STA Respawn_Timer
	JSR Make_Respawn
	DEC Enemy_Reinforce_Count
	LDA Enemy_Reinforce_Count
	JSR Draw_EmptyTile
	RTS

++
	DEC Counter
	LDA Counter
	CMP #1
	BNE -

End_Respawn_Handle
	RTS

Ice_Move
	LDA Frame_Counter
	AND #1
	BNE +
	LDA Frame_Counter
	AND #3
	BNE End_Ice_Move

+
	LDX #1

-
	LDA tank.status,X
	BPL ++++++
	CMP #$E0
	BCS ++++++
	LDA player.blinkTimer,X
	BEQ +++++
	DEC player.blinkTimer,X
	JMP Usual_Tank

+++++
	LDA player.iceStatus,X
	BPL ++++
	AND #$10
	BNE Usual_Tank

++++
	LDA Joypad1_Buttons,X
	JSR Button_To_DirectionIndex
	STA Temp
	BPL loc_DBB4

Usual_Tank
	LDA #$80
	JSR Rise_TankStatus_Bit
	LDA #8
	ORA tank.status,X
	STA tank.status,X
	JMP ++++++

loc_DBB4
	LDA player.iceStatus,X
	BPL ++
	AND #$1F
	BNE ++
	LDA #$9C
	STA player.iceStatus,X
	LDA #1
	STA Snd_Ice

++
	LDA tank.status,X
	AND #3
	CMP Temp
	BEQ +++
	EOR #2
	CMP Temp
	BEQ +++
	LDA tank.x,X
	CLC
	ADC #4
	AND #$F8
	STA tank.x,X
	LDA tank.y,X
	CLC
	ADC #4
	AND #$F8
	STA tank.y,X

+++
	LDA Temp
	ORA #$A0
	STA tank.status,X

++++++
	DEX
	BPL -

End_Ice_Move
	RTS

Motion_Handle
	LDA #7
	STA Counter
	LDA enemy.freezeTimer
	BEQ Skip_TimerOps
	LDA Frame_Counter
	AND #63
	BNE Skip_TimerOps
	DEC enemy.freezeTimer

Skip_TimerOps
	LDX Counter
	CPX #2
	BCS Enemy
	LDA Frame_Counter
	AND #1
	BNE JumpToStatusHandle
	LDA Frame_Counter
	AND #3
	BNE Motion_Handle_Next
	JMP JumpToStatusHandle

Enemy
	LDA enemy.freezeTimer
	BEQ +
	LDA tank.status,X
	BPL +
	CMP #$E0
	BCC Motion_Handle_Next

+
	LDA tank.type,X
	AND #$F0
	CMP #$A0
	BEQ JumpToStatusHandle
	LDA Counter
	EOR Frame_Counter
	AND #1
	BEQ Motion_Handle_Next

JumpToStatusHandle
	JSR Status_Core

Motion_Handle_Next
	DEC Counter
	BPL Skip_TimerOps
	RTS

Status_Core
	LDA tank.status,X
	LSR
	LSR
	LSR
	AND #@11111110
	TAY
	LDA TankStatus_JumpTable,Y
	STA LowPtr_Byte
	LDA TankStatus_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)

Misc_Status_Handle
	CPX #2
	BCS LoadStts_Misc_Status_Handle
	LDA player.iceStatus,X
	BPL LoadStts_Misc_Status_Handle
	AND #$7F
	BEQ LoadStts_Misc_Status_Handle
	DEC player.iceStatus,X
	LDA Track_Pos,X
	EOR #4
	STA Track_Pos,X
	JMP Check_Obj

LoadStts_Misc_Status_Handle
	LDA tank.status,X
	SEC
	SBC #4
	STA tank.status,X
	AND #$C
	BNE End_Misc_Status_Handle
	LDA #tank.status
	JSR Rise_TankStatus_Bit

End_Misc_Status_Handle
	RTS

Check_TileReach
	CPX #2
	BCC Check_Obj
	LDA tank.x,X
	AND #7
	BNE Check_Obj
	LDA tank.y,X
	AND #7
	BNE Check_Obj
	JSR random.GetA
	AND #$F
	BNE Check_Obj
	JSR Get_RandomDirection
	RTS

Check_Obj
	LDA tank.status,X
	AND #3
	TAY
	LDA Bullet_Coord_Y_Increment_1,Y
	ASL
	ASL
	ASL
	STA byte_59
	LDA Bullet_Coord_Y_Increment_1,Y
	CLC
	ADC tank.y,X
	STA Block_Y
	LDA Bullet_Coord_X_Increment_1,Y
	ASL
	ASL
	ASL
	STA byte_58
	LDA Bullet_Coord_X_Increment_1,Y
	CLC
	ADC tank.x,X
	STA Block_X
	CLC
	ADC byte_58
	CLC
	ADC byte_59
	JSR Compare_Block_X
	TAX
	LDA Block_Y
	CLC
	ADC byte_58
	CLC
	ADC byte_59
	JSR Compare_Block_Y
	TAY
	JSR GetCoord_InTiles
	LDA (LowPtr_Byte),Y
	BMI GetRnd_CheckObj
	BEQ CheckX_Check_Obj
	CMP #$20
	BCC GetRnd_CheckObj

CheckX_Check_Obj
	LDA Block_X
	CLC
	ADC byte_58
	SEC
	SBC byte_59
	JSR Compare_Block_X
	TAX
	LDA Block_Y
	CLC
	ADC byte_59
	SEC
	SBC byte_58
	JSR Compare_Block_Y
	TAY
	JSR GetCoord_InTiles
	LDA (LowPtr_Byte),Y
	BMI GetRnd_CheckObj
	BEQ SaveCoord_Check_Obj
	CMP #$20
	BCC GetRnd_CheckObj

SaveCoord_Check_Obj
	LDX Counter
	LDA Block_X
	STA tank.x,X
	LDA Block_Y
	STA tank.y,X
	JMP TrackHandle_CheckObj

GetRnd_CheckObj
	LDX Counter
	CPX #2
	BCC TrackHandle_CheckObj
	JSR random.GetA
	AND #3
	BEQ CheckTile_Check_Obj
	LDA #$80
	JSR Rise_TankStatus_Bit
	LDA #8
	ORA tank.status,X
	STA tank.status,X

TrackHandle_CheckObj
	LDA Track_Pos,X
	EOR #4
	STA Track_Pos,X
	RTS

CheckTile_Check_Obj
	LDA tank.x,X
	AND #7
	BNE Change_Direction_Check_Obj
	LDA tank.y,X
	AND #7
	BNE Change_Direction_Check_Obj
	LDA #$90
	JSR Rise_TankStatus_Bit

Change_Direction_Check_Obj
	LDA tank.status,X
	EOR #2
	STA tank.status,X
	RTS

Get_RandomStatus
	JSR random.GetA
	AND #1
	BEQ End_Get_RandomStatus
	JSR random.GetA
	AND #1
	BEQ Sbc_Get_RandomStatus
	LDA tank.status,X
	CLC
	ADC #1
	JMP Save_Get_RandomStatus

Sbc_Get_RandomStatus
	LDA tank.status,X
	SEC
	SBC #1

Save_Get_RandomStatus
	AND #3
	ORA #tank.status
	STA tank.status,X
	RTS

End_Get_RandomStatus
	JSR Get_RandomDirection
	RTS

Compare_Block_X
	CMP Block_X
	BCC +
	SEC
	SBC #1

+
	RTS

Compare_Block_Y
	CMP Block_Y
	BCC +
	SEC
	SBC #1

+
	RTS

Aim_FirstPlayer
	LDA tank.x
	STA AI_X_Aim
	LDA tank.y
	STA AI_Y_Aim
	JMP Save_AI_ToStatus

Aim_ScndPlayer
	LDA tank.x+1
	STA AI_X_Aim
	LDA tank.y+1
	STA AI_Y_Aim
	JMP Save_AI_ToStatus

Aim_HQ
	LDA #$78
	STA AI_X_Aim
	LDA #$D8
	STA AI_Y_Aim

Save_AI_ToStatus
	JSR Load_AI_Status
	STA tank.status,X
	RTS


Load_AI_Status
	LDA AI_X_Aim
	SEC
	SBC tank.x,X
	JSR Relation_To_Byte
	CLC
	ADC #1
	STA AI_X_DifferFlag
	LDA AI_Y_Aim
	SEC
	SBC tank.y,X
	JSR Relation_To_Byte
	CLC
	ADC #1
	STA AI_Y_DifferFlag
	ASL
	CLC
	ADC AI_Y_DifferFlag
	CLC
	ADC AI_X_DifferFlag
	STA AI_X_DifferFlag
	CPX #2
	BCS Load_AIStatus_GetRandom
	TXA
	ASL
	EOR Seconds_Counter
	AND #2
	BEQ loc_DDE4
	JMP LoadSecondPart

Load_AIStatus_GetRandom
	JSR random.GetA
	AND #1
	BEQ loc_DDE4

LoadSecondPart
	LDA #9
	CLC
	ADC AI_X_DifferFlag
	TAY
	JMP End_Load_AIStatus

loc_DDE4
	LDY AI_X_DifferFlag

End_Load_AIStatus
	LDA AI_Status,Y
	RTS

Explode_Handle
	DEC tank.status,X
	LDA tank.status,X
	AND #$F
	BNE End_Explode_Handle
	LDA tank.status,X
	SEC
	SBC #$10
	BEQ Skip_Explode_Handle
	CMP #$10
	BNE SkipRiseBit_Explode_Handle
	ORA #6
	JMP SaveStts_Explode_Handle

SkipRiseBit_Explode_Handle
	ORA #3

SaveStts_Explode_Handle
	STA tank.status,X
	RTS

Skip_Explode_Handle
	STA tank.status,X
	CPX #2
	BCS Dec_Enemy_Explode_Handle
	DEC player.lives,X
	BEQ CheckHQ_Explode_Handle
	JSR Make_Respawn
	RTS

Dec_Enemy_Explode_Handle
	DEC Enemy_Counter
	RTS

CheckHQ_Explode_Handle
	LDA HQ_Status
	CMP #$80
	BNE End_Explode_Handle
	CPX #1
	BEQ Check1pLives_Explode_Handle
	LDA player.lives + 1
	BEQ End_Explode_Handle
	LDA #3
	STA gameOverStr.scrollType
	LDA #$20
	STA gameOverStr.x
	JSR Init_GameOver_Properties
	RTS

Check1pLives_Explode_Handle
	LDA player.lives
	BEQ End_Explode_Handle
	LDA #1
	STA gameOverStr.scrollType
	LDA #$C0
	STA gameOverStr.x
	JSR Init_GameOver_Properties

End_Explode_Handle
	RTS


Init_GameOver_Properties
	LDA #$D
	STA gameOverStr.timer
	LDA #$D8
	STA gameOverStr.y
	LDA #0
	STA Frame_Counter
	RTS

Set_Respawn
	INC tank.status,X
	LDA tank.status,X
	AND #$F
	CMP #$E
	BNE End_Set_Respawn
	LDA #$E0
	STA tank.status,X

End_Set_Respawn
	RTS

Load_Tank
	INC tank.status,X
	LDA tank.status,X
	AND #$F
	CMP #$E
	BNE End_Load_Tank
	JSR Load_New_Tank

End_Load_Tank
	RTS

Get_RandomDirection
	LDA Respawn_Delay
	LSR
	LSR
	CMP Seconds_Counter
	BCS ++++
	LDA #$B0
	JMP End_Get_RandomDirection

++++
	LSR
	CMP Seconds_Counter
	BCC +
	JSR random.GetA
	AND #3
	ORA #$A0
	STA tank.status,X
	RTS

+
	LDA tank.status
	BEQ ++
	TXA
	AND #1
	BEQ +++
	LDA tank.status+1
	BEQ +++

++
	LDA #$C0
	JMP End_Get_RandomDirection

+++
	LDA #$D0

End_Get_RandomDirection
	JSR Rise_TankStatus_Bit
	RTS

TanksStatus_Handle
	LDA #0
	STA Counter

-
	LDX Counter
	JSR SingleTankStatus_Handle
	INC Counter
	LDA Counter
	CMP #8
	BNE -
	RTS

SingleTankStatus_Handle
	LDA tank.status,X
	LSR
	LSR
	LSR
	AND #$FE
	TAY
	LDA TankDraw_JumpTable,Y
	STA LowPtr_Byte
	LDA TankDraw_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)

Draw_Small_Explode2
	LDA #0
	STA Spr_Attrib
	LDA tank.status,X
	PHA
	LDY tank.y,X
	LDA tank.x,X
	TAX
	PLA
	JSR Draw_Bullet_Ricochet
	LDA #$20
	STA Spr_Attrib
	RTS

Draw_Bullet_Ricochet
	LSR
	LSR
	LSR
	LSR
	SEC
	SBC #7
	EOR #$FF
	CLC
	ADC #1
	ASL
	ASL

Draw_Ricochet
	CLC
	ADC #$F1
	STA Spr_TileIndex
	LDA #3
	STA TSA_Pal
	JSR Draw_WholeSpr
	RTS

Draw_Kill_Points
	LDA #0
	STA Spr_Attrib
	LDA tank.type,X
	BEQ Draw_PlayerKill
	LDA tank.type,X
	LSR
	LSR
	LSR
	AND #$FC
	SEC
	SBC #$10
	CLC
	ADC #$B9
	STA Spr_TileIndex
	LDA #3
	STA TSA_Pal
	LDY tank.y,X
	LDA tank.x,X
	TAX
	JSR Draw_WholeSpr
	JMP Draw_Kill_Points_Skip

Draw_PlayerKill
	LDA tank.y,X
	TAY
	LDA tank.x,X
	TAX
	LDA #0
	JSR Draw_Ricochet

Draw_Kill_Points_Skip
	LDA #$20
	STA Spr_Attrib
	RTS

Draw_Small_Explode1
	LDA #0
	STA Spr_Attrib
	LDY tank.y,X
	LDA tank.x,X
	TAX
	LDA #8
	JSR Draw_Ricochet
	LDA #$20
	STA Spr_Attrib
	RTS

Draw_Big_Explode
	LDA #3
	STA TSA_Pal
	LDA #0
	STA Spr_Attrib
	JSR Set_SprIndex
	TXA
	SEC
	SBC #8
	TAX
	TYA
	SEC
	SBC #8
	TAY
	JSR Draw_WholeSpr
	LDA #1
	JSR Set_SprIndex
	TXA
	CLC
	ADC #8
	TAX
	TYA
	SEC
	SBC #8
	TAY
	JSR Draw_WholeSpr
	LDA #2
	JSR Set_SprIndex
	TXA
	SEC
	SBC #8
	TAX
	TYA
	CLC
	ADC #8
	TAY
	JSR Draw_WholeSpr
	LDA #3
	JSR Set_SprIndex
	TXA
	CLC
	ADC #8
	TAX
	TYA
	CLC
	ADC #8
	TAY
	JSR Draw_WholeSpr
	LDA #$20
	STA Spr_Attrib
	RTS


Set_SprIndex
	LDX Counter
	ASL
	ASL
	CLC
	ADC #$D1
	STA Temp
	LDA tank.status,X
	AND #$F0
	SEC
	SBC #$30
	EOR #$10
	CLC
	ADC Temp
	STA Spr_TileIndex
	LDY tank.y,X
	LDA tank.x,X
	TAX
	RTS

OperatingTank
	CPX #2
	BCC OperTank_Player
	LDA tank.type,X
	AND #4
	BEQ OperTank_NotBonus
	LDA Frame_Counter
	LSR
	LSR
	LSR
	AND #1
	CLC
	ADC #2
	JMP OperTank_Draw

OperTank_NotBonus
	LDA Frame_Counter
	ASL
	ASL
	CLC
	ADC tank.type,X
	AND #7
	TAY
	LDA TankType_Pal,Y
	JMP OperTank_Draw

OperTank_Player
	LDA player.blinkTimer,X
	BEQ OperTank_Skip
	LDA Frame_Counter
	AND #8
	BEQ OperTank_Skip
	RTS

OperTank_Skip
	TXA

OperTank_Draw
	STA TSA_Pal
	LDA tank.status,X
	AND #3
	PHA
	LDA tank.type,X
	AND #$F0
	CLC
	ADC Track_Pos,X
	STA Spr_TileIndex
	LDY tank.y,X
	LDA tank.x,X
	TAX
	PLA
	JSR Spr_TileIndex_Add
	RTS
TankType_Pal	.HEX 2 0 0 1 2 1 2 2

Respawn
	LDA tank.status,X
	AND #$F
	SEC
	SBC #7
	BPL loc_E019
	EOR #$FF
	CLC
	ADC #1

loc_E019
	ASL
	AND #$FC
	CLC
	ADC #$A1
	STA Spr_TileIndex
	LDA #3
	STA TSA_Pal
	LDY tank.y,X
	LDA tank.x,X
	TAX
	JSR Draw_WholeSpr
	RTS

AllBulletsStatus_Handle
	LDA #9
	STA Counter

-
	LDX Counter
	JSR BulletStatus_Handle
	DEC Counter
	BPL -
	RTS

BulletStatus_Handle
	LDA bullet.status,X
	LSR
	LSR
	LSR
	AND #$FE
	TAY
	LDA Bullet_Status_JumpTable,Y
	STA LowPtr_Byte
	LDA Bullet_Status_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)

Bullet_Move
	LDA bullet.status,X
	AND #3
	TAY
	JSR Change_BulletCoord
	LDA bullet.property,X
	AND #1
	BEQ End_Bullet_Move
	JSR Change_BulletCoord

End_Bullet_Move
	RTS

Change_BulletCoord
	LDA Bullet_Coord_X_Increment_1,Y
	ASL
	CLC
	ADC bullet.x,X
	STA bullet.x,X
	LDA Bullet_Coord_Y_Increment_1,Y
	ASL
	CLC
	ADC bullet.y,X
	STA bullet.y,X
	RTS

Make_Ricochet
	DEC bullet.status,X
	LDA bullet.status,X
	AND #$F
	BNE End_Animate_Ricochet
	LDA bullet.status,X
	AND #$F0
	SEC
	SBC #$10
	BEQ Skip_Animate_Ricochet
	ORA #3

Skip_Animate_Ricochet
	STA bullet.status,X

End_Animate_Ricochet
	RTS

Make_Shot
	LDA bullet.status,X
	BNE End_Make_Shot
	CPX #2
	BCS +
	LDA #1
	STA Snd_Shoot

+
	LDA tank.status,X
	AND #3
	TAY
	ORA #$40
	STA bullet.status,X
	LDA Bullet_Coord_X_Increment_1,Y
	ASL
	ASL
	ASL
	CLC
	ADC tank.x,X
	STA bullet.x,X
	LDA Bullet_Coord_Y_Increment_1,Y
	ASL
	ASL
	ASL
	CLC
	ADC tank.y,X
	STA bullet.y,X
	LDA #0
	STA bullet.property,X
	LDA tank.type,X
	AND #$F0
	BEQ End_Make_Shot
	CMP #$C0
	BEQ QuickBullet_End_Make_Shot
	CMP #$60
	BEQ ++
	AND #$80
	BNE End_Make_Shot

QuickBullet_End_Make_Shot
	LDA #1
	STA bullet.property,X
	RTS

++
	LDA #3
	STA bullet.property,X

End_Make_Shot
	RTS


Draw_All_BulletGFX
	LDA #bullet.MAX - 1
	STA Counter
-
	LDX Counter
	JSR Draw_BulletGFX
	DEC Counter
	BPL -
	RTS

Draw_BulletGFX
	LDA bullet.status,X
	LSR
	LSR
	LSR
	AND #$FE
	TAY
	LDA BulletGFX_JumpTable,Y
	STA LowPtr_Byte
	LDA BulletGFX_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)

Draw_Bullet		;+绘制子弹
	LDA bullet.status,X
	AND #3
	PHA
	LDY bullet.y,X
	LDA bullet.x,X
	TAX
	LDA #2
	STA TSA_Pal
	LDA #$B1
	STA Spr_TileIndex
	PLA
	JSR Indexed_SaveSpr
	RTS
	;-绘制子弹

Update_Ricochet
	LDA bullet.status,X
	PHA
	LDY bullet.y,X
	LDA bullet.x,X
	TAX
	PLA
	CLC
	ADC #$40
	JSR Draw_Bullet_Ricochet
	RTS

Make_Player_Shot		;+玩家射击
	LDA #player.MAX - 1
	STA Counter
-
	LDX Counter
	LDA tank.status,X
	BPL Next_Jump_Make_Shot
	CMP #$E0
	BCS Next_Jump_Make_Shot
	LDA Joypad1_Differ,X
	AND #@11
	BEQ Next_Jump_Make_Shot
	LDA tank.type,X
	AND #$C0
	CMP #$40
	BNE +
	LDA bullet.status,X
	BEQ +
	LDA bullet.status + tank.MAX,X
	BNE Next_Jump_Make_Shot
	
	;===== 将玩家的第二颗子弹写到第一颗 =====
	LDA bullet.status,X
	STA bullet.status + tank.MAX,X
	LDA bullet.x,X
	STA bullet.x + tank.MAX,X
	LDA bullet.y,X
	STA bullet.y + tank.MAX,X
	LDA bullet.property,X
	STA bullet.property + tank.MAX,X
	LDA #0
	STA bullet.status,X
+
	JSR Make_Shot

Next_Jump_Make_Shot
	DEC Counter
	BPL -
	RTS
	;-玩家射击

Make_Enemy_Shot
	LDA enemy.freezeTimer
	BNE End_Make_Enemy_Shot
	LDX #tank.MAX - 1
-
	LDA tank.status,X
	BPL Next_Make_Enemy_Shot
	CMP #$E0
	BCS Next_Make_Enemy_Shot
	JSR random.GetA
	AND #$1F
	BNE Next_Make_Enemy_Shot
	JSR Make_Shot

Next_Make_Enemy_Shot
	DEX
	CPX #player.MAX - 1
	BNE -

End_Make_Enemy_Shot
	RTS

Ice_Detect		;+坦克在冰面检测
	LDA #tank.MAX - 1
	STA Counter
-
	LDX Counter
	LDA tank.status,X
	BPL Next_Tank
	CMP #$E0
	BCS Next_Tank
	LDA tank.y,X
	SEC
	SBC #8
	TAY
	LDA tank.x,X
	SEC
	SBC #8
	TAX
	JSR GetCoord_InTiles
	LDX Counter
	LDA LowPtr_Byte
	STA NTAddr_Coord_Lo,X
	LDA HighPtr_Byte
	AND #3
	STA NTAddr_Coord_Hi,X
	LDY #$21
	CPX #2
	BCS ++
	LDA (LowPtr_Byte),Y
	CMP #$21
	BNE +
	LDA #$80
	ORA player.iceStatus,X
	STA player.iceStatus,X
	JMP ++
+
	LDA player.iceStatus,X
	AND #$7F
	STA player.iceStatus,X

++
	JSR Rise_Nt_HighBit
	LDA tank.x,X
	AND #7
	BNE +++
	LDA NTAddr_Coord_Hi,X
	ORA #$80
	STA NTAddr_Coord_Hi,X
	LDY #$20
	JSR Rise_Nt_HighBit

+++
	LDA tank.y,X
	AND #7
	BNE Next_Tank
	LDA NTAddr_Coord_Hi,X
	ORA #$40
	STA NTAddr_Coord_Hi,X
	LDY #1
	JSR Rise_Nt_HighBit

Next_Tank
	DEC Counter
	BPL -
	RTS
	;-坦克在冰面检测

Rise_Nt_HighBit
	LDA (LowPtr_Byte),Y
	ORA #$80
	STA (LowPtr_Byte),Y
	RTS


HideHiBit_Under_Tank
	LDA #tank.MAX - 1
	STA Counter
-
	LDX Counter
	LDA tank.status,X
	BPL ++
	CMP #$E0
	BCS ++
	LDA NTAddr_Coord_Lo,X
	STA LowPtr_Byte
	LDA NTAddr_Coord_Hi,X
	AND #3
	ORA #4
	STA HighPtr_Byte
	LDY #$21
	JSR HideHiBit_InBuffer
	LDA NTAddr_Coord_Hi,X
	AND #$80
	BEQ +
	LDY #$20
	JSR HideHiBit_InBuffer
+
	LDA NTAddr_Coord_Hi,X
	AND #$40
	BEQ ++
	LDY #1
	JSR HideHiBit_InBuffer
++
	DEC Counter
	BPL -
	RTS

HideHiBit_InBuffer
	LDA (LowPtr_Byte),Y
	AND #$7F
	STA (LowPtr_Byte),Y
	RTS

Bonus_Draw			;+绘制奖励
	LDA bouns.x
	BEQ End_Bonus_Draw
				;
	LDA BonusPts_TimeCounter
	BEQ Bonus_NotTaken
	DEC BonusPts_TimeCounter
	BNE NotZeroCounter
	LDA #0
	STA bouns.x
	JMP End_Bonus_Draw

NotZeroCounter
	LDA #2
	STA TSA_Pal
	LDA #$3B
	STA Spr_TileIndex
	JMP Draw_Bonus

Bonus_NotTaken
	LDA Frame_Counter
	AND #8
	BEQ End_Bonus_Draw
	LDA #2
	STA TSA_Pal
	LDA bouns.number
	ASL
	ASL
	CLC
	ADC #$81
	STA Spr_TileIndex

Draw_Bonus
	LDX bouns.x
	LDY bouns.y
	LDA #0
	STA Spr_Attrib
	JSR Draw_WholeSpr
	LDA #$20
	STA Spr_Attrib

End_Bonus_Draw
	RTS
	;-绘制奖励

Invisible_Timer_Handle		;+无敌时间检测
	LDA #player.MAX - 1
	STA Counter
-
	LDX Counter
	LDA player.invisibleTimer,X
	BEQ Next_Invisible_Timer_Handle
	LDA Frame_Counter
	AND #$3F
	BNE +
	DEC player.invisibleTimer,X
+
	LDA #2
	STA TSA_Pal
	LDY tank.y,X
	LDA tank.x,X
	TAX
	LDA Frame_Counter
	AND #2
	ASL
	CLC
	ADC #$29
	STA Spr_TileIndex
	JSR Draw_WholeSpr

Next_Invisible_Timer_Handle
	DEC Counter
	BPL -
	RTS
	;-无敌时间检测

HQ_Handle			;+基地检测
	LDA HQArmour_Timer
	BEQ HQ_Explode_Handle
	LDA Frame_Counter
	AND #$F
	BNE HQ_Explode_Handle
	LDA Frame_Counter
	AND #63
	BNE Skip_DecHQTimer
	DEC HQArmour_Timer
	BEQ Normal_HQ_Handle

Skip_DecHQTimer
	LDA HQArmour_Timer
	CMP #4
	BCS HQ_Explode_Handle
	LDA Frame_Counter
	AND #$10
	BEQ Normal_HQ_Handle
	JSR Draw_ArmourHQ
	JMP HQ_Explode_Handle

Normal_HQ_Handle
	JSR DraW_Normal_HQ

HQ_Explode_Handle
	LDA HQ_Status
	BEQ End_HQ_Handle
	BMI End_HQ_Handle
	LDA #3
	STA TSA_Pal
	DEC HQ_Status
	LDA HQ_Status
	LSR
	LSR
	SEC
	SBC #5
	BPL +
	EOR #$FF
	CLC
	ADC #1

+
	SEC
	SBC #5
	BPL ++
	EOR #$FF
	CLC
	ADC #1

++
	ASL
	TAY
	LDA HQExplode_JumpTable,Y
	STA LowPtr_Byte
	LDA HQExplode_JumpTable+1,Y
	STA HighPtr_Byte
	JMP (LowPtr_Byte)
End_HQ_Handle
	RTS
HQExplode_JumpTable
	.DW End_Ice_Move
	.DW FirstExplode_Pic
	.DW SecondExplode_Pic
	.DW ThirdExplode_Pic
	.DW FourthExplode_Pic
	.DW FifthExplode_Pic

FirstExplode_Pic
	LDA #$F1
	JMP Draw_HQSmallExplode

SecondExplode_Pic
	LDA #$F5
	JMP Draw_HQSmallExplode

ThirdExplode_Pic
	LDA #$F9

Draw_HQSmallExplode
	LDX #$78
	LDY #$D8

Draw_SmallExplode
	STA Spr_TileIndex
	JSR Draw_WholeSpr
	RTS


Add_ExplodeSprBase
	CLC
	ADC HQExplode_SprBase
	JMP Draw_SmallExplode

FourthExplode_Pic
	LDA #0
	STA HQExplode_SprBase
	JSR Draw_BigExplode
	RTS

FifthExplode_Pic
	LDA #$10
	STA HQExplode_SprBase
	JSR Draw_BigExplode
	RTS

Draw_BigExplode
	LDX #$70
	LDY #$D0
	LDA #$D1
	JSR Add_ExplodeSprBase
	LDX #$80
	LDY #$D0
	LDA #$D5
	JSR Add_ExplodeSprBase
	LDX #$70
	LDY #$E0
	LDA #$D9
	JSR Add_ExplodeSprBase
	LDX #$80
	LDY #$E0
	LDA #$DD
	JSR Add_ExplodeSprBase
	RTS
	;-基地检测

Make_Respawn
	LDA #0
	STA tank.type,X
	CPX #2
	BCS Enemy_Operations
	
	LDA X_Player_Respawn,X
	STA tank.x,X
	LDA Y_Player_Respawn,X
	STA tank.y,X
	LDA #0
	STA player.blinkTimer,X
	JMP ++

Enemy_Operations
	INC EnemyRespawn_PlaceIndex
	LDY EnemyRespawn_PlaceIndex
	CPY #3
	BNE +
	LDA #0
	STA EnemyRespawn_PlaceIndex
	TAY

+
	LDA X_Enemy_Respawn,Y
	STA tank.x,X
	LDA Y_Enemy_Respawn,Y
	STA tank.y,X
	LDA Enemy_Reinforce_Count
	CMP #3
	BEQ Make_BonusEnemy
	CMP #10
	BEQ Make_BonusEnemy
	CMP #17
	BNE ++

Make_BonusEnemy
	LDA #4
	STA tank.type,X
	LDA #0
	STA bouns.x

++
	LDA #$F0
	STA tank.status,X
	LDY tank.y,X
	LDA tank.x,X
	TAX
	LDA #$F
	JSR Draw_TSABlock
	RTS

Load_New_Tank
	LDA Respawn_Status,X
	STA tank.status,X
	CPX #2
	BCS Load_NewEnemy
	LDA #3
	STA player.invisibleTimer,X
	LDA player.type,X
	JMP ++

Load_NewEnemy
	LDY Enemy_TypeNumber
	LDA Enemy_Count,Y
	BNE +
	INC Enemy_TypeNumber
	JMP Load_NewEnemy

+
	SEC
	SBC #1
	STA Enemy_Count,Y
	LDA Level_Mode
	BEQ +++
	LDA #35
	JMP ++++

+++
	LDA Level_Number

++++
	SEC
	SBC #1
	ASL
	ASL
	CLC
	ADC Enemy_TypeNumber
	TAY
	LDA EnemyType_ROMArray,Y
	CMP #$E0
	BNE ++
	ORA #3

++
	ORA tank.type,X
	CMP #$E7
	BNE End_Load_New_Tank
	LDA #$E4

End_Load_New_Tank
	STA tank.type,X
	LDA #0
	STA Track_Pos,X
	RTS

Hide_All_Bullets
	LDX #9
	LDA #0

-
	STA bullet.status,X
	DEX
	BPL -
	RTS


Null_Status
	LDA #0
	LDX #7
-
	STA tank.status,X
	STA player.iceStatus,X
	DEX
	BPL -
	RTS

Rise_TankStatus_Bit
	STA Temp
	LDA tank.status,X
	AND #$F
	ORA Temp
	STA tank.status,X
	RTS


Load_Enemy_Count
	LDA Level_Mode
	BEQ +
	LDA #35
	JMP ++

+
	LDA Level_Number

++
	SEC
	SBC #1
	ASL
	ASL
	TAY
	LDA Enemy_Amount_ROMArray,Y
	STA Enemy_Count
	LDA Enemy_Amount_ROMArray+1,Y
	STA Enemy_Count+1
	LDA Enemy_Amount_ROMArray+2,Y
	STA Enemy_Count+2
	LDA Enemy_Amount_ROMArray+3,Y
	STA Enemy_Count+3
	RTS

Button_To_DirectionIndex
	ASL
	BCC +
	LDA #3
	RTS

+
	ASL
	BCC ++
	LDA #1
	RTS

++
	ASL
	BCC +++
	LDA #2
	RTS

+++
	ASL
	BCC ++++
	LDA #0
	RTS

++++
	LDA #$FF
	RTS

Bullet_Coord_X_Increment_1	.HEX 00 FF 00 01
Bullet_Coord_Y_Increment_1	.HEX FF 00 01 00
X_Enemy_Respawn			.HEX 18 78 D8
Y_Enemy_Respawn			.HEX 18 18 18
X_Player_Respawn		.HEX 58 98
Y_Player_Respawn		.HEX D8 D8

Respawn_Status	.HEX A0 A0 A2 A2 A2 A2 A2 A2
AI_Status	.HEX A0 A0 A0 A1 A0 A3 A2 A2 A2
		.HEX A1 A0 A3 A1 A0 A3 A1 A2 A3

TankStatus_JumpTable
	.DW End_Ice_Move
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Explode_Handle
	.DW Misc_Status_Handle
	.DW Get_RandomStatus
	.DW Check_TileReach
	.DW Aim_HQ
	.DW Aim_ScndPlayer
	.DW Aim_FirstPlayer
	.DW Load_Tank
	.DW Set_Respawn

TankDraw_JumpTable
	.DW End_Ice_Move
	.DW Draw_Kill_Points
	.DW Draw_Small_Explode1
	.DW Draw_Big_Explode
	.DW Draw_Big_Explode
	.DW Draw_Small_Explode2
	.DW Draw_Small_Explode2
	.DW Draw_Small_Explode2
	.DW OperatingTank
	.DW OperatingTank
	.DW OperatingTank
	.DW OperatingTank
	.DW OperatingTank
	.DW OperatingTank
	.DW Respawn
	.DW Respawn
	
Bullet_Status_JumpTable
	.DW End_Ice_Move
	.DW Make_Ricochet
	.DW Make_Ricochet
	.DW Make_Ricochet
	.DW Bullet_Move
	
BulletGFX_JumpTable
	.DW End_Ice_Move
	.DW Update_Ricochet
	.DW Update_Ricochet
	.DW Update_Ricochet
	.DW Draw_Bullet

EnemyType_ROMArray
	.HEX 80 A0 C0 E0
	.HEX E0 A0 C0 80
	.HEX 80 A0 C0 E0
	.HEX C0 A0 80 E0
	.HEX C0 E0 80 A0
	.HEX C0 A0 80 E0
	.HEX 80 A0 C0 80
	.HEX C0 E0 A0 80
	.HEX 80 A0 C0 E0
	.HEX 80 A0 C0 E0
	.HEX A0 E0 C0 A0
	.HEX C0 A0 80 E0
	.HEX C0 A0 80 E0
	.HEX C0 A0 80 E0
	.HEX 80 C0 A0 E0
	.HEX 80 C0 A0 E0
	.HEX E0 A0 C0 80
	.HEX E0 80 C0 A0
	.HEX A0 E0 80 C0
	.HEX A0 80 C0 E0
	.HEX C0 A0 80 E0
	.HEX A0 80 C0 E0
	.HEX E0 80 C0 A0
	.HEX C0 E0 A0 80
	.HEX C0 A0 80 E0
	.HEX A0 E0 80 C0
	.HEX C0 E0 A0 80
	.HEX A0 E0 80 C0
	.HEX C0 A0 80 E0
	.HEX 80 A0 C0 E0
	.HEX C0 A0 E0 C0
	.HEX E0 80 C0 A0
	.HEX A0 E0 C0 A0
	.HEX C0 A0 80 E0
	.HEX C0 A0 80 E0
;
Enemy_Amount_ROMArray
	.HEX 12 02 00 00
	.HEX 02 04 00 0E
	.HEX 0E 04 00 02
	.HEX 0A 05 02 03
	.HEX 05 02 08 05
	.HEX 07 02 09 02
	.HEX 03 04 06 07
	.HEX 07 02 04 07
	.HEX 06 04 07 03
	.HEX 0C 02 04 02
	.HEX 05 06 04 05
	.HEX 08 06 00 06
	.HEX 08 08 00 04
	.HEX 0A 04 00 06
	.HEX 02 00 0A 08
	.HEX 10 00 02 02
	.HEX 02 02 08 08
	.HEX 04 02 06 08
	.HEX 04 08 04 04
	.HEX 08 02 02 08
	.HEX 08 02 06 04
	.HEX 08 06 02 04
	.HEX 06 00 04 0A
	.HEX 04 02 04 0A
	.HEX 02 08 00 0A
	.HEX 06 06 04 04
	.HEX 02 08 08 02
	.HEX 02 01 0F 02
	.HEX 0A 04 00 06
	.HEX 04 08 04 04
	.HEX 03 08 06 03
	.HEX 08 06 02 04
	.HEX 04 08 04 04
	.HEX 04 0A 00 06
	.HEX 04 06 00 0A


Bullet_Fly_Handle		;+子弹飞行程序
	LDA #bullet.MAX - 1
	STA Counter
-
	LDX Counter
	LDA bullet.status,X
	AND #$F0
	CMP #$40
	BNE Bullet_Fly_Handle.Next
	LDA bullet.property,X
	BNE +
	TXA
	EOR Frame_Counter
	AND #1
	BEQ Bullet_Fly_Handle.Next
+
	LDA bullet.status,X
	AND #3
	TAY
	LDA Bullet_Coord_X_Increment_2,Y
	BPL ++
	EOR #$FF
	CLC
	ADC #1

++
	STA Temp_X
	ASL
	ASL
	STA AI_X_DifferFlag
	LDA Bullet_Coord_Y_Increment_2,Y
	BPL +++
	EOR #$FF
	CLC
	ADC #1

+++
	STA Temp_Y
	ASL
	ASL
	STA AI_Y_DifferFlag
	LDY bullet.y,X
	LDA bullet.x,X
	TAX
	JSR GetSprCoord_InTiles
	BEQ GetCoord_Bullet_Fly_Handle
	LDX Counter
	LDA bullet.y,X
	CLC
	ADC AI_X_DifferFlag
	STA Spr_Y
	LDA bullet.x,X
	CLC
	ADC AI_Y_DifferFlag
	STA Spr_X
	JSR BulletToObject_Impact_Handle

GetCoord_Bullet_Fly_Handle
	LDX Counter
	LDA bullet.y,X
	SEC
	SBC Temp_X
	TAY
	LDA bullet.x,X
	SEC
	SBC Temp_Y
	TAX
	JSR GetSprCoord_InTiles
	BEQ Bullet_Fly_Handle.Next
	LDX Counter
	LDA bullet.y,X
	SEC
	SBC AI_X_DifferFlag
	SEC
	SBC Temp_X
	STA Spr_Y
	LDA bullet.x,X
	SEC
	SBC AI_Y_DifferFlag
	SEC
	SBC Temp_Y
	STA Spr_X
	JSR BulletToObject_Impact_Handle

Bullet_Fly_Handle.Next
	DEC Counter
	BMI Bullet_Fly_Handle.End
	JMP -

Bullet_Fly_Handle.End
	RTS
	;-子弹飞行程序

GetSprCoord_InTiles
	STX Spr_X
	STY Spr_Y
	JSR GetCoord_InTiles

BulletToObject_Impact_Handle		;子弹碰撞物体检测
	JSR Temp_Coord_shl
	JSR Check_Object
	BEQ BulletToObject_Return0
	LDA (LowPtr_Byte),Y
	AND #$FC
	CMP #$C8
	BNE +
	LDA HQ_Status
	BEQ +
	LDA #$27
	STA HQ_Status
	LDA #1
	STA Snd_HQExplode
	STA Snd_PlayerExplode
	JSR Draw_Destroyed_HQ
	LDX Counter
	LDA #$33
	STA bullet.status,X
	JMP BulletToObject_Return0

+
	LDA (LowPtr_Byte),Y
	CMP #$12
	BCS BulletToObject_Return0
	LDX Counter
	LDA #$33
	STA bullet.status,X
	LDA (LowPtr_Byte),Y
	CMP #$11
	BEQ Armored_Wall
	LDA bullet.property,X
	AND #2
	BEQ ++
	LDA #0
	JSR Draw_Tile
	LDA #1
	STA Snd_Brick_Ricochet
	JMP BulletToObject_Return0

++
	LDA (LowPtr_Byte),Y
	CMP #$10
	BEQ Armored_Wall
	CPX #2
	BCS BulletToObject_Return1
	LDA #1
	STA Snd_Brick_Ricochet

BulletToObject_Return1
	JSR Draw_Destroyed_Brick
	LDA #1
	RTS

Armored_Wall
	CPX #2
	BCS BulletToObject_Return0
	LDA #1
	STA Snd_ArmourRicochetWall

BulletToObject_Return0
	LDA #0
	RTS

BulletToTank_Impact_Handle
	LDA #1
	STA Counter

-
	LDX Counter
	LDA tank.status,X
	BPL Jump_Next_Player_Tank_Impact
	CMP #$E0
	BCC +

Jump_Next_Player_Tank_Impact
	JMP Next_Player_Tank_Impact

+
	LDA #7
	STA Counter2

--
	LDY Counter2
	LDA bullet.status,Y
	AND #$F0
	CMP #$40
	BNE Next_Bullet_Tank_Impact
	LDA bullet.x,Y
	SEC
	SBC tank.x,X
	BPL CheckMinX_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinX_TankImpact
	CMP #$A
	BCS Next_Bullet_Tank_Impact
	LDA bullet.y,Y
	SEC
	SBC tank.y,X
	BPL CheckMinY_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinY_TankImpact
	CMP #$A
	BCS Next_Bullet_Tank_Impact
	LDA #$33
	STA bullet.status,Y
	LDA player.invisibleTimer,X
	BEQ Explode_Player_Tank_Impact
	LDA #0
	STA bullet.status,Y
	JMP Next_Bullet_Tank_Impact

Explode_Player_Tank_Impact
	LDA #$73
	STA tank.status,X
	LDA #1
	STA Snd_PlayerExplode
	LDA #0
	STA player.type,X
	STA tank.type,X
	JMP Next_Player_Tank_Impact

Next_Bullet_Tank_Impact
	DEC Counter2
	LDA Counter2
	CMP #1
	BNE --

Next_Player_Tank_Impact
	DEC Counter
	BPL -
	LDA #7
	STA Counter

---
	LDX Counter
	LDA tank.status,X
	BPL JumpNext_Enemy_Tank_Impact
	CMP #$E0
	BCC ++

JumpNext_Enemy_Tank_Impact
	JMP Next_Enemy_Tank_Impact

++
	LDA #9
	STA Counter2

----
	LDA Counter2
	AND #6
	BEQ +++
	JMP Next_Bullet2_Tank_Impact

+++
	LDY Counter2
	LDA bullet.status,Y
	AND #$F0
	CMP #$40
	BEQ Load_X_TankImpact
	JMP Next_Bullet2_Tank_Impact

Load_X_TankImpact
	LDA bullet.x,Y
	SEC
	SBC tank.x,X
	BPL CheckMinX2_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinX2_TankImpact
	CMP #$A
	BCS Next_Bullet2_Tank_Impact
	LDA bullet.y,Y
	SEC
	SBC tank.y,X
	BPL CheckMinY2_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinY2_TankImpact
	CMP #$A
	BCS Next_Bullet2_Tank_Impact
	LDA #$33
	STA bullet.status,Y
	LDA tank.type,X
	AND #4
	BEQ Skip_BonusHandle_TankImpact
	JSR Bonus_Appear_Handle
	LDA tank.type,X
	CMP #$E4
	BNE Skip_BonusHandle_TankImpact
	DEC tank.type,X

Skip_BonusHandle_TankImpact
	LDA tank.type,X
	AND #3
	BEQ Explode_Enemy_Tank_Impact
	DEC tank.type,X
	LDA #1
	STA Snd_ArmourRicochetTank
	JMP Next_Bullet2_Tank_Impact

Explode_Enemy_Tank_Impact
	LDA #$73
	STA tank.status,X
	LDA #1
	STA Snd_EnemyExplode
	LDA tank.type,X
	LSR
	LSR
	LSR
	LSR
	LSR
	SEC
	SBC #4
	TAX
	LDA Counter2
	AND #1
	STA Spr_X
	BNE ScndPlayerKll_Tank_Impact
	INC Enmy_KlledBy1P_Count,X
	JMP Score_TankImpact

ScndPlayerKll_Tank_Impact
	INC Enmy_KlledBy2P_Count,X

Score_TankImpact
	LDA Level_Mode
	CMP #2
	BEQ Next_Enemy_Tank_Impact
	LDA EnemyKill_Score,X
	JSR Num_To_NumString
	LDA Spr_X
	TAX
	JSR Add_Score
	JSR Add_Life
	JMP Next_Enemy_Tank_Impact

Next_Bullet2_Tank_Impact
	DEC Counter2
	BMI Next_Enemy_Tank_Impact
	JMP ----

Next_Enemy_Tank_Impact
	DEC Counter
	LDA Counter
	CMP #1
	BEQ ++++
	JMP ---

++++
	LDA #1
	STA Counter

-----
	LDX Counter
	LDA tank.status,X
	BPL Jump_Next_Player2_Tank_Impact
	CMP #$E0
	BCC +++++

Jump_Next_Player2_Tank_Impact
	JMP Next_Player2_Tank_Impact

+++++
	LDA #9
	STA Counter2

------
	LDA Counter2
	AND #6
	BNE Next_Bullet3_Tank_Impact
	LDY Counter2
	LDA bullet.status,Y
	AND #$F0
	CMP #$40
	BNE Next_Bullet3_Tank_Impact
	LDA Counter
	EOR Counter2
	AND #1
	BEQ Next_Bullet3_Tank_Impact
	LDA bullet.x,Y
	SEC
	SBC tank.x,X
	BPL CheckMinX3_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinX3_TankImpact
	CMP #$A
	BCS Next_Bullet3_Tank_Impact
	LDA bullet.y,Y
	SEC
	SBC tank.y,X
	BPL CheckMinY3_TankImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinY3_TankImpact
	CMP #$A
	BCS Next_Bullet3_Tank_Impact
	LDA #$33
	STA bullet.status,Y
	LDA player.invisibleTimer,X
	BEQ CheckBlink_TankImpact
	LDA #0
	STA bullet.status,Y
	JMP Next_Bullet3_Tank_Impact

CheckBlink_TankImpact
	LDA player.blinkTimer,X
	BNE Next_Bullet3_Tank_Impact
	LDA Level_Mode
	CMP #2
	BEQ Next_Bullet3_Tank_Impact
	LDA #$C8
	STA player.blinkTimer,X
	JMP Next_Player2_Tank_Impact

Next_Bullet3_Tank_Impact
	DEC Counter2
	BPL ------

Next_Player2_Tank_Impact
	DEC Counter
	BPL -----
	RTS
	
EnemyKill_Score	.HEX 10 20 30 40		; 敌人分数

Bonus_Appear_Handle
	LDA #1
	STA Snd_BonusAppears
-
	JSR random.GetA
	AND #3
	JSR Multiply_Bonus_Coord
	STA bouns.x
	JSR random.GetA
	AND #3
	JSR Multiply_Bonus_Coord
	STA bouns.y
	LDA #$FF
	STA bouns.number
	LDA #0
	STA BonusPts_TimeCounter
	JSR Bonus_Handle
	LDA BonusPts_TimeCounter
	BNE -
	JSR random.GetA
	AND #7
	TAY
	LDA BonusNumber_ROM_Array,Y
	STA bouns.number
	LDA #0
	STA BonusPts_TimeCounter
	LDX Counter
	LDY Counter2
	RTS
BonusNumber_ROM_Array	.HEX 0 1 2 3 4 5 4 3

Multiply_Bonus_Coord
	STA Temp
	ASL
	CLC
	ADC Temp
	ASL
	CLC
	ADC #6
	ASL
	ASL
	ASL
	RTS

BulletToBullet_Impact_Handle		;+子弹碰撞子弹检测
	LDA #bullet.MAX - 1
	STA Counter
-
	LDA Counter
	AND #6
	BNE Next_Bullet_Bulllet_Impact
	
	LDX Counter
	LDA bullet.status,X
	AND #$F0
	CMP #$40
	BNE Next_Bullet_Bulllet_Impact
	
	LDA #bullet.MAX - 1
	STA Counter2
--
	LDA Counter2
	TAY
	AND #7
	STA Temp
	
	LDA Counter
	AND #7
	CMP Temp
	BEQ Next_Bullet2_Bulllet_Impact
	
	LDA bullet.status,Y
	AND #$F0
	CMP #$40
	BNE Next_Bullet2_Bulllet_Impact
	
	LDA bullet.x,Y
	SEC
	SBC bullet.x,X
	BPL CheckMinX_BulletImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinX_BulletImpact
	CMP #6
	BCS Next_Bullet2_Bulllet_Impact
	LDA bullet.y,Y
	SEC
	SBC bullet.y,X
	BPL CheckMinY_BulletImpact
	EOR #$FF
	CLC
	ADC #1

CheckMinY_BulletImpact
	CMP #6
	BCS Next_Bullet2_Bulllet_Impact
	LDA #0
	STA bullet.status,X
	STA bullet.status,Y

Next_Bullet2_Bulllet_Impact
	DEC Counter2
	BPL --

Next_Bullet_Bulllet_Impact
	DEC Counter
	BPL -
	RTS

Bullet_Coord_X_Increment_2	.HEX 00 FF 00 01
Bullet_Coord_Y_Increment_2	.HEX FF 00 01 00
	;-子弹碰撞子弹检测

Bonus_Handle				;+检测坦克获取奖励
	LDA bouns.x
	BEQ Bonus_Handle.End
	LDA BonusPts_TimeCounter
	BNE Bonus_Handle.End
	LDA #1
	STA Tank_Num

-
	LDX Tank_Num
	LDA tank.status,X
	BPL +
	CMP #$E0
	BCS +
	LDA tank.x,X
	SEC
	SBC bouns.x
	BPL +++
	EOR #$FF
	CLC
	ADC #1

+++
	CMP #$C
	BCS +
	LDA tank.y,X
	SEC
	SBC bouns.y
	BPL ++
	EOR #$FF
	CLC
	ADC #1

++
	CMP #$C
	BCS +
	LDA #$32
	STA BonusPts_TimeCounter
	LDA bouns.number
	BMI Bonus_Handle.End
	LDA Level_Mode
	CMP #2
	BEQ Bonus_Command
	LDA #$50
	JSR Num_To_NumString
	LDX Tank_Num
	JSR Add_Score
	JSR Add_Life
	LDX Tank_Num
	LDA #1
	STA Snd_BonusTaken

Bonus_Command
	LDA bouns.number
	ASL
	TAY
	LDA Bonus_JumpTable,Y
	STA LowPtr_Byte
	LDA Bonus_JumpTable+1,Y
	STA HighPtr_Byte
	PLA
	PLA
	JMP (LowPtr_Byte)

+
	DEC Tank_Num
	BPL -

Bonus_Handle.End
	RTS
Bonus_JumpTable
	.DW Bonus_Helmet
	.DW Bonus_Watch
	.DW Bonus_Shovel
	.DW Bonus_Star
	.DW Bonus_Grenade
	.DW Bonus_Life
	.DW Bonus_Pistol

Bonus_Helmet
	LDA #10
	STA player.invisibleTimer,X
	RTS

Bonus_Watch
	LDA #10
	STA enemy.freezeTimer
	RTS

Bonus_Shovel
	LDA HQ_Status
	BPL End_Bonus_Shovel
	JSR Draw_ArmourHQ
	LDA #20
	STA HQArmour_Timer

End_Bonus_Shovel
	RTS

Bonus_Star
	LDA player.type,X
	CMP #$60
	BEQ End_Bonus_Star
	CLC
	ADC #$20
	STA player.type,X
	STA tank.type,X

End_Bonus_Star
	RTS

Bonus_Grenade
	LDA #tank.MAX - 1
	STA Counter
	LDA #1
	STA Snd_EnemyExplode

Bonus_Grenade_Loop
	LDY Counter
	LDA tank.status,Y
	BPL Explode_Next
	CMP #$E0
	BCS Explode_Next
	LDA #$73
	STA tank.status,Y
	LDA #0
	STA tank.type,Y

Explode_Next
	DEC Counter
	LDA Counter
	CMP #player.MAX - 1
	BNE Bonus_Grenade_Loop
	RTS

Bonus_Life
	INC player.lives,X
	LDA #1
	STA Snd_Ancillary_Life1
	STA Snd_Ancillary_Life2
Bonus_Pistol
	RTS
	;-检测坦克获取奖励

Sound_Stop
	LDA #@00001111
	STA SND_MASTERCTRL_REG
	LDA #@11000000
	STA JOYPAD_PORT2
	LDA #$1C		;
	STA Low_Ptr_Snd
	LDA #3
	STA High_Ptr_Snd
	LDX #0
	LDY #0

-
	TYA
	STA (Low_Ptr_Snd),Y
	STA Snd_Pause,X
	CLC
	LDA Low_Ptr_Snd
	ADC #8
	STA Low_Ptr_Snd
	BCC +
	INC High_Ptr_Snd

+
	INX
	CPX #28
	BNE -
	RTS

Play_Sound
	LDA Pause_Flag
	BNE loc_EA88
	LDA #$1C
	STA byte_F5
	BPL loc_EA8C

loc_EA88
	LDA #1
	STA byte_F5

loc_EA8C
	LDA #0
	LDX #3

loc_EA90
	STA $F9,X
	DEX
	BPL loc_EA90
	LDA #0
	STA Sound_Number
	LDA #$1C
	STA Low_Ptr_Snd
	LDA #3
	STA High_Ptr_Snd

loc_EAA1
	LDX Sound_Number
	LDA Snd_Pause,X
	BEQ loc_EAE3
	LDY #0
	LDA (Low_Ptr_Snd),Y
	BEQ loc_EAE3
	CMP #5
	BCC loc_EABD
	SEC
	SBC #5
	TAX
	LDA #1
	STA $F9,X
	JMP loc_EAE3

loc_EABD
	TAX
	DEX
	LDA $F9,X
	BNE loc_EAE3
	LDA #1
	STA $F9,X
	TXA
	TAY
	CLC
	ADC #5
	LDY #0
	STA (Low_Ptr_Snd),Y
	TXA
	ASL
	ASL
	TAX
	LDA #4
	STA byte_FD

loc_EAD8
	INY
	LDA (Low_Ptr_Snd),Y
	STA SND_SQUARE1_REG,X
	INX
	DEC byte_FD
	BNE loc_EAD8

loc_EAE3
	CLC
	LDA Low_Ptr_Snd
	ADC #8
	STA Low_Ptr_Snd
	BCC loc_EAEE
	INC High_Ptr_Snd

loc_EAEE
	INC Sound_Number
	LDA Sound_Number
	CMP byte_F5
	BCC loc_EAA1
	LDX #0

loc_EAF8
	STX byte_FD
	LDA $F9,X
	BNE loc_EB0A
	TXA
	ASL
	ASL
	TAX
	ASL
	AND #$10
	EOR #$10
	STA SND_SQUARE1_REG,X

loc_EB0A
	LDX byte_FD
	INX
	CPX #4
	BCC loc_EAF8
	LDY #0
	STY Sound_Number
	LDA #$1C
	STA Low_Ptr_Snd
	LDA #3
	STA High_Ptr_Snd

loc_EB1D
	LDX Sound_Number
	LDA Snd_Pause,X
	BEQ loc_EB2E
	CMP #1
	BNE loc_EB42
	INC Snd_Pause,X
	JMP loc_EB4F

loc_EB2E
	CLC
	LDA Low_Ptr_Snd
	ADC #8
	STA Low_Ptr_Snd
	BCC loc_EB39
	INC High_Ptr_Snd

loc_EB39
	INC Sound_Number
	LDA Sound_Number
	CMP byte_F5
	BCC loc_EB1D
	RTS

loc_EB42
	LDY #7
	LDA (Low_Ptr_Snd),Y
	SEC
	SBC #1
	STA (Low_Ptr_Snd),Y
	BEQ loc_EB85
	BNE loc_EB2E

loc_EB4F
	LDA #0
	LDY #5
	STA (Low_Ptr_Snd),Y
	JSR Load_Snd_Ptr
	JSR sub_ECBE
	LDY #0
	STA (Low_Ptr_Snd),Y
	JSR sub_ECBE
	LDY #1
	STA (Low_Ptr_Snd),Y
	JSR sub_ECBE
	LDY #2
	STA (Low_Ptr_Snd),Y
	JSR sub_ECBE
	LDY #4
	STA (Low_Ptr_Snd),Y
	LDY #0
	LDA (Low_Ptr_Snd),Y
	CMP #4
	BNE loc_EB88
	JSR sub_ECBE
	LDY #3
	STA (Low_Ptr_Snd),Y
	BPL loc_EB88

loc_EB85
	JSR Load_Snd_Ptr

loc_EB88
	JSR sub_ECBE
	CMP #$E8
	BCS loc_EBE1
	CMP #$60
	BEQ loc_EBD7
	BCC loc_EB9E
	SBC #$60
	LDY #6
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

loc_EB9E
	PHA
	AND #$F8
	LSR
	LSR
	TAX
	LDA Snd_Beep,X
	
	STA byte_FD
	LDA Snd_Beep+1,X
	
	STA byte_FE
	PLA
	AND #7
	BEQ loc_EBBB
	TAX

loc_EBB4
	LSR byte_FD
	ROR byte_FE
	DEX
	BNE loc_EBB4

loc_EBBB
	LDY #4
	LDA (Low_Ptr_Snd),Y
	AND #$F8
	ORA byte_FD
	STA (Low_Ptr_Snd),Y
	LDA byte_FE
	DEY
	STA (Low_Ptr_Snd),Y
	LDY #0
	LDA (Low_Ptr_Snd),Y
	CMP #5
	BCC loc_EBD7
	SEC
	SBC #4
	STA (Low_Ptr_Snd),Y

loc_EBD7
	LDY #6
	LDA (Low_Ptr_Snd),Y
	INY
	STA (Low_Ptr_Snd),Y
	JMP loc_EB2E

loc_EBE1
	SBC #$E8
	JSR sub_ECD0
	
Sound_Com_JumpTable
	.DW sound.Com1
	.DW sound.Com2
	.DW sound.Com3
	.DW sound.Com4
	.DW sound.Com5
	.DW sound.Com6
	.DW sound.Com7
	.DW sound.Com8
	.DW sound.Com9
	.DW sound.Com10
	.DW Sound_Com11
	.DW Sound_Com12
	.DW Sound_Com12
	.DW Sound_Com12
	.DW Sound_Com12
	.DW Sound_Com12
	.DW Sound_Com12
	.DW Sound_Com13

sound.Com1
	LDX Sound_Number
	LDA #0
	STA Snd_Pause,X
	LDY #0
	STA (Low_Ptr_Snd),Y
	LDY #5
	LDA (Low_Ptr_Snd),Y
	SEC
	SBC #1
	STA (Low_Ptr_Snd),Y
	JMP loc_EB2E

sound.Com2
	JSR sub_ECBE
	STA byte_FD
	LDY #1
	LDA (Low_Ptr_Snd),Y
	AND #$3F
	ORA byte_FD
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com3
	JSR sub_ECBE
	STA byte_FD
	LDY #1
	LDA (Low_Ptr_Snd),Y
	AND #$C0
	ORA byte_FD
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com4
	JSR sub_ECBE
	STA byte_FD
	LDY #1
	LDA (Low_Ptr_Snd),Y
	AND #Low_Ptr_Snd
	ORA byte_FD
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com5
	JSR sub_ECBE
	LDY #2
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com6
	JSR sub_ECBE
	LDY #4
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com7
	JSR sub_ECBE
	LDY #1
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

sound.Com8
	LDA #0
	LDX #2

loc_EC79
	STA $F6,X
	DEX
	BPL loc_EC79
	JMP loc_EB88

sound.Com9
	LDX #0
	BEQ loc_EC8A

sound.Com10
	LDX #1
	.DB $2C

Sound_Com11
	LDX #2

loc_EC8A
	JSR sub_ECBE
	INC $F6,X
	CMP $F6,X
	BNE Sound_Com13
	LDA #0
	STA $F6,X
	BEQ Sound_Com12

Sound_Com12
	LDY #5
	LDA (Low_Ptr_Snd),Y
	CLC
	ADC #1
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88

Sound_Com13
	JSR sub_ECBE
	LDY #5
	STA (Low_Ptr_Snd),Y
	JMP loc_EB88


Load_Snd_Ptr
	LDA Sound_Number
	ASL
	TAX
	LDA Sound_PtrTbl,X
	STA Low_Ptr_SndData
	LDA Sound_PtrTbl+1,X
	STA High_Ptr_SndData
	RTS

sub_ECBE
	LDA Sound_Number
	LDY #5
	LDA (Low_Ptr_Snd),Y
	TAY
	LDA (Low_Ptr_SndData),Y
	PHA
	INY
	TYA
	LDY #5
	STA (Low_Ptr_Snd),Y
	PLA
	RTS


sub_ECD0
	ASL
	TAY
	INY
	PLA
	STA byte_FD
	PLA
	STA byte_FE
	LDA ($FD),Y
	TAX
	INY
	LDA ($FD),Y
	STA byte_FE
	STX byte_FD
	JMP (byte_FD)


Snd_Beep
	.HEX 07 F2 07 80 07 14 06 AE 06 43 05 F4 05 
	.HEX 9E 05 4E 05 02 04 BA 04 76 04 36

Sound_PtrTbl
	.DW Sound_Pause
	.DW Sound_Battle1
	.DW Sound_Battle2
	.DW sound_Battle3
	.DW sound_Ancillary_Life1
	.DW sound_Ancillary_Life2
	.DW sound_BonusTaken
	.DW sound_PlayerExplode
	.DW sound_Unknown1
	.DW sound_BonusAppears
	.DW sound_EnemyExplode
	.DW sound_HQExplode
	.DW sound_BrickRicochet
	.DW sound_ArmourRicochetWall
	.DW sound_ArmourRicochetTank
	.DW sound_Shoot
	.DW sound_Ice
	.DW sound_Move
	.DW sound_Engine
	.DW sound_PtsCount1
	.DW sound_PtsCount2
	.DW sound_RecordPts1
	.DW sound_RecordPts2
	.DW sound_RecordPts3
	.DW sound_GameOver1
	.DW sound_GameOver2
	.DW sound_GameOver3
	.DW sound_BonusPts
Sound_Battle1			.HEX 01 81 7F 40 EF 68 1B 2B 33 F0 02 06 33 43 53 F0 
				.HEX 02 0C 43 53 04 F0 02 12 5B 0C 1C F0 02 18 78 1C 
				.HEX 68 1C 1C 1C 78 1C E8 
Sound_Battle2			.HEX 03 10 7F 08 78 1A 68 1A F1 03 07 78 32 68 32 F1 
				.HEX 03 0E 78 42 68 42 F1 03 15 5A F1 03 19 0B F1 03 
				.HEX 1D 78 52 68 52 F1 03 24 78 52 E8 
sound_Battle3			.HEX 02 81 7F 40 78 51 68 51 F2 03 07 78 0A 68 0A F2 
				.HEX 03 0E 78 1A 68 1A F2 03 15 32 F2 03 19 42 F2 03 
				.HEX 1D 78 3A 68 3A F2 03 24 78 3A E8 
sound_PlayerExplode		.HEX 04 1F 7F 30 0A 62 49 49 EA 1E 49 49 EA 1D 49 49 
				.HEX EA 1C 49 49 EA 1B 49 49 EA 1A 49 EA 19 49 EA 18 
				.HEX 49 E8 
sound_Unknown1			.HEX 02 1F 7F 30 62 00 01 00 EA 1E 01 00 EA 1D 01 00 
				.HEX 01 00 EA 1C 01 EA 1B 00 EA 1A 01 EA 19 00 E8 
sound_HQExplode			.HEX 02 20 7F 30 63 1A 12 51 31 19 11 50 30 18 E8
sound_EnemyExplode		.HEX 04 1F 7F 40 0A 62 51 EA 1E 51 EA 08 6A 51 E8
sound_Shoot			.HEX 01 8F 82 10 6F 2C E8
sound_BonusTaken		.HEX 02 80 7F 40 63 52 1B 3B 53 4A 13 33 4B 1B 3B 53 1C 3C E8
Sound_Pause			.HEX 02 82 7F 40 64 1B 2B 3B 1C 2C 3C 6C 53 E8
sound_BonusPts			.HEX 02 82 7F 40 63 53 1B 1C 3B 3C 53 6A 54 E8
sound_BonusAppears		.HEX 02 60 7F 40 64 52 3A 52 03 52 03 13 1B E8
sound_ArmourRicochetWall	.HEX 02 D5 7F 00 62 1C 1D E8 
sound_BrickRicochet		.HEX 03 07 7F 08 61 3A 13 22 E8 
sound_ArmourRicochetTank	.HEX 02 40 7F 00 61 3D 62 45 EA 10 28 E8 
sound_PtsCount1			.HEX 02 80 7F 18 61 39 E8 
sound_PtsCount2			.HEX 04 00 7F 28 0A 61 28 E8 
sound_Engine			.HEX 02 8C 94 40 61 10 64 18 F9 05 
sound_Move			.HEX 02 80 94 48 62 40 48 F9 05 
sound_Ice			.HEX 01 1F 7F 28 61 22 42 5A 1B E8 
sound_Ancillary_Life1		.HEX 01 A0 7F 40 66 1C 3C 1C 53 1C 3C 05 72 54 E8 
sound_Ancillary_Life2		.HEX 02 90 7F 40 62 38 66 EA 20 3B 53 3B 1B 3B 53 1C 
				.HEX 6A 14 E8 
sound_RecordPts1		.HEX 01 B8 7F 40 EF 65 0C 53 F0 0C 05 0C 53 F0 0C 0B 
				.HEX 34 24 F0 08 10 EA 30 B0 50 EA 20 9C 54 E8 
sound_RecordPts2		.HEX 02 B8 7F 40 65 43 33 F1 0C 04 43 33 F1 0C 0A 14 
				.HEX 4B F1 08 0F EA 3A 30 50 09 29 31 51 0A 2A 32 52 
				.HEX 0B 2B 33 53 0C 2C 9C EA 20 2C E8 
sound_RecordPts3		.HEX 03 00 7F 08 A1 01 01 EE 15 6A 0B 0B 0B EE 22 6F 
				.HEX 33 65 43 7E EE 33 53 6A EE 15 43 33 53 6F EE 22 
				.HEX 13 65 23 7E EE 33 33 6A EE 15 23 13 4A 9C EE FF 
				.HEX 32 E8 
sound_GameOver1			.HEX 01 42 7F 40 66 1B 0B 78 1B 68 52 42 32 1A 1A 1A 
				.HEX 78 1A E8 
sound_GameOver2			.HEX 02 82 7F 40 66 52 52 78 52 68 32 2A 12 1A 1A 1A 
				.HEX 78 1A E8 
sound_GameOver3			.HEX 03 10 7F 08 66 3B 33 78 3B 68 1B 0B 52 52 52 52 
				.HEX 78 52 E8

	.ORG  $F000

level.Load
	CMP #$FF
	BNE level.Normal
	LDA #$24
	JMP Begin

level.Normal
	CMP #$24
	BCC Begin
	SEC
	SBC #$23

Begin
	STA Temp
	LDA #>level.data
	STA HighPtr_Byte
	LDA #<level.data
	STA LowPtr_Byte

-
	DEC Temp
	BEQ +
	LDA #$5B
	JSR Inc_Ptr_on_A
	JMP -

+
	LDA #0
	STA Counter
	
	LDA LowPtr_Byte
	STA LowStrPtr_Byte
	LDA HighPtr_Byte
	STA HighStrPtr_Byte
	LDA #$10
	STA Block_Y

--
	JSR NMI_Wait
	LDA #$10
	STA Block_X

---
	LDA Counter
	LSR
	TAY
	LDA Counter
	AND #1
	BEQ ++
	LDA (LowStrPtr_Byte),Y
	AND #$F
	JMP +++

++
	LDA (LowStrPtr_Byte),Y
	LSR
	LSR
	LSR
	LSR

+++
	LDX Block_X
	LDY Block_Y
	JSR Draw_TSABlock
	LDA #0
	STA ScrBuffer_Pos
	INC Counter
	LDA Block_X
	CLC
	ADC #$10
	STA Block_X
	CMP #$E0
	BNE ---
	INC Counter
	LDA Block_Y
	CLC
	ADC #$10
	STA Block_Y
	CMP #$E0
	BNE --
	RTS
level.data

	.HEX DD DD DD DD DD DD DD D4 D4 D4 
	.HEX D4 D4 D4 DD D4 D4 D4 D4 D4 D4 
	.HEX DD D4 D4 D4 94 D4 D4 DD D4 D4 
	.HEX D3 D3 D4 D4 DD D3 D3 D1 D1 D3 
	.HEX D3 DD 1D 11 D3 D3 D1 1D 1D 8D 
	.HEX 33 D1 D1 D3 3D 8D D1 D1 D4 44 
	.HEX D1 D1 DD D4 D4 D4 D4 D4 D4 DD 
	.HEX D4 D4 D3 D3 D4 D4 DD D4 D4 DD 
	.HEX DD D4 D4 DD DD DD DD DD DD DD 
	.HEX DD 

	.HEX DD D9 DD D9 DD DD DD D4 D9 DD 
	.HEX D4 D4 D4 DD D4 DD DD 44 D4 94 
	.HEX DD DD D4 DD DD D9 DD DD BD D4 
	.HEX DD 9D D4 B4 9D BB DD D4 DD 9D 
	.HEX BD DD D4 44 BB B9 DD B4 DD DD 
	.HEX D9 B4 D4 D4 D4 DD 94 D9 D4 D4 
	.HEX DD D4 DD D4 D4 D4 44 D4 94 DD 
	.HEX D4 D4 D4 44 DD DD DD D4 DD DD 
	.HEX DD D4 D4 DD D4 D4 DD DD D4 44 
	.HEX DD 
	
	.HEX DD DD 4D DD 4D DD DD DB BB 4D 
	.HEX DD DD 66 6D 4B BB DD DD DD DD 
	.HEX DD BB BB DD D4 D4 44 2D BB BB 
	.HEX 44 43 D4 D0 DD BB BB DD 4D DD 
	.HEX D0 DD DB DD DD 99 9D DB DD D1 
	.HEX D1 DD DD DB BB BD 42 04 20 33 3B 
	.HEX BB BD DD DD D4 D1 1B BB BD 4D 
	.HEX D7 DD D3 3B BB DD 44 D7 DD DD 
	.HEX DB BB DD 94 4D DD DD D4 DD DD 
	.HEX DB BD DD DD DD DB DD BB DD 14 
	.HEX 41 1D DD BD BD D0 44 44 44 1D 
	.HEX 8D 8D D4 44 44 44 42 DD DD 03 DD 
	.HEX D3 44 D2 DD AD 0D 7D 7D 42 DD 
	.HEX DD DD 4D 11 DD 42 DA AD DD 44 
	.HEX 44 44 44 DD DD D0 44 44 44 44 
	.HEX 2D DD D3 34 44 44 43 3D DD D4 
	.HEX 41 34 43 14 4D BD BD 33 DD DD 
	.HEX 33 DB BD 9B DD DD DD DD BB 9D 
	.HEX DD DD 44 4D DD DD DD 6D 1D 4D 
	.HEX DD 88 9D DD 9D 4D DD 4D DD DD 
	.HEX DD 4D 44 4D 44 DA AD AD 3D DD 
	.HEX 3D DD DA DD DD DD 1D AA DA AA 
	.HEX D4 4D 44 DD A4 D4 2D DD DD DD 
	.HEX DD AD DD DD 57 DD AA AD AD 9D 
	.HEX 4D 5D DD DD D1 1D DD DD 54 4D 
	.HEX DD DD 43 33 41 DD DD 44 3D DD 
	.HEX DD D3 4D DD 3D DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD DD D0 D2 BB DD DD D2 5D 2D 
	.HEX DD 0B 20 BD D2 5D 2D 4D 0B 20 BD 
	.HEX D4 DD 4D 9D 4B D4 BD DD D0 8D 
	.HEX 4D 37 DB BD 44 2D DB 4B DD 04 4D 
	.HEX DD DD 0B BB 2D DD DD 94 4D 3B 
	.HEX BB 30 44 9D 88 8D 1D BD 1D 88 
	.HEX 8D D4 DD 4D DD 4D DD DD D4 2D 
	.HEX D3 D3 DD 04 BD DD 3D DD DD DD BB 
	.HEX BD DD 1D DD DD DD 1B BD 
	.HEX DD DD DD D8 8D DD DD DD 98 88 
	.HEX DD DD 9D DD DD 9D DD BD 89 9D 
	.HEX DD D9 DD DB 9D DD 9D DD DD DD 
	.HEX B9 9D DD 89 DD D9 DB 99 9D 9D 
	.HEX DD DD D5 D9 9D DD 99 DD DD 7D 
	.HEX DD 9D 99 9D D5 DD D5 9D DD 99 
	.HEX BD D9 DD D9 DD DD 9B DD 99 DD 
	.HEX D8 89 DD BD D9 DD DD DD DD DD 
	.HEX DD D8 D6 9D 66 DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD 4D D4 D1 D4 DD DD B4 44 D4 
	.HEX D6 D4 2D DD BB BD D3 D4 D3 D0 
	.HEX 2D BA AA AA AA AA AD AD D4 DD 
	.HEX DD 11 DD DD DD DD 4D D0 44 34 
	.HEX 38 8D 44 D4 D0 44 B4 66 4D DD 
	.HEX D9 D6 DB BB BD DD AA DA AA AA 
	.HEX DA AA AD BB D0 DD 11 DD DD DD 
	.HEX BB 4D 2D D0 D6 14 DD B6 4D 2D 
	.HEX DD D3 D4 DD DD DD DD DD D1 D3 
	.HEX DD 
	
	.HEX DD D4 DD DD D6 BD DD 4D DD DD 
	.HEX 6B 59 7D 4D DD D6 B5 97 D8 BD 
	.HEX DD DD 59 7D 8B DD DD DD DD D8 
	.HEX BD DD DD DD DD DD DB 6B DB 6B 
	.HEX DD DD 94 D5 97 D5 97 D4 9D DD 
	.HEX DB 8B DB 8B DD DD DD DD 6D DD 
	.HEX 6D DD DD 4D D5 97 D5 97 DD 4D 
	.HEX 4D DB 8B DB 8B DD 4D DD 1D DD 
	.HEX DD DD 1D DD DD 44 DD DD D4 4D 
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD D0 34 DD 
	.HEX DD DD 43 2D 03 DD 4D BB D4 DD 
	.HEX 0D 4D DD 4B BB B4 DD 0D 4D D0 
	.HEX 4B 99 B4 2D 4D 01 14 AA AA AA 
	.HEX 44 4D D4 44 99 49 94 44 2D DD 
	.HEX 44 9D 4D 94 42 DD DD 44 44 44 
	.HEX 44 42 DD 4B 33 39 93 33 3B 4D 
	.HEX 4B BB BB BB BB BB 4D DD BB B1 
	.HEX 11 BB BB DD DD D2 D4 D4 DD 2D 
	.HEX DD 
	
	.HEX DD DD D9 D4 D4 4D DD D0 44 44 
	.HEX D4 DD DD DD DD D2 D4 D4 4D BB 
	.HEX BD D0 DD DD D9 DB BB BD D0 D4 
	.HEX 44 94 4B B3 9D D3 33 9D D4 DB 
	.HEX BD 0D 04 44 D9 BB BB BD DD DD 
	.HEX D9 DD BB BB B4 DD 94 DB BB B9 
	.HEX BB B4 DD 04 BB BB BD DD D4 2D 
	.HEX D4 BB DD DD 84 44 DD DD BB DD 
	.HEX DD D4 D0 DD D1 BB DD DD DD DD 
	.HEX DD 
	
	.HEX DD DD DD 44 44 DD DD D4 44 1D 
	.HEX 1D D4 DD DD DD DD 4D 3D DD D4 
	.HEX 4D DA AA AA D4 2D D4 8D DD 66 
	.HEX 6A D4 D9 74 DD 4D 44 4A AA DA 
	.HEX 44 DD DD DD 9A DD DA 8D DD AA 
	.HEX AD AA 44 DA DD DD DD DD D4 88 
	.HEX DA AA DD 44 4D DD DD DD DD DD 
	.HEX DD 4D 88 DD D4 4D 0D 4D DD DD 
	.HEX DD D4 DD 4D DD DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD DD 1D DD 1D DD DD D4 44 4D 
	.HEX DD 44 44 DD D4 DD DD 4D DD D9 
	.HEX DD D9 D4 3D DD 34 D4 4D D4 D2 
	.HEX B6 96 B0 D9 4D D3 DD BB BB BD 
	.HEX D8 4D 46 DD BB BB BD D1 4D 49 
	.HEX D2 B8 98 B0 D4 DD 44 D4 1D DD 
	.HEX 14 D9 DD 49 DD DD 4D DD D4 DD 
	.HEX 44 44 4D DD 44 49 9D 44 DD 3D 
	.HEX DD 3D D4 DD 44 DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD BB DD 14 
	.HEX 44 1D DB BD BD D0 44 44 42 DD 
	.HEX BD DD D4 4B 4B 44 DD DD DD D4 
	.HEX BB 4B B4 DD DD BD D4 44 44 44 
	.HEX DD BD BB DD 4B 4B 4D DB BD AA 
	.HEX AD 44 44 4D AA AD DD DD 00 00 
	.HEX 0D DD DD DD DD 22 22 2D DD DD 
	.HEX 55 5D DD DD DD 77 7D 22 2D DD 
	.HEX DD DD 00 0D 77 75 DD DD D7 55 
	.HEX 5D 
	
	.HEX DD DD 44 DD 4D DD DD DB B4 4D 
	.HEX DD 4D DD DD BB BB BB BB 44 DD 
	.HEX DD B8 4B 44 4B BB B4 9D BB 4B 
	.HEX BB 8B B4 74 DD DB B4 6B BB B4 
	.HEX D4 DD D4 44 44 BB 44 2B BD 58 
	.HEX 44 DD D4 3D DD BD D4 D4 D6 13 
	.HEX BB 42 BD D4 DD 04 3B B4 DD BD 
	.HEX D4 42 03 BB 1B 4B BD DD 4D BD 
	.HEX DD 4B 3B DD DD 3D BD DD DB BB 
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD DD 9B 9D 
	.HEX DD DD DD DD DD DB DB 6D DD DD 
	.HEX DD DB DD DD B1 DD DD DD DB BD 
	.HEX DB DB 6D DD DD DB DB DB DD B1 
	.HEX DD DD DB DD BD DD BB 6D DD DD 
	.HEX BD DD DB BB B1 DD DD DB DD BD 
	.HEX BB BB DD 4D DD DD BD DB BB 9D 
	.HEX 44 DD DD DB DB BB BD 94 4D DD 
	.HEX DD BD BB BD 99 44 DD DD BD DB 
	.HEX BD 
	
	.HEX DD DD 1D DD DD 1D DD D4 D4 4D 
	.HEX DC CC 44 DD D4 DD 4D 9C CC CC 
	.HEX DD CC C7 4D D4 CC CC DD CC CC 
	.HEX CC 44 02 DD DD DD 5C CC C4 02 
	.HEX D8 8D 44 44 CC CC CC C4 4D DD 
	.HEX D4 4C CC C7 DD DD D4 44 DC CC 
	.HEX 44 D4 DD CC C4 CD DD D4 D4 DD 
	.HEX CC CC C8 D8 DD 14 DD 4C CC CD
	.HEX DD D4 DD DD 44 7D DD DD D4 D4 
	.HEX DD 
	
	.HEX DD DD DD DD 99 9B DD D4 DD DD 
	.HEX DD 9D D9 DD 4B 4D DD 44 44 D9 
	.HEX DD D4 B4 DD 4D B4 99 DD DD 4D 
	.HEX B9 4B D4 DD DD DD DD 9D 49 44 
	.HEX DD DD DD 44 94 D9 DD DD DD DD 
	.HEX 4D B4 9B DD DD DD 99 9B D4 DD 
	.HEX 44 DD DD 9D 44 44 DD 49 9D DD 
	.HEX 9D D9 DD DD D9 44 DD B9 99 DD 
	.HEX DD DD 49 9D DD DD DD DD DD D9 
	.HEX 9D 
	
	.HEX D4 D4 D4 D4 D4 D4 DD D4 D4 D4 
	.HEX D4 D4 D4 DD D8 D8 D8 D8 D8 D8 
	.HEX DD 1D 1D 4D DD 4D 1D 1D 4D 43 
	.HEX 4D 4D 43 4D 4D 8D 8D 9D 8D 9D 
	.HEX 8D 8D BB DD 4D BD 4D DB BD BB 
	.HEX BB 43 B3 4B BB BD BB BB BB BB 
	.HEX BB BB BD 1D 1D 4B BB 4D 1D 1D 
	.HEX D4 D4 DD BD D4 D4 DD D4 D4 DD 
	.HEX DD D4 D4 DD D3 D3 DD DD D3 D3 
	.HEX DD
	
	.HEX DD DA D4 DD 4D 4D DD DD DD DD 
	.HEX DD 4D 9D DD DD DA D1 9D 4D 4D 
	.HEX DD 8D 4A D9 D1 3D 4D DD DD 4A 
	.HEX DD D4 DD DD DD 4D 4A AD AA AA 
	.HEX DD 4D DD D1 DD DB DA D8 8D 44 
	.HEX 04 D9 BB BA D1 1D 3D 0D D4 BB 
	.HEX BA D4 DD D6 DD D4 DB DA DB DD 
	.HEX D4 D6 D3 33 DD BB BD D4 D4 DD 
	.HEX DD DA BB BD DD DD DD DD DA DB 
	.HEX DD 
	
	.HEX DD D1 11 DD 1D DD DD D1 44 44 
	.HEX 44 44 DD DD DB BB BB BB B4 4D 
	.HEX DD BB DD DD DD BB 44 DD BD 9D 
	.HEX D9 DD DB BB DD BD 9D D9 DD DB 
	.HEX BB DD BD DB DD DD BB 44 2D BB 
	.HEX BB BB BB B4 44 2D 4B B4 4B BB 
	.HEX 44 44 DD D4 44 44 44 44 4D 9D 
	.HEX 9D 49 44 44 44 2D 9D D9 43 94 
	.HEX 44 44 99 9D DD DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD DD DB DD DD DD DD DD DD B9 
	.HEX BD DD DD DD DD BD DB DD BB DD 
	.HEX DD DB 4B DD DB 44 BD DD DD B4 
	.HEX BD DD BB DD BD BD DB DD BD DD 
	.HEX DB 9D 4B DD DB 9B DD BD BD 94 
	.HEX BD DD BD DB 9B DD 4B DD BD DD 
	.HEX BD BD DD BD DB 4B DB 4B DD DD 
	.HEX DD DB 4B DD BD DB DD DB DD BD 
	.HEX DD DD B9 BD B9 BD DD DD DB 4B 
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD DD DD D9 
	.HEX 9D DD DD DD DD DD DD 9D DD DD 
	.HEX DD D9 9B B4 94 BB 99 DD DD D9 
	.HEX BB 9B B9 DD DD BD DD 9B BB 9D 
	.HEX DD BD 9B DD DB BB DD DB 9D BD 
	.HEX DD 68 B8 6D DD BD DD DD 9D 6D 
	.HEX 9D DD DD DD D9 DD 9D D9 DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD DD DD DD DD 9D DD DD DD 9D 
	.HEX DD 
	
	.HEX DD 9D 48 DD DD 0D DD DD 4D 4B 
	.HEX D3 44 4D DD DB BD 4B 02 DD D9 
	.HEX 9D BB BB BB 44 4D 04 DD DD BB 
	.HEX 11 84 D0 43 0D 48 D1 33 DD D4 
	.HEX 3D 0D 0D 14 CC CC CC CC CD 0D 
	.HEX 3D CC CC CC CC CD DD 9D CC CC 
	.HEX CC CC CD 4D 4D CC CC CC CC CD 
	.HEX 0D 4D CC CC CC CC CD 0D 4D DD 
	.HEX DD CC CC CD DD 3D DD DD DC CC 
	.HEX CD 
	
	.HEX DD D9 D4 D4 D4 D9 DD D4 D4 DD 
	.HEX DD D9 DD DD D4 D4 DD 9D D9 D9 
	.HEX 9D D4 DD D4 D9 4D DD 9D DD DD 
	.HEX 44 D4 4D 9D DD DD 9D 4D D4 4D 
	.HEX 44 DD 9D 9D D4 D9 DD 94 DD DD 
	.HEX 44 D4 DD D4 9D DD D9 44 D4 4D 
	.HEX 44 DD 4D D4 DD D4 9D DD D4 4D 
	.HEX DD D4 D4 49 D9 DD 4D 4D 44 DD 
	.HEX DD D4 9D DD 4D 4D DD DD D4 44 
	.HEX DD 
	
	.HEX DD AA DD DD DD DD DD 6D DA BD 
	.HEX 2D DD DD DD B6 DD DD 7D 2D AA 
	.HEX DD BB D8 10 DD 7B AD DD BB BD 
	.HEX D9 10 DD DD 6D BB 86 D0 D9 1D 
	.HEX D6 BD B8 DD 39 D0 D8 DB BD DD 
	.HEX DD D2 39 DD BB BD DD AB 5D D2 
	.HEX 36 8B BD DA AD 0D 5D DD DD BD 
	.HEX DD DD DD 0D BA DD 8D 9D DD DD 
	.HEX DD DA AD DD 99 DD DD DD DD DD 
	.HEX 9D 
	
	.HEX DD DD 9D DD DD DD DD 99 DD 9D 
	.HEX D9 9D DD DD D9 DD 9D DD 9D 99 
	.HEX BD D9 DD 99 9D BD 9D DD D4 DD 
	.HEX DD 9D 99 9D DD B9 9D 94 94 4D 
	.HEX DD DD DD 9B 9B DD 4D D9 9D DD 
	.HEX 9D DB DD 9D D9 DD DD 4D D9 DD 
	.HEX 99 49 DD B9 99 BB 49 9D 49 DD 
	.HEX DD D4 DD DD BB D4 DD DD D9 DD 
	.HEX DD DB D4 DD DD D9 DD DD D9 D4 
	.HEX DD 
	
	.HEX DD DD DD DD DD 57 DD DD DD DD 
	.HEX 6D DD 9D DD DD DD D1 B1 D4 2D 
	.HEX DD DD DD 6B BB 64 2D DD DD D1 
	.HEX BB CB B4 2D DD DD 6B BC CC BB 
	.HEX 2D DD D1 BB CC CC CB B1 DD 6B 
	.HEX BC CC CC CC BB 6D BB CC CC CC 
	.HEX CC CB BD DB CC CC CC CC CB DD 
	.HEX DB CC CC CC CC CB DD DB CC CD 
	.HEX DD CC CB DD DB CC DD DD DC CB 
	.HEX DD 
	
	.HEX DD DD DD DD DD 4D DD D4 AA D9 
	.HEX D4 DD DD DD DD AA 4B BB AA D9 
	.HEX DD DD DD DB BB AA 4D DD D9 DD 
	.HEX AA DB DD DD DD BB 4D AA 9D DD 
	.HEX D4 DD BB BD DD DD D9 DD 9D D4 
	.HEX AA D4 DD DD DD DD 9D AA BB AA 
	.HEX BB D4 DD DD DD BD AA BB AA DD 
	.HEX DD D9 BD DD BB AA DD DD 4D 4D 
	.HEX DD DD DD DD 4D DD DD DD D4 9D 
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD DD DD D1 
	.HEX 1D DD 6D DD D6 6D 1B B6 D1 B1 
	.HEX DD 1B B1 BB BB 1B BB 1D BB BB 
	.HEX BB BB BB BB BD 9B AB BB BB AB 
	.HEX BB BD BB AA AB BB AA AB 9D BB 
	.HEX BB AB 9B BB AB BD BB BB BB BB 
	.HEX BB BB BD BB BB B3 3B BB BB 8D 
	.HEX 8B BB 3D D3 BB B8 DD D8 33 DD 
	.HEX DD 33 3D DD DD DD DD DD DD DD 
	.HEX DD 
	
	.HEX DD DA DD DD AD DD DD AA DA DA 
	.HEX AA AD AA AD BB 4D D4 DD AD AB 
	.HEX AD BA AA AD 9D D4 BB BD BB DA 
	.HEX DD AD AA AA BD AA DA DA AD DA 
	.HEX DD DD DD 4B 4D 4B DA DD AD DA 
	.HEX AB AA AA DB 4D AD 4D D4 DD AD 
	.HEX BB AD AD AA DA AD A4 AA AD DD 
	.HEX DD 4D BB DD BA DD AD DA AA BD 
	.HEX DD DA DA AD DA DD DD DD DD DD 
	.HEX DD 
	
	.HEX CC CC CC CC CC CC CD CC CC CC 
	.HEX CC CC CC CD CC C4 CC CC C4 CC 
	.HEX CD C4 D4 D4 C4 D4 D4 CD C3 34 
	.HEX DD DD D4 33 CD CC C4 14 94 14 
	.HEX CC CD 9C CC D8 D8 DC CC 9D CC 
	.HEX CC D1 D1 DC CC CD CC CC D4 D4 
	.HEX DC CC CD CC C4 DD 1D D4 CC CD 
	.HEX C4 C4 D8 88 D4 C4 CD D4 14 DD 
	.HEX DD D4 14 DD D3 DD DD DD DD D3 
	.HEX DD 
	
	.HEX DD DD 9D DD D9 DD DD D9 DD D9 
	.HEX DD 9B BD DD DD 9D DD D9 B6 7D 
	.HEX DD DD D9 DB BB BB D5 DD D7 DD 
	.HEX 9B B9 BD D9 DD D8 7B D9 BB 9D 
	.HEX D5 DD DD BB BB BD D9 DD DD D6 
	.HEX 7B D9 BD DD 9D DD DB BB 9D 9D 
	.HEX 6D D9 DD BB B9 DD DD 5D DD DD 
	.HEX DD 9D DD DD DD D5 9D DD DD DD 
	.HEX DD D6 7D DD 7D 6D DD DD DD DD 
	.HEX DD
	
	.HEX DD DD 20 DD DD DD DD 22 20 D2 
	.HEX DD 22 DD DD 22 24 4D DD 24 2D 
	.HEX DD 00 D4 2D D0 24 4D DD D2 D4 
	.HEX 02 D2 44 4D DD D2 0D D4 24 00
	.HEX 4D DD D2 DD 04 42 D2 4D DD D0
	.HEX DD 24 42 D2 4D DD D0 33 D4 44
	.HEX D2 23 4D D0 DD 02 40 22 20 0D 
	.HEX DD 2D 40 24 4D D0 DD DD 20 2D 
	.HEX DD 42 D2 DD DD 20 DD DD D4 4D
	.HEX DD 
	
	.HEX DD DD DD DD DD DD DD DD DD 4D 
	.HEX 4D DD DD DD BD DB 4B 4B DD BD 
	.HEX DD 4B B4 44 44 BB 4B DD 44 44 
	.HEX 94 94 44 4B DD AA A4 44 44 AA 
	.HEX AB DD A4 44 44 44 44 AA BD 44 
	.HEX 4A 44 4A 44 4B BD 44 AA A4 AA 
	.HEX A4 4A AD BA AB BB BB AA BA BD 
	.HEX DB BD DD DD BB DB DD DD DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD
	
	.HEX DD DD DD DD DD DD DD 6D DD DD 
	.HEX 6D DD DD 6D DD DD DD DD DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD DD DD DD DD DD DD DD DD DD 
	.HEX DD DD DD BD DD DD DD DD DD BD 
	.HEX BB DD DD DD DD DB BD 9B BD DD 
	.HEX DD DD BB 9D 99 BB DD DD DB B9 
	.HEX 9D
	
	.HEX FF FF FF FF FF FF FF FF FF FF 
	
	.DB "................"
	.DB "...@.......@@@@."
	.DB "@@@@@@@...@..@.."
	.DB "...@.....@..@..."
	.DB "..@.@......@.@.."
	.DB "@@...@@..@@...@@"
	.DB "................"
	.DB ".....@.@@@@@@@.."
	.DB "....@..@.....@.."
	.DB "...@...@@@@@@@.."
	.DB "..@.@.....@....."
	.DB ".@..@.@@@@@@@@@."
	.DB "....@...@.@.@..."
	.DB "....@..@..@..@.."
	.DB "....@.@...@...@."
	.DB "................"
	.DB "....@..........."
	.DB "@@@@@@@@.@@@@@@@"
	.DB "@......@.@..@..@"
	.DB ".@@@@@@..@..@..@"
	.DB "....@....@@@@@@@"
	.DB ".@@@@@@..@..@..@"
	.DB "....@....@..@..@"
	.DB "..@@@....@@@@@@@"
	.DB "................"
	.DB "...@.........@.."
	.DB "...@....@....@.."
	.DB "...@....@....@.."
	.DB "...@....@....@.."
	.DB "...@....@....@.."
	.DB "..@.....@....@.."
	.DB ".@.........@@@.."
	
	.ORG $FFFA
	.DW NMI
	.DW RESET
	.DW RESET

	.INCBIN "chr.bin"
