;NES specific hardware defines

	.DEF PPU_CTRL_REG1,          $2000
	.DEF PPU_CTRL_REG2,          $2001
	.DEF PPU_STATUS,             $2002
	.DEF PPU_SPR_ADDR,           $2003
	.DEF PPU_SPR_DATA,           $2004
	.DEF PPU_SCROLL_REG,         $2005
	.DEF PPU_ADDRESS,            $2006
	.DEF PPU_DATA,               $2007

	.DEF SND_REGISTER,           $4000
	.DEF SND_SQUARE1_REG,        $4000
	.DEF SND_SQUARE2_REG,        $4004
	.DEF SND_TRIANGLE_REG,       $4008
	.DEF SND_NOISE_REG,          $400c
	.DEF SND_DELTA_REG,          $4010
	.DEF SND_MASTERCTRL_REG,     $4015

	.DEF SPR_DMA,                $4014
	.DEF JOYPAD_PORT,            $4016
	.DEF JOYPAD_PORT1,           $4016
	.DEF JOYPAD_PORT2,           $4017

; GAME SPECIFIC DEFINES

	.DEF ObjectOffset,           $08

	.DEF FrameCounter,           $09

	.DEF SavedJoypadBits,        $06fc
	.DEF SavedJoypad1Bits,       $06fc
	.DEF SavedJoypad2Bits,       $06fd
	.DEF JoypadBitMask,          $074a
	.DEF JoypadOverride,         $0758

	.DEF A_B_Buttons,            $0a
	.DEF PreviousA_B_Buttons,    $0d
	.DEF Up_Down_Buttons,        $0b
	.DEF Left_Right_Buttons,     $0c

	.DEF GameEngineSubroutine,   $0e

	.DEF Mirror_PPU_CTRL_REG1,   $0778
	.DEF Mirror_PPU_CTRL_REG2,   $0779

	.DEF OperMode,               $0770
	.DEF OperMode_Task,          $0772
	.DEF ScreenRoutineTask,      $073c

	.DEF GamePauseStatus,        $0776
	.DEF GamePauseTimer,         $0777

	.DEF DemoAction,             $0717
	.DEF DemoActionTimer,        $0718

	.DEF TimerControl,           $0747
	.DEF IntervalTimerControl,   $077f

	.DEF Timers,                 $0780
	.DEF SelectTimer,            $0780
	.DEF PlayerAnimTimer,        $0781
	.DEF JumpSwimTimer,          $0782
	.DEF RunningTimer,           $0783
	.DEF BlockBounceTimer,       $0784
	.DEF SideCollisionTimer,     $0785
	.DEF JumpspringTimer,        $0786
	.DEF GameTimerCtrlTimer,     $0787
	.DEF ClimbSideTimer,         $0789
	.DEF EnemyFrameTimer,        $078a
	.DEF FrenzyEnemyTimer,       $078f
	.DEF BowserFireBreathTimer,  $0790
	.DEF StompTimer,             $0791
	.DEF AirBubbleTimer,         $0792
	.DEF ScrollIntervalTimer,    $0795
	.DEF EnemyIntervalTimer,     $0796
	.DEF BrickCoinTimer,         $079d
	.DEF InjuryTimer,            $079e
	.DEF StarInvincibleTimer,    $079f
	.DEF ScreenTimer,            $07a0
	.DEF WorldEndTimer,          $07a1
	.DEF DemoTimer,              $07a2

	.DEF Sprite_Data,            $0200

	.DEF Sprite_Y_Position,      $0200
	.DEF Sprite_Tilenumber,      $0201
	.DEF Sprite_Attributes,      $0202
	.DEF Sprite_X_Position,      $0203

	.DEF ScreenEdge_PageLoc,     $071a
	.DEF ScreenEdge_X_Pos,       $071c
	.DEF ScreenLeft_PageLoc,     $071a
	.DEF ScreenRight_PageLoc,    $071b
	.DEF ScreenLeft_X_Pos,       $071c
	.DEF ScreenRight_X_Pos,      $071d

	.DEF PlayerFacingDir,        $33
	.DEF DestinationPageLoc,     $34
	.DEF VictoryWalkControl,     $35
	.DEF ScrollFractional,       $0768
	.DEF PrimaryMsgCounter,      $0719
	.DEF SecondaryMsgCounter,    $0749

	.DEF HorizontalScroll,       $073f
	.DEF VerticalScroll,         $0740
	.DEF ScrollLock,             $0723
	.DEF ScrollThirtyTwo,        $073d
	.DEF Player_X_Scroll,        $06ff
	.DEF Player_Pos_ForScroll,   $0755
	.DEF ScrollAmount,           $0775

	.DEF AreaData,               $e7
	.DEF AreaDataLow,            $e7
	.DEF AreaDataHigh,           $e8
	.DEF EnemyData,              $e9
	.DEF EnemyDataLow,           $e9
	.DEF EnemyDataHigh,          $ea

	.DEF AreaParserTaskNum,      $071f
	.DEF ColumnSets,             $071e
	.DEF CurrentPageLoc,         $0725
	.DEF CurrentColumnPos,       $0726
	.DEF BackloadingFlag,        $0728
	.DEF BehindAreaParserFlag,   $0729
	.DEF AreaObjectPageLoc,      $072a
	.DEF AreaObjectPageSel,      $072b
	.DEF AreaDataOffset,         $072c
	.DEF AreaObjOffsetBuffer,    $072d
	.DEF AreaObjectLength,       $0730
	.DEF StaircaseControl,       $0734
	.DEF AreaObjectHeight,       $0735
	.DEF MushroomLedgeHalfLen,   $0736
	.DEF EnemyDataOffset,        $0739
	.DEF EnemyObjectPageLoc,     $073a
	.DEF EnemyObjectPageSel,     $073b
	.DEF MetatileBuffer,         $06a1
	.DEF BlockBufferColumnPos,   $06a0
	.DEF CurrentNTAddr_Low,      $0721
	.DEF CurrentNTAddr_High,     $0720
	.DEF AttributeBuffer,        $03f9

	.DEF LoopCommand,            $0745

	.DEF DisplayDigits,          $07d7
	.DEF TopScoreDisplay,        $07d7
	.DEF ScoreAndCoinDisplay,    $07dd
	.DEF PlayerScoreDisplay,     $07dd
	.DEF GameTimerDisplay,       $07f8
	.DEF DigitModifier,          $0134

	.DEF VerticalFlipFlag,       $0109
	.DEF FloateyNum_Control,     $0110
	.DEF ShellChainCounter,      $0125
	.DEF FloateyNum_Timer,       $012c
	.DEF FloateyNum_X_Pos,       $0117
	.DEF FloateyNum_Y_Pos,       $011e
	.DEF FlagpoleFNum_Y_Pos,     $010d
	.DEF FlagpoleFNum_YMFDummy,  $010e
	.DEF FlagpoleScore,          $010f
	.DEF FlagpoleCollisionYPos,  $070f
	.DEF StompChainCounter,      $0484

	.DEF VRAM_Buffer1_Offset,    $0300
	.DEF VRAM_Buffer1,           $0301
	.DEF VRAM_Buffer2_Offset,    $0340
	.DEF VRAM_Buffer2,           $0341
	.DEF VRAM_Buffer_AddrCtrl,   $0773
	.DEF Sprite0HitDetectFlag,   $0722
	.DEF DisableScreenFlag,      $0774
	.DEF DisableIntermediate,    $0769
	.DEF ColorRotateOffset,      $06d4

	.DEF TerrainControl,         $0727
	.DEF AreaStyle,              $0733
	.DEF ForegroundScenery,      $0741
	.DEF BackgroundScenery,      $0742
	.DEF CloudTypeOverride,      $0743
	.DEF BackgroundColorCtrl,    $0744
	.DEF AreaType,               $074e
	.DEF AreaAddrsLOffset,       $074f
	.DEF AreaPointer,            $0750

	.DEF PlayerEntranceCtrl,     $0710
	.DEF GameTimerSetting,       $0715
	.DEF AltEntranceControl,     $0752
	.DEF EntrancePage,           $0751
	.DEF NumberOfPlayers,        $077a
	.DEF WarpZoneControl,        $06d6
	.DEF ChangeAreaTimer,        $06de

	.DEF MultiLoopCorrectCntr,   $06d9
	.DEF MultiLoopPassCntr,      $06da

	.DEF FetchNewGameTimerFlag,  $0757
	.DEF GameTimerExpiredFlag,   $0759

	.DEF PrimaryHardMode,        $076a
	.DEF SecondaryHardMode,      $06cc
	.DEF WorldSelectNumber,      $076b
	.DEF WorldSelectEnableFlag,  $07fc
	.DEF ContinueWorld,          $07fd

	.DEF CurrentPlayer,          $0753
	.DEF PlayerSize,             $0754
	.DEF PlayerStatus,           $0756

	.DEF OnscreenPlayerInfo,     $075a
	.DEF NumberofLives,          $075a ;used by current player
	.DEF HalfwayPage,            $075b
	.DEF LevelNumber,            $075c ;the actual dash number
	.DEF Hidden1UpFlag,          $075d
	.DEF CoinTally,              $075e
	.DEF WorldNumber,            $075f
	.DEF AreaNumber,             $0760 ;internal number used to find areas

	.DEF CoinTallyFor1Ups,       $0748

	.DEF OffscreenPlayerInfo,    $0761
	.DEF OffScr_NumberofLives,   $0761 ;used by offscreen player
	.DEF OffScr_HalfwayPage,     $0762
	.DEF OffScr_LevelNumber,     $0763
	.DEF OffScr_Hidden1UpFlag,   $0764
	.DEF OffScr_CoinTally,       $0765
	.DEF OffScr_WorldNumber,     $0766
	.DEF OffScr_AreaNumber,      $0767

	.DEF BalPlatformAlignment,   $03a0
	.DEF Platform_X_Scroll,      $03a1
	.DEF PlatformCollisionFlag,  $03a2
	.DEF YPlatformTopYPos,       $0401
	.DEF YPlatformCenterYPos,    $58

	.DEF BrickCoinTimerFlag,     $06bc
	.DEF StarFlagTaskControl,    $0746

	.DEF PseudoRandomBitReg,     $07a7
	.DEF WarmBootValidation,     $07ff

	.DEF SprShuffleAmtOffset,    $06e0
	.DEF SprShuffleAmt,          $06e1
	.DEF SprDataOffset,          $06e4
	.DEF Player_SprDataOffset,   $06e4
	.DEF Enemy_SprDataOffset,    $06e5
	.DEF Block_SprDataOffset,    $06ec
	.DEF Alt_SprDataOffset,      $06ec
	.DEF Bubble_SprDataOffset,   $06ee
	.DEF FBall_SprDataOffset,    $06f1
	.DEF Misc_SprDataOffset,     $06f3
	.DEF SprDataOffset_Ctrl,     $03ee

	.DEF Player_State,           $1d
	.DEF Enemy_State,            $1e
	.DEF Fireball_State,         $24
	.DEF Block_State,            $26
	.DEF Misc_State,             $2a

	.DEF Player_MovingDir,       $45
	.DEF Enemy_MovingDir,        $46

	.DEF SprObject_X_Speed,      $57
	.DEF Player_X_Speed,         $57
	.DEF Enemy_X_Speed,          $58
	.DEF Fireball_X_Speed,       $5e
	.DEF Block_X_Speed,          $60
	.DEF Misc_X_Speed,           $64

	.DEF Jumpspring_FixedYPos,   $58
	.DEF JumpspringAnimCtrl,     $070e
	.DEF JumpspringForce,        $06db

	.DEF SprObject_PageLoc,      $6d
	.DEF Player_PageLoc,         $6d
	.DEF Enemy_PageLoc,          $6e
	.DEF Fireball_PageLoc,       $74
	.DEF Block_PageLoc,          $76
	.DEF Misc_PageLoc,           $7a
	.DEF Bubble_PageLoc,         $83

	.DEF SprObject_X_Position,   $86
	.DEF Player_X_Position,      $86
	.DEF Enemy_X_Position,       $87
	.DEF Fireball_X_Position,    $8d
	.DEF Block_X_Position,       $8f
	.DEF Misc_X_Position,        $93
	.DEF Bubble_X_Position,      $9c

	.DEF SprObject_Y_Speed,      $9f
	.DEF Player_Y_Speed,         $9f
	.DEF Enemy_Y_Speed,          $a0
	.DEF Fireball_Y_Speed,       $a6
	.DEF Block_Y_Speed,          $a8
	.DEF Misc_Y_Speed,           $ac

	.DEF SprObject_Y_HighPos,    $b5
	.DEF Player_Y_HighPos,       $b5
	.DEF Enemy_Y_HighPos,        $b6
	.DEF Fireball_Y_HighPos,     $bc
	.DEF Block_Y_HighPos,        $be
	.DEF Misc_Y_HighPos,         $c2
	.DEF Bubble_Y_HighPos,       $cb

	.DEF SprObject_Y_Position,   $ce
	.DEF Player_Y_Position,      $ce
	.DEF Enemy_Y_Position,       $cf
	.DEF Fireball_Y_Position,    $d5
	.DEF Block_Y_Position,       $d7
	.DEF Misc_Y_Position,        $db
	.DEF Bubble_Y_Position,      $e4

	.DEF SprObject_Rel_XPos,     $03ad
	.DEF Player_Rel_XPos,        $03ad
	.DEF Enemy_Rel_XPos,         $03ae
	.DEF Fireball_Rel_XPos,      $03af
	.DEF Bubble_Rel_XPos,        $03b0
	.DEF Block_Rel_XPos,         $03b1
	.DEF Misc_Rel_XPos,          $03b3

	.DEF SprObject_Rel_YPos,     $03b8
	.DEF Player_Rel_YPos,        $03b8
	.DEF Enemy_Rel_YPos,         $03b9
	.DEF Fireball_Rel_YPos,      $03ba
	.DEF Bubble_Rel_YPos,        $03bb
	.DEF Block_Rel_YPos,         $03bc
	.DEF Misc_Rel_YPos,          $03be

	.DEF SprObject_SprAttrib,    $03c4
	.DEF Player_SprAttrib,       $03c4
	.DEF Enemy_SprAttrib,        $03c5

	.DEF SprObject_X_MoveForce,  $0400
	.DEF Enemy_X_MoveForce,      $0401

	.DEF SprObject_YMF_Dummy,    $0416
	.DEF Player_YMF_Dummy,       $0416
	.DEF Enemy_YMF_Dummy,        $0417
	.DEF Bubble_YMF_Dummy,       $042c

	.DEF SprObject_Y_MoveForce,  $0433
	.DEF Player_Y_MoveForce,     $0433
	.DEF Enemy_Y_MoveForce,      $0434
	.DEF Block_Y_MoveForce,      $043c

	.DEF DisableCollisionDet,    $0716
	.DEF Player_CollisionBits,   $0490
	.DEF Enemy_CollisionBits,    $0491

	.DEF SprObj_BoundBoxCtrl,    $0499
	.DEF Player_BoundBoxCtrl,    $0499
	.DEF Enemy_BoundBoxCtrl,     $049a
	.DEF Fireball_BoundBoxCtrl,  $04a0
	.DEF Misc_BoundBoxCtrl,      $04a2

	.DEF EnemyFrenzyBuffer,      $06cb
	.DEF EnemyFrenzyQueue,       $06cd
	.DEF Enemy_Flag,             $0f
	.DEF Enemy_ID,               $16

	.DEF PlayerGfxOffset,        $06d5
	.DEF Player_XSpeedAbsolute,  $0700
	.DEF FrictionAdderHigh,      $0701
	.DEF FrictionAdderLow,       $0702
	.DEF RunningSpeed,           $0703
	.DEF SwimmingFlag,           $0704
	.DEF Player_X_MoveForce,     $0705
	.DEF DiffToHaltJump,         $0706
	.DEF JumpOrigin_Y_HighPos,   $0707
	.DEF JumpOrigin_Y_Position,  $0708
	.DEF VerticalForce,          $0709
	.DEF VerticalForceDown,      $070a
	.DEF PlayerChangeSizeFlag,   $070b
	.DEF PlayerAnimTimerSet,     $070c
	.DEF PlayerAnimCtrl,         $070d
	.DEF DeathMusicLoaded,       $0712
	.DEF FlagpoleSoundQueue,     $0713
	.DEF CrouchingFlag,          $0714
	.DEF MaximumLeftSpeed,       $0450
	.DEF MaximumRightSpeed,      $0456

	.DEF SprObject_OffscrBits,   $03d0
	.DEF Player_OffscreenBits,   $03d0
	.DEF Enemy_OffscreenBits,    $03d1
	.DEF FBall_OffscreenBits,    $03d2
	.DEF Bubble_OffscreenBits,   $03d3
	.DEF Block_OffscreenBits,    $03d4
	.DEF Misc_OffscreenBits,     $03d6
	.DEF EnemyOffscrBitsMasked,  $03d8

	.DEF Cannon_Offset,          $046a
	.DEF Cannon_PageLoc,         $046b
	.DEF Cannon_X_Position,      $0471
	.DEF Cannon_Y_Position,      $0477
	.DEF Cannon_Timer,           $047d

	.DEF Whirlpool_Offset,       $046a
	.DEF Whirlpool_PageLoc,      $046b
	.DEF Whirlpool_LeftExtent,   $0471
	.DEF Whirlpool_Length,       $0477
	.DEF Whirlpool_Flag,         $047d

	.DEF VineFlagOffset,         $0398
	.DEF VineHeight,             $0399
	.DEF VineObjOffset,          $039a
	.DEF VineStart_Y_Position,   $039d

	.DEF Block_Orig_YPos,        $03e4
	.DEF Block_BBuf_Low,         $03e6
	.DEF Block_Metatile,         $03e8
	.DEF Block_PageLoc2,         $03ea
	.DEF Block_RepFlag,          $03ec
	.DEF Block_ResidualCounter,  $03f0
	.DEF Block_Orig_XPos,        $03f1

	.DEF BoundingBox_UL_XPos,    $04ac
	.DEF BoundingBox_UL_YPos,    $04ad
	.DEF BoundingBox_DR_XPos,    $04ae
	.DEF BoundingBox_DR_YPos,    $04af
	.DEF BoundingBox_UL_Corner,  $04ac
	.DEF BoundingBox_LR_Corner,  $04ae
	.DEF EnemyBoundingBoxCoord,  $04b0

	.DEF PowerUpType,            $39

	.DEF FireballBouncingFlag,   $3a
	.DEF FireballCounter,        $06ce
	.DEF FireballThrowingTimer,  $0711

	.DEF HammerEnemyOffset,      $06ae
	.DEF JumpCoinMiscOffset,     $06b7

	.DEF Block_Buffer_1,         $0500
	.DEF Block_Buffer_2,         $05d0

	.DEF HammerThrowingTimer,    $03a2
	.DEF HammerBroJumpTimer,     $3c
	.DEF Misc_Collision_Flag,    $06be

	.DEF RedPTroopaOrigXPos,     $0401
	.DEF RedPTroopaCenterYPos,   $58

	.DEF XMovePrimaryCounter,    $a0
	.DEF XMoveSecondaryCounter,  $58

	.DEF CheepCheepMoveMFlag,    $58
	.DEF CheepCheepOrigYPos,     $0434
	.DEF BitMFilter,             $06dd

	.DEF LakituReappearTimer,    $06d1
	.DEF LakituMoveSpeed,        $58
	.DEF LakituMoveDirection,    $a0

	.DEF FirebarSpinState_Low,   $58
	.DEF FirebarSpinState_High,  $a0
	.DEF FirebarSpinSpeed,       $0388
	.DEF FirebarSpinDirection,   $34

	.DEF DuplicateObj_Offset,    $06cf
	.DEF NumberofGroupEnemies,   $06d3

	.DEF BlooperMoveCounter,     $a0
	.DEF BlooperMoveSpeed,       $58

	.DEF BowserBodyControls,     $0363
	.DEF BowserFeetCounter,      $0364
	.DEF BowserMovementSpeed,    $0365
	.DEF BowserOrigXPos,         $0366
	.DEF BowserFlameTimerCtrl,   $0367
	.DEF BowserFront_Offset,     $0368
	.DEF BridgeCollapseOffset,   $0369
	.DEF BowserGfxFlag,          $036a
	.DEF BowserHitPoints,        $0483
	.DEF MaxRangeFromOrigin,     $06dc

	.DEF BowserFlamePRandomOfs,  $0417

	.DEF PiranhaPlantUpYPos,     $0417
	.DEF PiranhaPlantDownYPos,   $0434
	.DEF PiranhaPlant_Y_Speed,   $58
	.DEF PiranhaPlant_MoveFlag,  $a0

	.DEF FireworksCounter,       $06d7
	.DEF ExplosionGfxCounter,    $58
	.DEF ExplosionTimerCounter,  $a0

