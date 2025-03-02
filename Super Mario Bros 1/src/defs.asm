;-------------------------------------------------------------------------------------
;DEFINES


;-------------------------------------------------------------------------------------
;CONSTANTS

;sound effects constants
	.DEF Sfx_SmallJump,          @10000000
	.DEF Sfx_Flagpole,           @01000000
	.DEF Sfx_Fireball,           @00100000
	.DEF Sfx_PipeDown_Injury,    @00010000
	.DEF Sfx_EnemySmack,         @00001000
	.DEF Sfx_EnemyStomp,         @00000100
	.DEF Sfx_Bump,               @00000010
	.DEF Sfx_BigJump,            @00000001

	.DEF Sfx_BowserFall,         @10000000
	.DEF Sfx_ExtraLife,          @01000000
	.DEF Sfx_PowerUpGrab,        @00100000
	.DEF Sfx_TimerTick,          @00010000
	.DEF Sfx_Blast,              @00001000
	.DEF Sfx_GrowVine,           @00000100
	.DEF Sfx_GrowPowerUp,        @00000010
	.DEF Sfx_CoinGrab,           @00000001

	.DEF Sfx_BowserFlame,        @00000010
	.DEF Sfx_BrickShatter,       @00000001

;music constants
	.DEF Silence,                @10000000

	.DEF StarPowerMusic,         @01000000
	.DEF PipeIntroMusic,         @00100000
	.DEF CloudMusic,             @00010000
	.DEF CastleMusic,            @00001000
	.DEF UndergroundMusic,       @00000100
	.DEF WaterMusic,             @00000010
	.DEF GroundMusic,            @00000001

	.DEF TimeRunningOutMusic,    @01000000
	.DEF EndOfLevelMusic,        @00100000
	.DEF AltGameOverMusic,       @00010000
	.DEF EndOfCastleMusic,       @00001000
	.DEF VictoryMusic,           @00000100
	.DEF GameOverMusic,          @00000010
	.DEF DeathMusic,             @00000001

;enemy object constants 
	.DEF GreenKoopa,             $00
	.DEF BuzzyBeetle,            $02
	.DEF RedKoopa,               $03
	.DEF HammerBro,              $05
	.DEF Goomba,                 $06
	.DEF Bloober,                $07
	.DEF BulletBill_FrenzyVar,   $08
	.DEF GreyCheepCheep,         $0a
	.DEF RedCheepCheep,          $0b
	.DEF Podoboo,                $0c
	.DEF PiranhaPlant,           $0d
	.DEF GreenParatroopaJump,    $0e
	.DEF RedParatroopa,          $0f
	.DEF GreenParatroopaFly,     $10
	.DEF Lakitu,                 $11
	.DEF Spiny,                  $12
	.DEF FlyCheepCheepFrenzy,    $14
	.DEF FlyingCheepCheep,       $14
	.DEF BowserFlame,            $15
	.DEF Fireworks,              $16
	.DEF BBill_CCheep_Frenzy,    $17
	.DEF Stop_Frenzy,            $18
	.DEF Bowser,                 $2d
	.DEF PowerUpObject,          $2e
	.DEF VineObject,             $2f
	.DEF FlagpoleFlagObject,     $30
	.DEF StarFlagObject,         $31
	.DEF JumpspringObject,       $32
	.DEF BulletBill_CannonVar,   $33
	.DEF RetainerObject,         $35
	.DEF TallEnemy,              $09

;other constants
	.DEF World1, 0
	.DEF World2, 1
	.DEF World3, 2
	.DEF World4, 3
	.DEF World5, 4
	.DEF World6, 5
	.DEF World7, 6
	.DEF World8, 7
	.DEF Level1, 0
	.DEF Level2, 1
	.DEF Level3, 2
	.DEF Level4, 3

	.DEF WarmBootOffset,         <$07d6
	.DEF ColdBootOffset,         <$07fe
	.DEF TitleScreenDataOffset,  $1ec0
	.DEF SoundMemory,            $07b0
	.DEF SwimTileRepOffset,      PlayerGraphicsTable + $9e
	.DEF MusicHeaderOffsetData,  MusicHeaderData - 1
	.DEF MHD,                    MusicHeaderData

	.DEF A_Button,               @10000000
	.DEF B_Button,               @01000000
	.DEF Select_Button,          @00100000
	.DEF Start_Button,           @00010000
	.DEF Up_Dir,                 @00001000
	.DEF Down_Dir,               @00000100
	.DEF Left_Dir,               @00000010
	.DEF Right_Dir,              @00000001

	.DEF TitleScreenModeValue,   0
	.DEF GameModeValue,          1
	.DEF VictoryModeValue,       2
	.DEF GameOverModeValue,      3
