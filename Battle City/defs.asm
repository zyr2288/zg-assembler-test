
	; 可以运行的基础代码，不要更
	
	.DEF player.MAX,				2
	.DEF player.BULLET_MAX,			2
	.DEF enemy.MAX,					6
	.DEF bullet.MAX,				player.MAX * player.BULLET_MAX + enemy.MAX	;屏幕最大子弹数
	.DEF tank.MAX,					player.MAX + enemy.MAX						;屏幕最大坦克数

	;+ 零页地址
	.ENUM 0
		Temp,						1
		byte_1,						1
		CHR_Byte,					1
		Mask_CHR_Byte,				1
		TSA_Pal,					1
		PPU_Addr_Ptr,				1
		Joypad1_Buttons,			1
		Joypad2_Buttons,			1
		Joypad1_Differ,				1
		Joypad2_Differ,				1
		Seconds_Counter,			1
		Frame_Counter,				1
		ScrBuffer_Pos,				1
		SprBuffer_Position,			1
		Gap,						1
		random.lowAddr,				1
		random.highAddr,			1
		LowPtr_Byte,				1
		HighPtr_Byte,				1
		LowStrPtr_Byte,				1
		HighStrPtr_Byte,			1
		HiScore_1P_String,			8
		HiScore_2P_String,			8
		Temp_1PPts_String,			8
		Temp_2PPts_String,			8
		Num_String,					8
		HiScore_String,				8
		HQArmour_Timer,				1
		Level_Mode,					1
		Spr_X,						1
		Spr_Y,						1
		Tank_Num,					1
		Joy_Counter,				1
		Construction_Flag,			1
		EnterGame_Flag,				1
		BkgPal_Number,				2
		Scroll_Byte,				1
		PPU_REG1_Stts,				1
		player.lives,				player.MAX				
		Spr_TileIndex,				1
		Temp_X,						1
		Temp_Y,						1
		Block_X,					1
		Block_Y,					1
		byte_58,					1
		byte_59,					1
		Counter,					1	
		Counter2,					1
		TSA_BlockNumber,			1
		BrickChar_X,				1
		BrickChar_Y,				1
		String_Position,			1
		Char_Index_Base,			2
		BonusPts_TimeCounter,		1
		Iterative_Byte,				1
		AI_X_DifferFlag,			1
		AI_Y_DifferFlag,			1
		player.addLifeFlag,			player.MAX	; 玩家加命标记
		HQ_Status,					1			; 基地状态
		HQExplode_SprBase,			1			; 基地爆炸精灵			
		EnemyRespawn_PlaceIndex,	1
		byte_6B,					1
		TanksOnScreen,				1
		Pause_Flag,					1			; 暂停标记
		Spr_Attrib,					1
		player.blinkTimer,			player.MAX		; 玩家定住的时间
		AI_X_Aim,					1
		AI_Y_Aim,					1			
		Enmy_KlledBy1P_Count,		4
		Enmy_KlledBy2P_Count,		4		
		byte_7B,					1
		EndCount_Flag,				1
		TotalEnmy_KilledBy1P,		1
		TotalEnmy_KilledBy2P,		1
		Enemy_Reinforce_Count,		1
		Enemy_Counter,				1
		BkgOccurence_Flag,			1							
		Respawn_Timer,				1
		CursorPos,					1
		Respawn_Delay,				1
		Level_Number,				1			; 第几关
		bouns.x,					1			; 奖励X坐标
		bouns.y,					1			; 奖励Y坐标
		bouns.number,				1			; 奖励的类型
		player.invisibleTimer,		player.MAX		; 玩家无敌时间
		Enemy_Count,				4
		Enemy_TypeNumber,			1
		tank.x,						tank.MAX		; 所有坦克的X坐标
		tank.y,						tank.MAX		; 所有坦克的Y坐标
		tank.status,				tank.MAX		; 所有坦克的状态
		tank.type,					tank.MAX		; 所有坦克类型
		Track_Pos,					1
		byte_B1,					2
		byte_B3,					2
		byte_B5,					3
		bullet.x,					bullet.MAX
		bullet.y,					bullet.MAX
		bullet.status,				bullet.MAX
		bullet.property,			bullet.MAX
		NTAddr_Coord_Lo,			8
		NTAddr_Coord_Hi,			8
		Low_Ptr_Snd,				1
		High_Ptr_Snd,				1
		Low_Ptr_SndData,			1			
		High_Ptr_SndData,			1
		Sound_Number,				1
		byte_F5,					1
		byte_F6,					2
		byte_F8,					1
		byte_F9,					4
		byte_FD,					1
		byte_FE,					1
		byte_FF,					1
		enemy.freezeTimer,			1			; 敌人暂停时间
		player.type,				player.MAX		; 玩家坦克类型
		player.iceStatus,			player.MAX
		gameOverStr.x,				1
		gameOverStr.y,				1
		gameOverStr.scrollType,		1
		gameOverStr.timer,			1
		ZeroPage_Offset,			7
		StaffString_RAM,			111
		byte_17F,					1
		Screen_Buffer,				$80
	.ENDE
	;- 零页地址

	.ENUM $300
		Snd_Pause,					1
		Snd_Battle1,				1
		Snd_Battle2,				1
		Snd_Battle3,				1
		Snd_Ancillary_Life1,		1
		Snd_Ancillary_Life2,		1
		Snd_BonusTaken,				1
		Snd_PlayerExplode,			1
		Snd_Unknown1,				1
		Snd_BonusAppears,			1
		Snd_EnemyExplode,			1
		Snd_HQExplode,				1
		Snd_Brick_Ricochet,			1
		Snd_ArmourRicochetWall,		1
		Snd_ArmourRicochetTank,		1
		Snd_Shoot,					1
		Snd_Ice,					1
		Snd_Move,					1
		Snd_Engine,					1
		Snd_PtsCount1,				1
		Snd_PtsCount2,				1
		Snd_RecordPts1,				1
		Snd_RecordPts2,				1
		Snd_RecordPts3,				1
		Snd_GameOver1,				1
		Snd_GameOver2,				1
		Snd_GameOver3,				1
		Snd_BonusPts,				1
		byte_31C,					1
		byte_31D,					1
	.ENDE


	.ENUM $2000
		PPU_CTRL_REG1,				1
		PPU_CTRL_REG2,				1
		PPU_STATUS,					1
		PPU_SPR_ADDR,				1
		PPU_SPR_DATA,				1
		PPU_SCROLL_REG,				1
		PPU_ADDRESS,				1
		PPU_DATA,					1
	.ENDE
	
	.DEF SprBuffer,					$200		;存放精灵 Buffer
	.DEF NT_Buffer,					$400
	
	.DEF SND_SQUARE1_REG,			$4000
	.DEF SPR_DMA,					$4014
	.DEF SND_MASTERCTRL_REG,		$4015
	.DEF JOYPAD_PORT1,				$4016
	.DEF JOYPAD_PORT2,				$4017