;sound related defines
	.DEF Squ2_NoteLenBuffer,     $07b3
	.DEF Squ2_NoteLenCounter,    $07b4
	.DEF Squ2_EnvelopeDataCtrl,  $07b5
	.DEF Squ1_NoteLenCounter,    $07b6
	.DEF Squ1_EnvelopeDataCtrl,  $07b7
	.DEF Tri_NoteLenBuffer,      $07b8
	.DEF Tri_NoteLenCounter,     $07b9
	.DEF Noise_BeatLenCounter,   $07ba
	.DEF Squ1_SfxLenCounter,     $07bb
	.DEF Squ2_SfxLenCounter,     $07bd
	.DEF Sfx_SecondaryCounter,   $07be
	.DEF Noise_SfxLenCounter,    $07bf

	.DEF PauseSoundQueue,        $fa
	.DEF Square1SoundQueue,      $ff
	.DEF Square2SoundQueue,      $fe
	.DEF NoiseSoundQueue,        $fd
	.DEF AreaMusicQueue,         $fb
	.DEF EventMusicQueue,        $fc

	.DEF Square1SoundBuffer,     $f1
	.DEF Square2SoundBuffer,     $f2
	.DEF NoiseSoundBuffer,       $f3
	.DEF AreaMusicBuffer,        $f4
	.DEF EventMusicBuffer,       $07b1
	.DEF PauseSoundBuffer,       $07b2

	.DEF MusicData,              $f5
	.DEF MusicDataLow,           $f5
	.DEF MusicDataHigh,          $f6
	.DEF MusicOffset_Square2,    $f7
	.DEF MusicOffset_Square1,    $f8
	.DEF MusicOffset_Triangle,   $f9
	.DEF MusicOffset_Noise,      $07b0

	.DEF NoteLenLookupTblOfs,    $f0
	.DEF DAC_Counter,            $07c0
	.DEF NoiseDataLoopbackOfs,   $07c1
	.DEF NoteLengthTblAdder,     $07c4
	.DEF AreaMusicBuffer_Alt,    $07c5
	.DEF PauseModeFlag,          $07c6
	.DEF GroundMusicHeaderOfs,   $07c7
	.DEF AltRegContentFlag,      $07ca
