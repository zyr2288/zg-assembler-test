; Variables used in the game (memory allocation)

; Zero page ($0000-$00FF). Small single-byte variables, pointers.
	.DEF TOPSCORE,             $01 
	.DEF SOFT_RESET_FLAG,      $08 
	.DEF CLEAR_TOPSCORE1,      $09 
	.DEF CLEAR_TOPSCORE2,      $0A 
	.DEF FRAMEDONE,            $0B 
	.DEF LAST_2000,            $0C  		; The PPU_CTRL1 register is write-only, so its shadow copy in RAM is used (common practice)
	.DEF LAST_2001,            $0D 		; The PPU_CTRL2 register is write-only, so its shadow copy in RAM is used
	.DEF H_SCROLL,             $0E 
	.DEF V_SCROLL,             $0F 
	.DEF PAD1_TEST,            $10 
	.DEF PAD2_TEST,            $11 
	.DEF JOYPAD1,              $12 
	.DEF JOYPAD2,              $13 
	.DEF TILE_CUR,             $14 
	.DEF TILE_PTR,             $15 
	.DEF TILE_CNT,             $16 
	.DEF byte_17,              $17 
	.DEF byte_18,              $18 
	.DEF byte_19,              $19 
	.DEF byte_1A,              $1A 
	.DEF byte_1B,              $1B 
	.DEF byte_1C,              $1C 
	.DEF byte_1D,              $1D 
	.DEF byte_1E,              $1E 
	.DEF byte_1F,              $1F 
	.DEF byte_20,              $20 
	.DEF byte_21,              $21 
	.DEF byte_22,              $22 
	.DEF byte_23,              $23 
	.DEF TEMP_X,               $24 
	.DEF TEMP_Y,               $25 
	.DEF OAM_PTR,              $26 		; Pointer to cache of OAM data
	.DEF BOMBMAN_X,            $28 
	.DEF BOMBMAN_U,            $29 
	.DEF BOMBMAN_Y,            $2A 
	.DEF BOMBMAN_V,            $2B 
	.DEF BOMBMAN_FRAME,        $2C 
	.DEF byte_2D,              $2D 
	.DEF byte_2E,              $2E 
	.DEF byte_2F,              $2F 
	.DEF byte_30,              $30 
	.DEF byte_31,              $31 
	.DEF byte_32,              $32 
	.DEF FRAME_CNT,            $33 
	.DEF STAGE_MAP,            $34 
	.DEF byte_36,              $36 
	.DEF BOOM_SOUND,           $38 
	.DEF SPR_TAB_INDEX,        $39 
	.DEF SPR_X,                $3A 
	.DEF SPR_Y,                $3B 
	.DEF SPR_COL,              $3C 
	.DEF SPR_ATTR,             $3D 
	.DEF SPR_ID,               $3E 
	.DEF SPR_SAVEDX,           $3F 
	.DEF SPR_SAVEDY,           $40 
	.DEF M_TYPE,               $41 
	.DEF M_X,                  $42 
	.DEF M_U,                  $43 
	.DEF M_Y,                  $44 
	.DEF M_V,                  $45 
	.DEF M_FRAME,              $46 
	.DEF byte_47,              $47 
	.DEF byte_48,              $48 
	.DEF byte_49,              $49 
	.DEF M_FACE,               $4A 
	.DEF byte_4B,              $4B 
	.DEF byte_4C,              $4C 
	.DEF M_ID,                 $4D 
	.DEF byte_4E,              $4E 
	.DEF byte_4F,              $4F 
	.DEF byte_50,              $50 
	.DEF byte_51,              $51 
	.DEF byte_52,              $52 
	.DEF byte_53,              $53 
	.DEF SEED,                 $54 
	.DEF STAGE,                $58 
	.DEF DEMOPLAY,             $59 
	.DEF byte_5A,              $5A 
	.DEF EXIT_ENEMY_TYPE,      $5B 
	.DEF DYING,                $5C 		; Boolean, in the process of dying 
	.DEF KILLED,               $5D 		; Boolean, have we lost a life on this level 
	.DEF NO_ENEMIES_LEFT,      $5E  		; Boolean, when no enemies remain
	.DEF CURSOR,               $5F 
	.DEF STAGE_STARTED,        $60 
	.DEF SCORE,                $61 
	.DEF LIFELEFT,             $68 
	.DEF FPS,                  $69 
	.DEF IS_SECOND_PASSED,     $6A 
	.DEF byte_6B,              $6B 
	.DEF DEMO_WAIT_HI,         $70 
	.DEF DEMO_WAIT_LO,         $71 
	.DEF INMENU,               $72 
	.DEF BONUS_POWER,          $73 
	.DEF BONUS_BOMBS,          $74 
	.DEF BONUS_SPEED,          $75 
	.DEF BONUS_NOCLIP,         $76 
	.DEF BONUS_REMOTE,         $77 
	.DEF BONUS_BOMBWALK,       $78 
	.DEF BONUS_FIRESUIT,       $79 
	.DEF INVULNERABLE_TIMER,   $7A 		; Invulnerability to monsters for a short time 
	.DEF LAST_INPUT,           $7B 
	.DEF INVULNERABLE,         $7D 		; Invulnerable to monsters for this stage (Boolean)
	.DEF BONUS_ENEMY_TYPE,     $7E 
	.DEF PW_BUFF,              $7F			; Password is stored here (20 bytes) .. $92 
	.DEF byte_92,              $92 
	.DEF TIMELEFT,             $93 
	.DEF DEBUG_MODE,           $94 		; render hidden tiles (doors and powerups) as red half-destroyed walls
	.DEF PW_CXSUM4,            $95 		; Checksum for whole password 
	.DEF MTAB_PTR,             $97 
	.DEF PW_CXSUM1,            $99 		; Checksum for characters 1..4 of password 
	.DEF PW_CXSUM2,            $9A  		; Checksum for characters 6..9 of password
	.DEF PW_CXSUM3,            $9B  		; Checksum for characters 11..14 of password

; Extra bonus item criteria
; https://tcrf.net/Bomberman_(NES)#Bonus_Items
	.DEF ENEMIES_LEFT,         $9C  		; 
	.DEF BONUS_AVAILABLE,      $9D  		; 
	.DEF ENEMIES_DEFEATED,     $9E 		; 
	.DEF EXIT_DWELL_TIME,      $9F 		; How long we are over exit tile for
	.DEF VISITS_TOP_LEFT,      $A0 		; 
	.DEF VISITS_TOP_RIGHT,     $A1 		; 
	.DEF VISITS_BOTTOM_LEFT,   $A2 		; 
	.DEF VISITS_BOTTOM_RIGHT,  $A3 		; 
	.DEF BRICKS_BLOWN_UP,      $A4 		; 
	.DEF CHAIN_REACTIONS,      $A5 		; 
	.DEF KEY_TIMER,            $A6 		; How long at least one key is pressed for
	.DEF EXIT_BOMBED_COUNT,    $A7 		; 
	.DEF BONUS_STATUS,         $A8 		; 0 = Criteria not met / 1 = Achieved / 2 = Collected
	.DEF BONUS_TIMER,          $A9 		; Time which the bonus is on screen for
	.DEF EXTRA_BONUS_ITEM_X,   $AA 		; X position where extra bonus is placed
	.DEF EXTRA_BONUS_ITEM_Y,   $AB 		; Y position where extra bonus is placed

	.DEF DEMOKEY_DATA,         $AC 
	.DEF DEMOKEY_TIMEOUT,      $AE 
	.DEF DEMOKEY_PAD1,         $AF 
	.DEF byte_B0,              $B0 
	.DEF byte_B1,              $B1 
	.DEF APU_DISABLE,          $B2 
	.DEF APU_CHAN,             $B3 
	.DEF APU_TEMP,             $B4 
	.DEF APU_MUSIC,            $B5 
	.DEF byte_B6,              $B6 
	.DEF byte_B9,              $B9 
	.DEF byte_BA,              $BA 
	.DEF byte_BB,              $BB 
	.DEF APU_CHANDAT,          $BC 
	.DEF unk_BD,               $BD 
	.DEF unk_C0,               $C0 
	.DEF APU_PTR,              $C2 
	.DEF APU_CNT,              $C4 
	.DEF unk_C7,               $C7 
	.DEF unk_C8,               $C8 
	.DEF unk_CA,               $CA 
	.DEF byte_CD,              $CD 
	.DEF byte_CE,              $CE 
	.DEF byte_CF,              $CF 
	.DEF byte_D0,              $D0 
	.DEF byte_D1,              $D1 
	.DEF byte_D2,              $D2 
	.DEF byte_D3,              $D3 
	.DEF byte_D4,              $D4 
	.DEF byte_D5,              $D5 
	.DEF byte_D6,              $D6 
	.DEF byte_D7,              $D7 
	.DEF byte_D8,              $D8 
	.DEF byte_D9,              $D9 
	.DEF byte_DA,              $DA 
	.DEF SPR_TAB_TOGGLE,       $DB 
	.DEF BOMB_PWR,             $DC  		; Used for BONUS_POWER calculations with resume codes
	.DEF STAGE_LO,             $DD  		; Used for low byte of STAGE in resume codes
	.DEF STAGE_HI,             $DE  		; Used for high byte of STAGE in resume codes
	.DEF APU_SOUND,            $DF 
	.DEF APU_PATTERN,          $E0 
	.DEF TEMP_ADDR,            $E0 
	.DEF APU_CHAN_DIS,         $E1
	.DEF APU_SOUND_MOD,        $E1
	.DEF APU_SDELAY,           $E4 

; The rest of the memory ($0100-$07FF). Mostly large tables and buffers.
	.DEF _password_buffer,     $0180
	.DEF BOMB_ACTIVE,          $03A0
	.DEF BOMB_X,               $03AA 
	.DEF BOMB_Y,               $03B4 
	.DEF BOMB_TIME_LEFT,       $03BE 
	.DEF byte_3C8,             $03C8 
	.DEF BOMB_TIME_ELAPSED,    $03D2 
	.DEF FIRE_ACTIVE,          $03E6 
	.DEF FIRE_X,               $0436 
	.DEF FIRE_Y,               $0486 
	.DEF byte_4D6,             $04D6 
	.DEF byte_526,             $0526 
	.DEF ENEMY_TYPE,           $0576 
	.DEF ENEMY_X,              $0580 
	.DEF ENEMY_U,              $058A 
	.DEF ENEMY_Y,              $0594 
	.DEF ENEMY_V,              $059E 
	.DEF ENEMY_FRAME,          $05A8 
	.DEF byte_5B2,             $05B2 
	.DEF byte_5BC,             $05BC 
	.DEF byte_5C6,             $05C6 
	.DEF ENEMY_FACE,           $05D0 
	.DEF byte_5DA,             $05DA 
	.DEF byte_5E4,             $05E4 
	.DEF TILE_TAB,             $0600 
	.DEF SPR_TAB,              $0700 
