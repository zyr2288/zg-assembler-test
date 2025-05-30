
    .ORG $BFF0
	.INCBIN "assets/NES_Header.bin"
	
	.ORG $C000

    .INCLUDE "NESREGS.asm"
    .INCLUDE "VARS.asm"


RESET:
        SEI                             ; Reset PPU. Disable NMI, turn off background and sprites.
        LDA #0
        STA PPU_CTRL_REG2
        STA PPU_CTRL_REG1
        CLD                             ; The NES 6502 CPU has no BCD mode, reset the flag just in case.
        LDX #$FF                        ; Set the stack pointer to the initial position
        TXS

WAIT_VBLANK1                            ; Wait for 2 VBlank's, to stabilize the PPU.
        LDA PPU_STATUS
        BPL WAIT_VBLANK1

WAIT_VBLANK2
        LDA PPU_STATUS
        BPL WAIT_VBLANK2
        JMP START

; ---------------------------------------------------------------------------

NMI:
        PHA
        TXA
        PHA
        TYA
        PHA
        LDX #0
        STX FRAMEDONE   ; Cancel frame start wait
        STX PPU_SPR_ADDR
        LDA STAGE_STARTED
        BEQ SEND_SPRITES
        LDA #25     ; Draw a small `1` on the top-right side of the screen
        STA SPR_TAB     ; Apparently used for debugging (forgot to remove)
        LDA #$EC
        STA SPR_TAB+1
        LDA #0
        STA SPR_TAB+2
        LDA #248
        STA SPR_TAB+3

SEND_SPRITES:
        LDA #7
        STA PPU_SPR_DMA
        LDX #9      ; Draw tiles from the circular buffer
        STX TILE_CNT
        BNE DRAW_NEXT_TILE

DRAW_TILES:
        LDA TILE_TAB+2,Y    ; Draw new tiles until the end of the buffer, but no more than TILE_CNT tiles.
        ORA TILE_TAB,Y
        PHA
        STA PPU_ADDRESS
        LDX TILE_TAB+1,Y
        STX PPU_ADDRESS
        LDX TILE_TAB+3,Y
        LDA TILE_MAP,X
        STA PPU_DATA
        LDA TILE_MAP+1,X
        STA PPU_DATA
        PLA
        STA PPU_ADDRESS
        LDA TILE_TAB+1,Y
        CLC
        ADC #32
        STA PPU_ADDRESS
        LDA TILE_MAP+2,X
        STA PPU_DATA
        LDA TILE_MAP+3,X
        STA PPU_DATA
        LDA #$23 ; '#'
        ORA TILE_TAB,Y
        PHA
        STA PPU_ADDRESS
        LDA TILE_TAB+4,Y
        STA PPU_ADDRESS
        TAX
        LDA PPU_DATA
        LDA PPU_DATA
        AND TILE_TAB+6,Y
        ORA TILE_TAB+7,Y
        TAY
        PLA
        STA PPU_ADDRESS
        STX PPU_ADDRESS
        STY PPU_DATA
        LDA #8
        CLC
        ADC TILE_CUR
        STA TILE_CUR
        DEC TILE_CNT
        BEQ DRAW_MENU_ARROW

DRAW_NEXT_TILE:             
        LDY TILE_CUR
        CPY TILE_PTR
        BNE DRAW_TILES  ; Draw new tiles until the end of the buffer, but no more than TILE_CNT tiles.

DRAW_MENU_ARROW:            
        LDA INMENU
        BEQ DRAW_ARROW_SKIP
        LDA #$22 ; '"'
        LDX #$68 ; 'h'
        JSR VRAMADDR
        LDY #$B0 ; '-'
        LDA CURSOR
        BNE DRAW_ARROW_START
        LDY #$40 ; '@'

DRAW_ARROW_START:           
        STY PPU_DATA
        LDA #$22 ; '"'
        LDX #$70 ; 'p'
        JSR VRAMADDR
        LDY #$B0 ; '-'
        LDA CURSOR
        BEQ DRAW_ARROW_CONT
        LDY #$40 ; '@'

DRAW_ARROW_CONT:            
        STY PPU_DATA
        JMP UPDATE_FPS
; ---------------------------------------------------------------------------

DRAW_ARROW_SKIP:            
        LDA STAGE_STARTED
        BEQ UPDATE_FPS
        LDA TILE_CNT
        CMP #4
        BCC UPDATE_FPS
        LDA #$20 ; ' '
        LDX #$4B ; 'K'
        JSR VRAMADDR    ; Y=2, X=11
        LDX #0

DRAW_SCORE_BLANK:           
        LDA SCORE,X     ; Skip leading zeros
        BNE DRAW_SCORE_NUM
        LDA #$3A ; ':'      ; Blank character instead of zero
        STA PPU_DATA
        INX
        CPX #7
        BNE DRAW_SCORE_BLANK ; Skip leading zeros
        BEQ DRAW_TIMER

DRAW_SCORE_NUM:             
        LDA SCORE,X
        CLC
        ADC #$30 ; '0'      ; The number is 0...9
        STA PPU_DATA
        INX
        CPX #7
        BNE DRAW_SCORE_NUM

DRAW_TIMER:             
        LDA #$20 ; ' '
        LDX #$46 ; 'F'      ; Y=2, X=6
        JSR VRAMADDR
        LDA TIMELEFT
        CMP #255
        BNE TIME_OVERFLOW
        LDA #0

TIME_OVERFLOW:              
        JSR DRAW_TIME

UPDATE_FPS:             
        LDA PPU_STATUS
        JSR PPU_RESTORE
        INC FRAME_CNT
        LDA IS_SECOND_PASSED
        BEQ TICK_FPS
        INC FPS
        LDA FPS
        CMP #60
        BCC TICK_FPS
        LDA #0
        STA IS_SECOND_PASSED

TICK_FPS:               
        STA FPS
        JSR PAD_READ
        JSR APU_PLAY_MELODY ; Play a tune
        JSR APU_PLAY_SOUND  ; Play the sound
        LDA BOOM_SOUND
        BEQ SET_SCROLL_REG
        LDA DEMOPLAY
        BNE SET_SCROLL_REG
        LDA #$E
        STA APU_DELTA_REG
        LDA #0
        STA BOOM_SOUND
        LDA #$C0 ; 'L'
        STA APU_DELTA_REG+2
        LDA #$FF
        STA APU_DELTA_REG+3
        LDA #$F
        STA APU_MASTERCTRL_REG
        LDA #$1F
        STA APU_MASTERCTRL_REG

SET_SCROLL_REG:             
        LDA STAGE_STARTED
        BEQ LEAVE_NMI

WAIT_SPR0_HIT:              
        LDA PPU_STATUS
        AND #$40 ; '@'
        BNE WAIT_SPR0_HIT

WAIT_SPR0_MISS:             
        LDA PPU_STATUS
        AND #$40 ; '@'
        BEQ WAIT_SPR0_MISS
        LDA H_SCROLL
        STA PPU_SCROLL_REG
        LDA V_SCROLL
        STA PPU_SCROLL_REG

LEAVE_NMI:              
        LDA #5
        EOR SPR_TAB_TOGGLE
        STA SPR_TAB_TOGGLE
        PLA
        TAY
        PLA
        TAX
        PLA
        RTI

; =============== S U B R O U T I N E =======================================


VRAMADDR:
        STA PPU_ADDRESS
        STX PPU_ADDRESS
        RTS


; =============== S U B R O U T I N E =======================================


PAD_READ:
        JSR PAD_STROBE
        LDA JOYPAD1
        STA PAD1_TEST
        LDA JOYPAD2
        STA PAD2_TEST
        JSR PAD_STROBE
        LDA JOYPAD1
        CMP PAD1_TEST
        BNE PAD_DRE
        LDA JOYPAD2
        CMP PAD2_TEST
        BNE PAD_DRE
        RTS
; ---------------------------------------------------------------------------

PAD_DRE:
        LDA #0
        STA JOYPAD1
        STA JOYPAD2
        RTS


; =============== S U B R O U T I N E =======================================


PAD_STROBE:
        LDA #1
        STA JOYPAD_PORT1
        LDA #0
        STA JOYPAD_PORT1
        TAX
        LDY #8

JOY1:                   
        TXA
        ASL
        TAX
        LDA JOYPAD_PORT1
        JSR IS_PRESSED
        BNE JOY1
        STX JOYPAD1
        LDX #0
        LDY #8

JOY2:                   
        TXA
        ASL
        TAX
        LDA JOYPAD_PORT2
        JSR IS_PRESSED
        BNE JOY2
        STX JOYPAD2
        RTS


; =============== S U B R O U T I N E =======================================


IS_PRESSED:
        AND #3
        BEQ NOT_PRESSED
        INX

NOT_PRESSED:                
        DEY
        RTS

; =============== S U B R O U T I N E =======================================


PPU_RESET:
        JSR PPUD
        JSR VBLD
        LDA #$10
        STA LAST_2000
        STA PPU_CTRL_REG1
        LDA #0
        STA H_SCROLL
        STA TILE_CUR
        STA TILE_PTR
        STA V_SCROLL
        JSR SPRD        ; Hide Sprites
        JSR PPUD
        JSR WAITVBL
        JSR PAL_RESET


; =============== S U B R O U T I N E =======================================


CLS:
        LDA #$20 ; ' '
        LDX #0
        JSR VRAMADDR
        LDY #8
        LDA #$B0 ; '-'

CLEAR_NT:
        STA PPU_DATA
        DEX
        BNE CLEAR_NT
        DEY
        BNE CLEAR_NT
        LDA #$23
        LDX #$C0
        JSR VRAMADDR
        LDX #$40 ; '@'
        LDA #0

CLEAR_AT:               
        STA PPU_DATA
        DEX
        BNE CLEAR_AT
        RTS


; =============== S U B R O U T I N E =======================================


PPUE:
        JSR VBLD
        JSR WAITVBL
        LDA #$E
        JSR WRITE2001
        JSR SENDSPR
        JMP VBLE


; =============== S U B R O U T I N E =======================================

; How sprites are rendered.
; There can be up to 16 sprite images in total (10 monsters, bomberman and bonus points)
; The sprite image consists of 4 sprites and is 16x16 in size.
; The sprite table is conventionally divided into two parts: for even and odd frames.
; Apparently this is done to reduce the flicker of sprites.
; The sprite image is rendered in halves (first the left 8x16, then the right) because they are symmetrical.
; The special variable SPR_TAB_TOGGLE takes values 0 -> 5 -> 0 every frame ...
; and thereby selects which half of the SPR_TAB to use for rendering.
; In general, the offset in SPR_TAB for the current sprite image is calculated as follows:
; TEMP = SPR_TAB_INDEX++ + SPR_TAB_TOGGLE   <-- The index begins with 1.
; TEMP = TEMP >= 12 ? TEMP - 10 : TEMP      <-- Limit the index to 12
; Y = 16 * TEMP                             <-- *16 because the image is made up of 4 sprites
; Which is a little strange, but what to take, as they did so.
; For example, there is a bomber and 10 monsters on the screen. The TEMP value will be as follows-
; For even frames: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
; For odd frames: 6, 7, 8, 9, 10, 11, 2, 3, 4, 5, 6
; (For odd frames bomber sprites will be overwritten by monster sprites and as a result 
; the bomber picture will blink when there are many sprites on the screen).


SENDSPR:
        LDA #0
        STA PPU_SPR_ADDR
        LDA #7
        STA PPU_SPR_DMA
        RTS


; =============== S U B R O U T I N E =======================================


PPUD:
        JSR WAITVBL
        LDA #0


; =============== S U B R O U T I N E =======================================


WRITE2001:              
        STA PPU_CTRL_REG2

WRITE2001_2:                
        STA LAST_2001
        RTS


; =============== S U B R O U T I N E =======================================


SPRE:                   
        LDA LAST_2001
        ORA #$10
        BNE WRITE2001_2


; =============== S U B R O U T I N E =======================================

; Hide Sprites

SPRD:
        LDY #$1C
        LDA #248

SETATTR:                
        STA SPR_TAB,Y
        STA SPR_TAB+$20,Y
        STA SPR_TAB+$40,Y
        STA SPR_TAB+$60,Y
        STA SPR_TAB+$80,Y
        STA SPR_TAB+$A0,Y
        STA SPR_TAB+$C0,Y
        STA SPR_TAB+$E0,Y
        DEY
        DEY
        DEY
        DEY
        BPL SETATTR
        RTS


; =============== S U B R O U T I N E =======================================


WAITVBL:
        LDA PPU_STATUS
        BMI WAITVBL

WAITVBL2:               
        LDA PPU_STATUS
        BPL WAITVBL2
        RTS


; =============== S U B R O U T I N E =======================================


PPU_RESTORE:
        LDA LAST_2001
        STA PPU_CTRL_REG2
        LDA #0
        LDX #0
        JSR VRAMADDR
        LDA #0
        STA PPU_SCROLL_REG
        STA PPU_SCROLL_REG
        LDA LAST_2000
        STA PPU_CTRL_REG1
        RTS


; =============== S U B R O U T I N E =======================================


VBLE:
        JSR WAITVBL
        LDA LAST_2000
        ORA #$80
        BNE WRITE2000


; =============== S U B R O U T I N E =======================================


VBLD:
        LDA LAST_2000
        AND #$7F

WRITE2000:              
        STA LAST_2000
        STA PPU_CTRL_REG1
        RTS


; =============== S U B R O U T I N E =======================================


PAL_RESET:              
        LDA #$3F ; '?'
        LDX #0
        JSR VRAMADDR
        LDY #32

PAL_RESET_LOOP:             
        LDA STARTPAL,X
        STA PPU_DATA
        INX
        DEY
        BNE PAL_RESET_LOOP


; =============== S U B R O U T I N E =======================================


VRAMADDRZ:
        LDA #$3F
        STA PPU_ADDRESS
        LDA #0
        STA PPU_ADDRESS
        STA PPU_ADDRESS
        STA PPU_ADDRESS
        RTS

; ---------------------------------------------------------------------------
STARTPAL
		.DB $19, $F,$10,$30,$19,$16,$26,$36,$19, $F,$18,$28,$19, $F,$17,  7
		.DB $19,$30,$21,$26,$19, $F,$26,$30,$19, $F,$15,$30,$19, $F,$21,$30

; =============== S U B R O U T I N E =======================================

; Wait for the button to release

WAITUNPRESS:
        LDA JOYPAD1
        BNE WAITUNPRESS ; Wait for the button to release
        RTS


; =============== S U B R O U T I N E =======================================


START:           
        LDY #0
        STY TEMP_ADDR
        INY
        STY TEMP_ADDR+1
        DEY
        TYA
        LDX #7

CLEAR_WRAM:             
        STA (TEMP_ADDR),Y
        INY
        BNE CLEAR_WRAM
        INC TEMP_ADDR+1
        DEX
        BNE CLEAR_WRAM
        LDX #0
        LDY SOFT_RESET_FLAG
        CPY #$93
        BNE CLEAR_ZP
        LDY CLEAR_TOPSCORE1
        BNE CLEAR_ZP
        LDY CLEAR_TOPSCORE2
        BNE CLEAR_ZP
        LDX #8

CLEAR_ZP:
        STA 0,X
        INX
        BNE CLEAR_ZP
        LDA #$93
        STA SOFT_RESET_FLAG

RESET_GAME:
        JSR PPU_RESET
        LDA #0
        STA SPR_TAB_TOGGLE
        JSR APU_RESET   ; Reset APU state
        LDA #1
        STA APU_MUSIC

GAME_MENU:              
        LDX #$FF
        TXS
        LDA #$F
        STA APU_MASTERCTRL_REG
        LDA #0
        STA BOOM_SOUND
        STA DEMOPLAY
        STA APU_DISABLE
        STA STAGE_STARTED
        STA DEMO_WAIT_HI
        JSR DRAWMENU
        JSR VBLE
        LDA #1
        STA INMENU

WAIT_RELEASE:               
        LDA JOYPAD1
        BNE WAIT_RELEASE

ADVANCE_FRAME:              
        LDA #8
        STA DEMO_WAIT_HI

DEMO_WAIT_LOOP:             
        JSR NEXTFRAME
        LDA JOYPAD1
        AND #$10
        BNE START_PRESSED   ; If START is pressed
        LDA JOYPAD1
        AND #$20 ; ' '
        BEQ UPDATE_RAND ; Update the random number generator
        LDA CURSOR
        EOR #1
        STA CURSOR
        JSR WAITUNPRESS ; Wait for the button to release
        JMP ADVANCE_FRAME
; ---------------------------------------------------------------------------

UPDATE_RAND:                
        JSR RAND        ; Update the random number generator
        DEC DEMO_WAIT_LO
        BNE DEMO_WAIT_LOOP
        DEC DEMO_WAIT_HI
        BNE DEMO_WAIT_LOOP
        INC DEMOPLAY    ; If the counter has expired, start the demonstration

START_PRESSED:              
        LDA DEMOPLAY
        BNE loc_C3A3
        LDA CURSOR
        BEQ loc_C3A3
        JSR sub_DA8E

loc_C3A3:               
        LDA #0
        STA INMENU
        JSR WAITUNPRESS ; Wait for the button to release
        LDA #2
        STA LIFELEFT
        LDA DEMOPLAY
        BNE loc_C3B6
        LDA CURSOR
        BNE loc_C40A

loc_C3B6:               
        LDA #1
        STA STAGE
        LDA DEMOPLAY
        BNE loc_C3C7
        LDX #6
        LDA #0

CLEAR_SCORE_LOOP:
        STA SCORE,X
        DEX
        BPL CLEAR_SCORE_LOOP

loc_C3C7:               
        LDA #$10
        STA BONUS_POWER
        LDA #0
        STA BONUS_BOMBS
        STA BONUS_REMOTE
        STA BONUS_SPEED
        STA BONUS_NOCLIP
        STA BONUS_FIRESUIT
        STA DEBUG_MODE
        LDA DEMOPLAY
        BEQ loc_C40A
        LDA #9
        STA BONUS_BOMBS
        LDA #$40 ; '@'
        STA BONUS_POWER
        LDA #1
        STA BONUS_REMOTE
        LDA #0
        STA APU_MASTERCTRL_REG
        STA SEED
        STA SEED+1
        STA SEED+2
        STA SEED+3
        STA FRAME_CNT
        LDA #$F4
        STA DEMOKEY_DATA
        LDA #$ED
        STA DEMOKEY_DATA+1
        LDA DEMO_KEYDATA
        STA DEMOKEY_TIMEOUT
        LDA DEMO_KEYDATA+1
        STA DEMOKEY_PAD1

loc_C40A:               
        LDA #0
        STA BONUS_BOMBWALK
        STA INVULNERABLE_TIMER

START_STAGE:                
        LDA #0
        STA byte_B1
        STA BONUS_STATUS
        STA STAGE_STARTED
        STA ENEMIES_DEFEATED
        STA EXIT_DWELL_TIME
        STA ENEMIES_LEFT
        STA VISITS_TOP_LEFT
        STA VISITS_TOP_RIGHT
        STA VISITS_BOTTOM_LEFT
        STA VISITS_BOTTOM_RIGHT
        STA BRICKS_BLOWN_UP
        STA CHAIN_REACTIONS
        STA KEY_TIMER
        STA EXIT_BOMBED_COUNT
        JSR STAGE_SCREEN
        LDA #2
        STA APU_MUSIC
        JSR WAITTUNE    ; Wait for the end of the current tune
        LDA #3
        STA APU_MUSIC
        JSR VBLD
        JSR BUILD_MAP   ; Generate a level map with bricks
        JSR SPAWN       ; Create monsters and bomberman
        JSR sub_E4AF
        JSR PICTURE_ON  ; Turn on the screen and sprites
        LDA #200
        STA TIMELEFT

STAGE_LOOP:             
        JSR PAUSED      ; Check if the pause is pressed (and if it is, wait for it to release)
        JSR SPRD        ; Hide Sprites
        JSR sub_CC36    ; Button handling
        JSR BOMB_TICK   ; Bomb timer processing and detonation initiation
        JSR DRAW_BOMBERMAN  ; Draw the bomberman (update the sprite)
        JSR THINK       ; Monsters.
        JSR BOMB_ANIMATE    ; Draw a bomb animation
        JSR STAGE_TIMER ; Reduce time by 1 second (normal level)
        JSR sub_E399
        LDA KILLED
        BNE loc_C481
        LDA NO_ENEMIES_LEFT
        BNE loc_C4BF
        LDA FRAME_CNT
        AND #3      ; Explosions are only updated in 1 frame out of 4
        BNE STAGE_LOOP
        JSR sub_C79D    ; Drawing explosions (?)
        JSR sub_C66C    ; Explosion tracing to find the victim
        JMP STAGE_LOOP
; ---------------------------------------------------------------------------

loc_C481:               
        LDA DEMOPLAY
        BNE loc_C4C3
        LDA #0
        STA BONUS_NOCLIP
        STA BONUS_BOMBWALK
        STA BONUS_REMOTE
        STA BONUS_FIRESUIT
        STA INVULNERABLE_TIMER
        LDA #8
        STA APU_MUSIC
        JSR WAITTUNE    ; Wait for the end of the current tune
        DEC LIFELEFT
        BMI GAME_OVER
        JMP START_STAGE
; ---------------------------------------------------------------------------

GAME_OVER:              
        LDA #0
        STA STAGE_STARTED
        JSR GAME_OVER_SCREEN
        LDA #9
        STA APU_MUSIC

GAME_OVER_WAIT:             
        LDA JOYPAD1
        AND #$10
        BNE GAME_OVER_END
        LDA APU_MUSIC
        BNE GAME_OVER_WAIT

GAME_OVER_END:              
        LDA #0
        STA APU_MUSIC

WAIT_PRESS:             
        LDA JOYPAD1
        BEQ WAIT_PRESS
        JMP GAME_MENU
; ---------------------------------------------------------------------------

loc_C4BF:               
        LDA DEMOPLAY
        BEQ NEXT_STAGE

loc_C4C3:               
        LDA #0
        STA APU_MUSIC
        INC byte_B0
        LDA byte_B0
        AND #3
        BEQ loc_C4D2
        JMP GAME_MENU
; ---------------------------------------------------------------------------

loc_C4D2:               
        JMP RESET_GAME
; ---------------------------------------------------------------------------

NEXT_STAGE:             
        LDA #10
        STA APU_MUSIC
        JSR WAITTUNE    ; Wait for the end of the current tune
        INC LIFELEFT
        INC STAGE
        LDY #0
        LDA STAGE
        CMP #51
        BNE SELECT_BONUS_MONSTER ; Choose the type of monster for the bonus level
        JMP END_GAME
; ---------------------------------------------------------------------------

SELECT_BONUS_MONSTER:           
        INY         ; Choose the type of monster for the bonus level
        SEC
        SBC #5
        BCS SELECT_BONUS_MONSTER ; Choose the type of monster for the bonus level
        DEY
        CPY #8
        BCC SELECT_STAGE_TYPE
        LDY #8      ; Monster type is limited to 1...8

SELECT_STAGE_TYPE:          
        STY BONUS_ENEMY_TYPE
        ADC #5
        CMP #1
        BEQ START_BONUS_STAGE
        JMP START_STAGE
; ---------------------------------------------------------------------------

START_BONUS_STAGE:          
        LDA #0
        STA STAGE_STARTED
        JSR BONUS_STAGE_SCREEN
        LDA #2
        STA APU_MUSIC
        JSR WAITTUNE    ; Wait for the end of the current tune
        JSR VBLD
        JSR BUILD_CONCRET_WALLS ; Build concrete walls
        JSR SPAWN       ; Create monsters and bomberman
        JSR PICTURE_ON  ; Turn on the screen and sprites
        JSR STAGE_CLEANUP
        LDA #6
        STA APU_MUSIC
        LDA #1
        STA INVULNERABLE_TIMER
        STA INVULNERABLE
        LDA #30     ; Set 30 seconds
        STA TIMELEFT

BONUS_STAGE_LOOP:           
        JSR PAUSED      ; Check if the pause is pressed (and if it is, wait for it to release)
        LDA TIMELEFT
        BEQ BONUS_STAGE_END ; If time runs out then exit the bonus level
        JSR SPRD        ; Hide Sprites
        JSR RESPAWN_BONUS_ENEMY ; If the number of monsters in the bonus level is less than 10, then add more
        JSR sub_CC36    ; Button handling
        JSR BOMB_TICK   ; Bomb timer processing and detonation initiation
        JSR DRAW_BOMBERMAN  ; Draw the bomberman (update the sprite)
        JSR THINK       ; Monsters.
        JSR BOMB_ANIMATE    ; Draw a bomb animation
        JSR BONUS_STAGE_TIMER ; Reduce time by 1 second (bonus level)
        LDA FRAME_CNT
        AND #1      ; Explosions are not updated every frame, but every other frame
        BNE BONUS_STAGE_LOOP
        JSR sub_C79D    ; Drawing explosions (?)
        JSR sub_C66C    ; Explosion tracing to find the victim
        JMP BONUS_STAGE_LOOP
; ---------------------------------------------------------------------------

BONUS_STAGE_END:            
        LDA #10
        STA APU_MUSIC
        JSR WAITTUNE    ; Wait for the end of the current tune
        LDA #0
        STA INVULNERABLE
        STA INVULNERABLE_TIMER
        JMP START_STAGE
; ---------------------------------------------------------------------------

END_GAME:               
        JSR PPU_RESET
        JSR sub_DBF9
        JSR BUILD_CONCRET_WALLS ; Build concrete walls
        LDA #8
        STA BOMBMAN_U
        STA BOMBMAN_V
        LDA #0
        STA STAGE_STARTED
        STA BOMBMAN_X
        LDA #9
        STA BOMBMAN_Y
        LDA #7
        STA APU_MUSIC
        JSR SPRE
        JSR VBLE

loc_C58F:               
        JSR NEXTFRAME
        LDA #1
        STA SPR_TAB_INDEX
        JSR SPRD        ; Hide Sprites
        JSR DRAW_BOMBERMAN  ; Draw the bomberman (update the sprite)
        LDA FRAME_CNT
        ROR
        BCS loc_C5A4
        JSR sub_CDD4

loc_C5A4:               
        LDA BOMBMAN_X
        CMP #8
        BNE loc_C58F

WAIT_END_MELODY:            
        JSR NEXTFRAME
        LDA #1
        STA SPR_TAB_INDEX
        JSR SPRD        ; Hide Sprites
        JSR sub_CEA7
        LDA FRAME_CNT
        ROR
        BCS loc_C5BF
        JSR sub_CDD4

loc_C5BF:               
        LDA APU_MUSIC
        BNE WAIT_END_MELODY

WAIT_BUTTON:                
        LDA JOYPAD1
        BEQ WAIT_BUTTON
        LDA #1
        STA STAGE
        JMP START_STAGE

; =============== S U B R O U T I N E =======================================

; Create monsters and bomberman

SPAWN:                  
        LDA #1
        STA BOMBMAN_X
        STA BOMBMAN_Y
        LDA #8
        STA BOMBMAN_U
        STA BOMBMAN_V
        LDA #0
        STA BOMBMAN_FRAME
        STA KILLED
        STA DYING
        STA NO_ENEMIES_LEFT
        JSR STAGE_CLEANUP
        JSR SPAWN_MONSTERS
        JSR sub_CB06
        JSR WAITVBL
        JSR PAL_RESET
        LDX STAGE
        LDA EXIT_ENEMY_TAB-1,X ; This table contains the type of monster that comes out of the door after an explosion
        STA EXIT_ENEMY_TYPE
        LDA #1
        STA STAGE_STARTED
        RTS


; =============== S U B R O U T I N E =======================================

; Turn on the screen and sprites

PICTURE_ON:             
        JSR SPRD        ; Hide Sprites
        JSR VBLE
        JSR PPUE
        JMP SPRE


; =============== S U B R O U T I N E =======================================

; Wait for the end of the current tune

WAITTUNE:               
        LDA APU_MUSIC
        BNE WAITTUNE    ; Wait for the end of the current tune
        RTS

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR PAUSED

ABORT_DEMOPLAY:             
        JMP loc_C4C3

; =============== S U B R O U T I N E =======================================

; Check if the pause is pressed (and if it is, wait for it to release)

PAUSED:                 
        JSR NEXTFRAME
        LDA #1
        STA SPR_TAB_INDEX
        LDA JOYPAD1
        AND #$10
        BEQ NOT_PAUSED
        LDA DEMOPLAY
        BNE ABORT_DEMOPLAY
        LDA #1
        STA APU_DISABLE
        LDA #6
        STA APU_SOUND   ; Play the sound
        JSR WAITUNPRESS ; Wait for the button to release

WAIT_START:             
        LDA JOYPAD1
        AND #$10
        BEQ WAIT_START
        LDA #6
        STA APU_SOUND   ; Play the sound
        LDA #0
        STA APU_DISABLE
        JSR WAITUNPRESS ; Wait for the button to release
        JMP NEXTFRAME
; ---------------------------------------------------------------------------

NOT_PAUSED:             
        RTS


; =============== S U B R O U T I N E =======================================

; Reduce time by 1 second (normal level)

STAGE_TIMER:                
        LDA FRAME_CNT
        AND #$3F ; '?'
        BNE STAGE_TIMER_END
        LDA TIMELEFT
        CMP #255
        BEQ STAGE_TIMER_END
        DEC TIMELEFT
        BNE STAGE_TIMER_END
        JSR KILL_ENEMY  ; Remove all monsters from the map
        LDA #8      ; Add a bunch of the coolest monsters
        STA BONUS_ENEMY_TYPE
        JMP RESPAWN_BONUS_ENEMY ; If the number of monsters in the bonus level is less than 10, then add more
; ---------------------------------------------------------------------------

STAGE_TIMER_END:            
        RTS


; =============== S U B R O U T I N E =======================================

; Reduce time by 1 second (bonus level)

BONUS_STAGE_TIMER:          
        LDA FRAME_CNT
        AND #$3F ; '?'
        BNE STAGE_TIMER_END
        LDA TIMELEFT
        BEQ STAGE_TIMER_END
        DEC TIMELEFT
        RTS


; =============== S U B R O U T I N E =======================================

; Explosion tracing to find the victim

sub_C66C:               
        LDX #$4F ; 'O'

loc_C66E:               
        LDA FIRE_ACTIVE,X
        BEQ loc_C6CD
        BPL loc_C688
        AND #$7F
        TAY
        LDA FIRE_X,X
        STA byte_1F
        LDA FIRE_Y,X
        STA byte_20
        LDA byte_C75D,Y
        JMP loc_C6DA
; ---------------------------------------------------------------------------

loc_C688:               
        LDA FIRE_X,X
        STA byte_1F
        LDA FIRE_Y,X
        STA byte_20
        LDA byte_526,X
        AND #$78 ; 'x'
        BEQ loc_C6CD
        LDA byte_526,X
        BPL loc_C6B2
        AND #7
        STA byte_32
        LDA byte_526,X
        LSR
        AND #$3C ; '<'
        CLC
        ADC byte_32
        TAY
        LDA byte_C778,Y
        JMP loc_C6DA
; ---------------------------------------------------------------------------

loc_C6B2:               
        AND #7
        BEQ loc_C6D0
        AND #1
        EOR #1
        STA byte_32
        LDA byte_526,X
        LSR
        LSR
        AND #$1E
        CLC
        ADC byte_32
        CLC
        ADC #7
        TAY
        JMP loc_C6D6
; ---------------------------------------------------------------------------

loc_C6CD:               
        JMP loc_C756
; ---------------------------------------------------------------------------

loc_C6D0:               
        LDA byte_526,X
        LSR
        LSR
        LSR

loc_C6D6:               
        TAY
        LDA byte_C764,Y

loc_C6DA:               
        AND #$FF
        BEQ loc_C753
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB
        LDA DYING
        BNE loc_C705
        LDA BONUS_FIRESUIT
        BNE loc_C705
        LDA INVULNERABLE_TIMER
        BNE loc_C705
        LDA BOMBMAN_X
        CMP byte_1F
        BNE loc_C705
        LDA BOMBMAN_Y
        CMP byte_20
        BNE loc_C705
        LDA #5
        STA APU_SOUND   ; Play the sound
        LDA #1
        STA DYING
        LDA #12
        STA BOMBMAN_FRAME

loc_C705:               
        LDY #9

loc_C707:               
        LDA ENEMY_TYPE,Y
        BEQ loc_C74E
        CMP #9
        BCS loc_C74E
        LDA ENEMY_X,Y
        CMP byte_1F
        BNE loc_C74E
        LDA ENEMY_Y,Y
        CMP byte_20
        BNE loc_C74E
        INC ENEMIES_DEFEATED
        LDA #0
        STA VISITS_TOP_LEFT
        STA VISITS_TOP_RIGHT
        STA VISITS_BOTTOM_LEFT
        STA VISITS_BOTTOM_RIGHT
        LDA #$64 ; 'd'
        STA byte_5C6,Y
        LDA ENEMY_TYPE,Y
        STA ENEMY_FACE,Y
        LDA IS_SECOND_PASSED
        STA byte_5DA,Y
        INC IS_SECOND_PASSED
        LDA #9
        STA ENEMY_TYPE,Y
        LDA ENEMY_FRAME,Y
        LSR
        LSR
        AND #7
        CLC
        ADC #$20 ; ' '
        STA ENEMY_FRAME,Y

loc_C74E:               
        DEY
        BPL loc_C707
        BMI loc_C756

loc_C753:               
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB

loc_C756:               
        DEX
        BMI locret_C75C
        JMP loc_C66E
; ---------------------------------------------------------------------------

locret_C75C:                
        RTS

; ---------------------------------------------------------------------------
byte_C75D:  .DB $27,  3,  4,  5,  6,  7,  0 
byte_C764:  .DB   0, $B, $C, $D, $E, $D, $C, $B 
        .DB   0, $F,$10,$11,$12,$13,$14,$15
        .DB $16,$13,$14,$11
byte_C778:  .DB $12, $F,$10,  0,  0,$17,$18,$19 
        .DB $1A,$1B,$1C,$1D,$1E,$1F,$20,$21
        .DB $22,$23,$24,$25,$26,$1F,$20,$21
        .DB $22,$1B,$1C,$1D,$1E,$17,$18,$19
        .DB $1A,  0,  0,  0,  0

; =============== S U B R O U T I N E =======================================

; Drawing explosions (?)

sub_C79D:               
        LDX #79

loc_C79F:               
        LDA FIRE_ACTIVE,X
        BNE loc_C7A7

loc_C7A4:               
        JMP loc_C8A6
; ---------------------------------------------------------------------------

loc_C7A7:               
        PHA
        LDY FIRE_Y,X
        STY byte_20
        JSR FIX_STAGE_PTR   ; Fix the pointer to the current map cell
        LDY FIRE_X,X
        STY byte_1F
        PLA
        BPL loc_C7CB
        INC FIRE_ACTIVE,X
        LDA FIRE_ACTIVE,X
        CMP #$87
        BNE loc_C7A4
        LDA #0
        STA FIRE_ACTIVE,X
        STA (STAGE_MAP),Y
        BEQ loc_C7A4

loc_C7CB:               
        LDA (STAGE_MAP),Y
        TAY
        BEQ loc_C838
        CPY #2
        BNE loc_C7DE
        INC BRICKS_BLOWN_UP
        LDA #$80
        STA FIRE_ACTIVE,X
        JMP loc_C8A6
; ---------------------------------------------------------------------------

loc_C7DE:               
        CPY #3
        BNE loc_C7EE
        LDA byte_4D6,X
        ORA #$10
        LDY byte_1F
        STA (STAGE_MAP),Y
        JMP loc_C830
; ---------------------------------------------------------------------------

loc_C7EE:               
        CPY #4
        BNE loc_C800
        LDY byte_1F
        LDA #8
        STA (STAGE_MAP),Y
        LDA #$28 ; '('
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB
        JMP loc_C830
; ---------------------------------------------------------------------------

loc_C800:               
        CPY #5
        BNE loc_C815
        LDY byte_1F
        LDA #6
        STA (STAGE_MAP),Y
        LDA #$28 ; '('
        CLC
        ADC EXIT_ENEMY_TYPE
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB
        JMP loc_C830
; ---------------------------------------------------------------------------

loc_C815:               
        CPY #8
        BEQ loc_C828
        CPY #6
        BNE loc_C830
        LDY byte_1F
        LDA #0
        STA (STAGE_MAP),Y
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB
        DEC EXIT_BOMBED_COUNT

loc_C828:               
        INC EXIT_BOMBED_COUNT
        JSR sub_C8AD
        JMP loc_C830

loc_C830:               
        LDA #0
        STA FIRE_ACTIVE,X

loc_C835:               
        JMP loc_C8A6
; ---------------------------------------------------------------------------

loc_C838:               
        LDA byte_526,X
        CLC
        ADC #8
        STA byte_526,X
        AND #$7F
        CMP #$48
        BCS loc_C7EE
        LDA byte_4D6,X
        STA byte_36
        AND #7
        BEQ loc_C835
        TAY
        LDA #0
        STA byte_4D6,X
        LDA FIRE_X,X
        CLC
        ADC byte_CA16,Y
        STA byte_1F
        LDA FIRE_Y,X
        CLC
        ADC byte_CA11,Y
        STA byte_20
        LDY #$4F ; 'O'
        JSR sub_CBE5
        BNE loc_C8A6
        LDA byte_1F
        STA FIRE_X,Y
        LDA byte_20
        STA FIRE_Y,Y
        LDA #1
        STA FIRE_ACTIVE,Y
        LDA byte_36
        AND #7
        STA byte_526,Y
        LDA byte_36
        CLC
        ADC #$10
        CMP BONUS_POWER
        BCC loc_C89E
        LDA #0
        STA FIRE_ACTIVE,Y
        LDA byte_526,X
        ORA #$80
        STA byte_526,X
        JMP loc_C8A1
; ---------------------------------------------------------------------------

loc_C89E:               
        STA byte_4D6,Y

loc_C8A1:               
        LDA #0
        STA byte_4D6,X

loc_C8A6:               
        DEX
        BMI locret_C8AC
        JMP loc_C79F
; ---------------------------------------------------------------------------

locret_C8AC:                
        RTS


; =============== S U B R O U T I N E =======================================


sub_C8AD:               
        LDY #9

loc_C8AF:               
        LDA ENEMY_TYPE,Y
        BNE loc_C8E9
        LDA EXIT_ENEMY_TYPE
        STA ENEMY_TYPE,Y
        STA ENEMY_FRAME,Y
        LDA #8
        STA ENEMY_U,Y
        STA ENEMY_V,Y
        JSR RAND
        AND #3
        CLC
        ADC #1
        STA ENEMY_FACE,Y
        LDA byte_1F
        STA ENEMY_X,Y
        LDA byte_20
        STA ENEMY_Y,Y
        LDA #0
        STA byte_5DA,Y
        STA byte_5C6,Y
        STA byte_5E4,Y
        LDA #$1E
        STA byte_5B2,Y

loc_C8E9:               
        DEY
        BPL loc_C8AF
        RTS


; =============== S U B R O U T I N E =======================================

; If the number of monsters in the bonus level is less than 10, then add more

RESPAWN_BONUS_ENEMY:            
        LDY #9

SPAWN_BMONSTR:              
        LDA ENEMY_TYPE,Y
        BNE NEXT_BMONSTR
        LDA BONUS_ENEMY_TYPE
        STA ENEMY_TYPE,Y
        SEC
        SBC #1
        ASL
        ASL
        STA ENEMY_FRAME,Y
        LDA #8
        STA ENEMY_U,Y
        STA ENEMY_V,Y
        JSR RAND
        AND #3
        CLC
        ADC #1
        STA ENEMY_FACE,Y
        STY byte_5A
        JSR RAND_COORDS
        LDY byte_5A
        LDA TEMP_X
        STA ENEMY_X,Y
        LDA TEMP_Y
        STA ENEMY_Y,Y
        LDA #0
        STA byte_5DA,Y
        STA byte_5C6,Y
        STA byte_5E4,Y
        LDA #$1E
        STA byte_5B2,Y

NEXT_BMONSTR:               
        DEY
        BPL SPAWN_BMONSTR
        RTS


; =============== S U B R O U T I N E =======================================

; Blow up all the bombs

DETONATE:               
        LDX #9

DETONATE_LOOP:              
        LDA BOMB_ACTIVE,X
        BEQ DETONATE_NEXT
        LDY BOMB_Y,X
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        STY byte_20
        LDY BOMB_X,X
        STY byte_1F
        LDA #0
        JSR sub_C9B6
        JSR PLAY_BOOM_SOUND ; Play the sound of a bomb exploding
        LDA #0
        STA (STAGE_MAP),Y
        LDA #0
        STA BOMB_ACTIVE,X
        RTS
; ---------------------------------------------------------------------------

DETONATE_NEXT:              
        DEX
        BPL DETONATE_LOOP
        RTS


; =============== S U B R O U T I N E =======================================

; Bomb timer processing and detonation initiation

BOMB_TICK:              
        LDX #9

BOMB_TICK_LOOP:             
        LDA BOMB_ACTIVE,X
        BEQ BOMB_TICK_NEXT
        LDY BOMB_Y,X
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        STY byte_20
        LDY BOMB_X,X
        STY byte_1F
        LDA (STAGE_MAP),Y
        CMP #3
        BNE loc_C999
        INC BOMB_TIME_ELAPSED,X
        LDA BONUS_REMOTE
        BNE BOMB_TICK_NEXT
        DEC BOMB_TIME_LEFT,X
        BNE BOMB_TICK_NEXT
        LDA #0

loc_C999:               
        AND #7
        JSR sub_C9B6
        LDA CHAIN_REACTIONS
        CMP #$FF
        BEQ loc_C9A6
        INC CHAIN_REACTIONS

loc_C9A6:               
        JSR PLAY_BOOM_SOUND ; Play the sound of a bomb exploding
        LDA #0
        STA (STAGE_MAP),Y
        LDA #0
        STA BOMB_ACTIVE,X

BOMB_TICK_NEXT:             
        DEX
        BPL BOMB_TICK_LOOP

BOMB_TICK_END:              
        RTS


; =============== S U B R O U T I N E =======================================


sub_C9B6:               
        STX byte_2F
        STY byte_30
        TAY
        LDA byte_C9DE,Y
        STA byte_2E
        LDA #1
        JSR sub_C9E3
        LDA #2
        JSR sub_C9E3
        LDA #3
        JSR sub_C9E3
        LDA #4
        JSR sub_C9E3
        LDA #0
        JSR sub_C9E3
        LDX byte_2F
        LDY byte_30
        RTS

; ---------------------------------------------------------------------------
byte_C9DE:  .DB $FF,  3,  4,  1,  2 

; =============== S U B R O U T I N E =======================================


sub_C9E3:               
        CMP byte_2E
        BEQ BOMB_TICK_END
        STA byte_31
        TAX
        LDY #$4F ; 'O'
        JSR sub_CBE5
        BMI locret_CA10
        LDA byte_20
        CLC
        ADC byte_CA11,X
        STA FIRE_Y,Y
        LDA byte_1F
        CLC
        ADC byte_CA16,X
        STA FIRE_X,Y
        LDA byte_31
        STA byte_4D6,Y
        STA byte_526,Y
        LDA #1
        STA FIRE_ACTIVE,Y

locret_CA10:                
        RTS

; ---------------------------------------------------------------------------
byte_CA11:  .DB   0,  0,$FF,  0,  1 
byte_CA16:  .DB   0,  1,  0,$FF,  0 

; =============== S U B R O U T I N E =======================================

; Draw a bomb animation

BOMB_ANIMATE:               
        LDX #9

BOMB_ANIM_LOOP:             
        LDA BOMB_ACTIVE,X
        BEQ BOMB_ANIM_NEXT  ; If the bomb is not set, skip
        LDA BOMB_X,X
        STA byte_1F
        LDA BOMB_Y,X
        STA byte_20
        LDA BOMB_TIME_ELAPSED,X
        AND #$F     ; Animation delay
        BNE BOMB_ANIM_NEXT
        LDA BOMB_TIME_ELAPSED,X
        LSR
        LSR
        LSR
        LSR
        AND #3
        TAY
        LDA BOMB_ANIM,Y ; Select an animation frame from the table
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB

BOMB_ANIM_NEXT:             
        DEX
        BPL BOMB_ANIM_LOOP
        RTS

; ---------------------------------------------------------------------------
BOMB_ANIM:  .DB   9, $A,  9,  8   

; =============== S U B R O U T I N E =======================================

; Generate a level map with bricks

BUILD_MAP:              
        JSR BUILD_CONCRET_WALLS ; Build concrete walls
        JSR RAND_COORDS
        LDA #4
        STA (STAGE_MAP),Y
        JSR RAND_COORDS
        LDA #5
        STA (STAGE_MAP),Y
        LDA #$32 ; '2'
        CLC
        ADC STAGE
        CLC
        ADC STAGE
        STA byte_1F

NEXT_BRICK:             
        JSR RAND_COORDS
        LDA #2
        STA (STAGE_MAP),Y
        DEC byte_1F
        BNE NEXT_BRICK
        RTS


; =============== S U B R O U T I N E =======================================

; Build concrete walls

BUILD_CONCRET_WALLS:            
        LDA #0
        STA STAGE_MAP
        LDA #2
        STA STAGE_MAP+1
        LDY #0
        LDX #0
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #$40 ; '@'
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #$40 ; '@'
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #$40 ; '@'
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #$40 ; '@'
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #$40 ; '@'
        JSR STAGE_ROW
        LDX #$20 ; ' '
        JSR STAGE_ROW
        LDX #0


; =============== S U B R O U T I N E =======================================


STAGE_ROW:              
        LDA #$20 ; ' '
        STA TEMP_X

STAGE_CELL:             
        LDA STAGE_ROWS,X
        STA (STAGE_MAP),Y
        INC STAGE_MAP
        BNE HI_PART
        INC STAGE_MAP+1

HI_PART:                
        INX
        DEC TEMP_X
        BNE STAGE_CELL
        RTS


; =============== S U B R O U T I N E =======================================


RAND_COORDS:                
        JSR RAND
        ROR
        ROR
        AND #$1F
        BEQ RAND_COORDS
        STA TEMP_X

loc_CADA:               
        JSR RAND
        ROR
        ROR
        ROR
        AND #$F
        BEQ loc_CADA
        CMP #$C
        BCS loc_CADA
        STA TEMP_Y
        TAY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY TEMP_X
        LDA (STAGE_MAP),Y
        BNE RAND_COORDS
        CPY #3
        BCS locret_CB05
        LDA TEMP_Y
        CMP #3
        BCC RAND_COORDS

locret_CB05:                
        RTS


; =============== S U B R O U T I N E =======================================


sub_CB06:               
        JSR PPUD
        LDA #0
        STA byte_20
        LDA #0
        STA OAM_PTR
        LDA #2
        STA OAM_PTR+1
        LDY #0

loc_CB17:               
        LDA #0
        STA byte_1F

loc_CB1B:               
        LDA DEBUG_MODE
        BEQ loc_CB24
        LDA (OAM_PTR),Y
        JMP loc_CB30
; ---------------------------------------------------------------------------

loc_CB24:               
        LDA (OAM_PTR),Y
        CMP #4
        BEQ loc_CB2E
        CMP #5
        BNE loc_CB30

loc_CB2E:               
        LDA #2

loc_CB30:               
        JSR sub_CB4E
        INY
        BNE loc_CB38
        INC OAM_PTR+1

loc_CB38:               
        INC byte_1F
        LDA byte_1F
        AND #$20 ; ' '
        BEQ loc_CB1B
        INC byte_20
        LDA byte_20
        CMP #13
        BNE loc_CB17
        JSR TIME_AND_LIFE   ; Draw text "TIME" and "LEFT XX"
        JMP PPU_RESTORE


; =============== S U B R O U T I N E =======================================


sub_CB4E:               
        STY TEMP_Y
        JSR sub_D924
        LDX #0

loc_CB55:               
        LDA $17,X
        STA TILE_TAB,X
        INX
        CPX #8
        BNE loc_CB55
        JSR sub_CB65
        LDY TEMP_Y
        RTS


; =============== S U B R O U T I N E =======================================


sub_CB65:               
        LDA TILE_TAB+2
        ORA TILE_TAB
        PHA
        STA PPU_ADDRESS
        LDX TILE_TAB+1
        STX PPU_ADDRESS
        LDX TILE_TAB+3
        LDA TILE_MAP,X
        STA PPU_DATA
        LDA TILE_MAP+1,X
        STA PPU_DATA
        PLA
        STA PPU_ADDRESS
        LDA TILE_TAB+1
        CLC
        ADC #$20 ; ' '
        STA PPU_ADDRESS
        LDA $D9C8,X
        STA PPU_DATA
        LDA TILE_MAP+3,X
        STA PPU_DATA
        LDA #$23 ; '#'
        ORA TILE_TAB
        PHA
        STA PPU_ADDRESS
        LDA TILE_TAB+4
        STA PPU_ADDRESS
        TAX
        LDA PPU_DATA
        LDA PPU_DATA
        AND TILE_TAB+6
        ORA TILE_TAB+7
        TAY
        PLA
        STA PPU_ADDRESS
        STX PPU_ADDRESS
        STY PPU_DATA
        RTS


; =============== S U B R O U T I N E =======================================


STAGE_CLEANUP:              
        LDX #9
        LDA #0

CLEAN_BOMBS:                
        STA BOMB_ACTIVE,X
        DEX
        BPL CLEAN_BOMBS
        LDX #79

CLEAN_EXPLO:                
        STA FIRE_ACTIVE,X
        DEX
        BPL CLEAN_EXPLO


; =============== S U B R O U T I N E =======================================

; Remove all monsters from the map

KILL_ENEMY:             
        LDA #0
        LDX #9

KILL_LOOP:              
        STA ENEMY_TYPE,X
        DEX
        BPL KILL_LOOP
        RTS

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR sub_CBE5

loc_CBE2:               
        DEY
        BMI locret_CBEA


; =============== S U B R O U T I N E =======================================


sub_CBE5:               
        LDA FIRE_ACTIVE,Y
        BNE loc_CBE2

locret_CBEA:                
        RTS


; =============== S U B R O U T I N E =======================================

; Fix the pointer to the current map cell

FIX_STAGE_PTR:              
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        RTS


; =============== S U B R O U T I N E =======================================

; Play the sound of a bomb exploding

PLAY_BOOM_SOUND:            
        LDA #1
        STA BOOM_SOUND
        RTS


; =============== S U B R O U T I N E =======================================


NEXTFRAME:              
        LDA FRAMEDONE
        BNE NEXTFRAME
        LDA #1
        STA FRAMEDONE

locret_CC03:
        RTS

; ---------------------------------------------------------------------------
EXIT_ENEMY_TAB:
		.DB   2,  1,  5,  3,  1,  1,  2,  5,  6,  4 ; This table contains the type of monster that comes out of the door after an explosion
        .DB   1,  1,  5,  6,  2,  4,  1,  6,  1,  5 
        .DB   6,  5,  1,  5,  6,  8,  2,  1,  5,  7
        .DB   4,  1,  5,  8,  6,  7,  5,  2,  4,  8
        .DB   5,  4,  6,  5,  8,  4,  6,  5,  7,  8

; =============== S U B R O U T I N E =======================================

; Button handling

sub_CC36:               
        LDA INVULNERABLE
        BNE loc_CC4C
        LDA INVULNERABLE_TIMER
        BEQ loc_CC4C
        LDA FRAME_CNT
        AND #7
        BNE loc_CC4C
        DEC INVULNERABLE_TIMER
        BNE loc_CC4C
        LDA #3
        STA APU_MUSIC

loc_CC4C:               
        LDA DYING
        BEQ loc_CC63
        LDA FRAME_CNT
        AND #$F
        BNE locret_CC62
        INC BOMBMAN_FRAME
        LDA BOMBMAN_FRAME
        CMP #20
        BNE locret_CC62
        LDA #1
        STA KILLED

locret_CC62:                
        RTS
; ---------------------------------------------------------------------------

loc_CC63:               
        LDA BOMBMAN_U
        CMP #8
        BNE loc_CCA4    ; Check the speed of the bomberman
        LDA BOMBMAN_V
        CMP #8
        BNE loc_CCA4    ; Check the speed of the bomberman
        LDY BOMBMAN_Y
        STY byte_20
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        STY byte_1F
        LDA (STAGE_MAP),Y
        CMP #8
        BEQ loc_CC95
        CMP #6
        BNE loc_CCA4    ; Check the speed of the bomberman
        LDA #0
        STA (STAGE_MAP),Y
        JSR DRAW_TILE   ; Add a new tile to TILE_TAB
        JMP loc_CEE9
; ---------------------------------------------------------------------------

loc_CC95:               
        INC EXIT_DWELL_TIME
        LDA #0
        STA KEY_TIMER
        LDA ENEMIES_LEFT
        BNE loc_CCA4    ; Check the speed of the bomberman
        LDA #1
        STA NO_ENEMIES_LEFT

locret_CCA3:                
        RTS
; ---------------------------------------------------------------------------

loc_CCA4:               
        LDA BONUS_SPEED ; Check the speed of the bomberman
        BNE FAST_MOVE
        LDA FRAME_CNT
        AND #3      ; Without bonus speed, the bomberman stomps only once every 4 frames
        BEQ locret_CCA3

FAST_MOVE:              
        JSR GET_INPUT   ; Return to A the value of buttons P1 | P2
        BNE CASE_RIGHT
        STA KEY_TIMER
        STA LAST_INPUT

CASE_RIGHT:             
        TAX
        AND #1      ; Right
        BEQ CASE_LEFT
        JSR sub_CDD4

CASE_LEFT:              
        TXA
        AND #2      ; Left
        BEQ CASE_UP
        JSR sub_CDA3

CASE_UP:                
        TXA
        AND #8      ; Up
        BEQ CASE_DOWN
        JSR sub_CD70

CASE_DOWN:              
        TXA
        AND #4      ; Down
        BEQ CASE_ACTION
        JSR sub_CD39

CASE_ACTION:                
        TXA
        AND #$80            ; A
        BNE CASE_A
        LDA BONUS_REMOTE    ; Only if the bomberman has a radio detonator
        BEQ CASE_NOTHING
        LDA LAST_INPUT
        BNE CASE_NOTHING
        TXA
        AND #$40            ; B
        BEQ CASE_NOTHING
        STA LAST_INPUT
        JSR DETONATE    ; Blow up all the bombs

CASE_NOTHING:               
        RTS
; ---------------------------------------------------------------------------

CASE_A:                 
        LDY BOMBMAN_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        LDA (STAGE_MAP),Y
        BNE CASE_NOTHING    ; There's already something in this place, don't put a bomb
        JSR ADJUST_BOMBMAN_HPOS ; Move the bomber a little to the left or right after placing the bomb
        JSR ADJUST_BOMBMAN_VPOS ; Move the bomber up or down a bit after placing the bomb
        LDX BONUS_BOMBS

CHECK_AMMO_LEFT:            
        LDA BOMB_ACTIVE,X
        BEQ PLACE_BOMB
        DEX
        BPL CHECK_AMMO_LEFT
        RTS
; ---------------------------------------------------------------------------

PLACE_BOMB:             
        LDA #3
        STA (STAGE_MAP),Y
        LDA BOMBMAN_X
        STA BOMB_X,X
        LDA BOMBMAN_Y
        STA BOMB_Y,X
        LDA #0
        STA BOMB_TIME_ELAPSED,X
        LDA #0
        STA byte_3C8,X
        LDA #160
        STA BOMB_TIME_LEFT,X
        LDA #1
        STA BOMB_ACTIVE,X
        LDA #3
        STA APU_SOUND   ; Play the sound
        RTS


; =============== S U B R O U T I N E =======================================


sub_CD39:               
        LDA BOMBMAN_V
        CMP #8
        BCS loc_CD44
        INC BOMBMAN_V
        JMP loc_CD69
; ---------------------------------------------------------------------------

loc_CD44:               
        LDY BOMBMAN_Y
        INY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        JSR sub_CF60
        BNE loc_CD69
        JSR ADJUST_BOMBMAN_HPOS ; Move the bomber a little to the left or right after placing the bomb
        INC BOMBMAN_V
        LDA BOMBMAN_V
        CMP #$10
        BNE loc_CD69
        LDA #0
        STA BOMBMAN_V
        INC BOMBMAN_Y

loc_CD69:               
        LDA #4
        LDY #7
        JMP loc_CE2E


; =============== S U B R O U T I N E =======================================


sub_CD70:               
        LDA BOMBMAN_V
        CMP #9
        BCC loc_CD7B
        DEC BOMBMAN_V
        JMP loc_CD9C
; ---------------------------------------------------------------------------

loc_CD7B:               
        LDY BOMBMAN_Y
        DEY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        JSR sub_CF60
        BNE loc_CD9C
        JSR ADJUST_BOMBMAN_HPOS ; Move the bomber a little to the left or right after placing the bomb
        DEC BOMBMAN_V
        BPL loc_CD9C
        LDA #$F
        STA BOMBMAN_V
        DEC BOMBMAN_Y

loc_CD9C:               
        LDA #8
        LDY #$B
        JMP loc_CE2E


; =============== S U B R O U T I N E =======================================


sub_CDA3:               
        LDA BOMBMAN_U
        CMP #9
        BCC loc_CDAE
        DEC BOMBMAN_U
        JMP loc_CDCF
; ---------------------------------------------------------------------------

loc_CDAE:               
        LDY BOMBMAN_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        DEY
        JSR sub_CF60
        BNE loc_CDCF
        JSR ADJUST_BOMBMAN_VPOS ; Move the bomber up or down a bit after placing the bomb
        DEC BOMBMAN_U
        BPL loc_CDCF
        LDA #$F
        STA BOMBMAN_U
        DEC BOMBMAN_X

loc_CDCF:               
        LDA #0
        JMP loc_CE06


; =============== S U B R O U T I N E =======================================


sub_CDD4:               
        LDA BOMBMAN_U
        CMP #8
        BCS loc_CDDF
        INC BOMBMAN_U
        JMP loc_CE04
; ---------------------------------------------------------------------------

loc_CDDF:               
        LDY BOMBMAN_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY BOMBMAN_X
        INY
        JSR sub_CF60
        BNE loc_CE04
        JSR ADJUST_BOMBMAN_VPOS ; Move the bomber up or down a bit after placing the bomb
        INC BOMBMAN_U
        LDA BOMBMAN_U
        CMP #$10
        BNE loc_CE04
        LDA #0
        STA BOMBMAN_U
        INC BOMBMAN_X

loc_CE04:               
        LDA #$40 ; '@'

loc_CE06:               
        STA byte_2D
        LDA #0
        LDY #3
        JMP loc_CE2E

; ---------------------------------------------------------------------------
        .DB $60 ; `

; =============== S U B R O U T I N E =======================================

; Move the bomber a little to the left or right after placing the bomb

ADJUST_BOMBMAN_HPOS:            
        LDA BOMBMAN_U
        CMP #8
        BCC ADJUST_RIGHT
        BEQ DONT_ADJUST
        DEC BOMBMAN_U
        RTS
; ---------------------------------------------------------------------------

ADJUST_RIGHT:               
        INC BOMBMAN_U
        RTS
; ---------------------------------------------------------------------------

DONT_ADJUST:                
        RTS


; =============== S U B R O U T I N E =======================================

; Move the bomber up or down a bit after placing the bomb

ADJUST_BOMBMAN_VPOS:            
        LDA BOMBMAN_V
        CMP #8
        BCC ADJUST_DOWN
        BEQ DONT_ADJUST2
        DEC BOMBMAN_V
        RTS
; ---------------------------------------------------------------------------

ADJUST_DOWN:                
        INC BOMBMAN_V
        RTS
; ---------------------------------------------------------------------------

DONT_ADJUST2:               
        RTS

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR sub_CD39

loc_CE2E:               
        PHA
        LDA FRAME_CNT
        AND #3
        CMP #2
        BNE loc_CE59
        LDA FRAME_CNT
        PLA
        INC KEY_TIMER
        INC BOMBMAN_FRAME
        CMP BOMBMAN_FRAME
        BCC loc_CE45
        STA BOMBMAN_FRAME
        RTS
; ---------------------------------------------------------------------------

loc_CE45:               
        CPY BOMBMAN_FRAME
        BCC loc_CE4A
        RTS
; ---------------------------------------------------------------------------

loc_CE4A:               
        STA BOMBMAN_FRAME
        CMP #4
        BCC loc_CE54
        LDA #2
        BNE loc_CE56

loc_CE54:               
        LDA #1

loc_CE56:               
        STA APU_SOUND   ; Play the sound
        RTS
; ---------------------------------------------------------------------------

loc_CE59:               
        PLA

INCORRECT_FRAMENUM:         
        RTS

; =============== S U B R O U T I N E =======================================

; Draw the bomberman (update the sprite)

DRAW_BOMBERMAN:             
        LDA BOMBMAN_FRAME
        CMP #19
        BCS INCORRECT_FRAMENUM
        LDA byte_2D
        STA SPR_ATTR
        LDY #0
        STY SPR_COL
        LDA BOMBMAN_X
        CMP #8
        BCC DONT_SCROLL
        LDY #$F0
        CMP #23
        BCS DONT_SCROLL
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC BOMBMAN_U
        SEC
        SBC #$80
        TAY

DONT_SCROLL:                
        STY H_SCROLL
        LDA BOMBMAN_X
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC BOMBMAN_U
        SEC
        SBC #8
        SBC H_SCROLL
        STA SPR_X
        LDA BOMBMAN_Y
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC BOMBMAN_V
        ADC #23
        STA SPR_Y
        LDX BOMBMAN_FRAME
        LDA BOMBER_ANIM,X
        JMP SPR_DRAW    ; Update the sprite (the A register is the sequential number of the 16x16 sprite image)


; =============== S U B R O U T I N E =======================================


sub_CEA7:               
        LDA byte_2D
        STA SPR_ATTR
        LDY #3
        STY SPR_COL
        LDA BOMBMAN_X
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC BOMBMAN_U
        SEC
        SBC #8
        STA SPR_X
        LDA BOMBMAN_Y
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC BOMBMAN_V
        ADC #$17
        STA SPR_Y
        LDX BOMBMAN_FRAME
        LDA byte_CED2,X
        JMP SPR_DRAW    ; Update the sprite (the A register is the sequential number of the 16x16 sprite image)

; ---------------------------------------------------------------------------
byte_CED2:  .DB $10,$11,$12,$11   
BOMBER_ANIM:    .DB   0,  1,  2,  1,  3,  4,  5,  4,  6,  7,  8,  7,  9, 10, 11, 12
        .DB  13, 14, 15
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR sub_CC36

loc_CEE9:               
        LDA #4
        STA APU_SOUND   ; Play the sound
        LDA #$A
        JSR sub_DD83
        LDX EXIT_ENEMY_TYPE
        DEX
        BEQ loc_CF0D
        DEX
        BEQ loc_CF1A
        DEX
        BEQ loc_CF2A
        DEX
        BEQ loc_CF33
        DEX
        BEQ loc_CF3C
        DEX
        BEQ loc_CF45
        DEX
        BEQ loc_CF4E
        DEX
        BEQ loc_CF57
        RTS
; ---------------------------------------------------------------------------

loc_CF0D:               
        LDA BONUS_BOMBS
        CMP #9
        BEQ loc_CF15
        INC BONUS_BOMBS

loc_CF15:               
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF1A:               
        LDA BONUS_POWER
        CMP #$50 ; 'P'
        BEQ loc_CF25
        CLC
        ADC #$10
        STA BONUS_POWER

loc_CF25:               
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF2A:               
        LDA #1
        STA BONUS_SPEED
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF33:               
        LDA #1
        STA BONUS_NOCLIP
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF3C:               
        LDA #1
        STA BONUS_REMOTE
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF45:               
        LDA #1
        STA BONUS_BOMBWALK
        LDA #4
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF4E:               
        LDA #1
        STA BONUS_FIRESUIT
        LDA #5
        STA APU_MUSIC
        RTS
; ---------------------------------------------------------------------------

loc_CF57:               
        LDA #$FF
        STA INVULNERABLE_TIMER
        LDA #5
        STA APU_MUSIC
        RTS

; =============== S U B R O U T I N E =======================================


sub_CF60:               
        LDA (STAGE_MAP),Y
        BEQ locret_CF7C
        CMP #8
        BEQ locret_CF7C
        CMP #6
        BEQ locret_CF7C
        CMP #2
        BEQ loc_CF7D
        CMP #4
        BEQ loc_CF7D
        CMP #5
        BEQ loc_CF7D
        CMP #3
        BEQ loc_CF82

locret_CF7C:                
        RTS
; ---------------------------------------------------------------------------

loc_CF7D:               
        LDA BONUS_NOCLIP
        EOR #1
        RTS
; ---------------------------------------------------------------------------

loc_CF82:               
        LDA BONUS_BOMBWALK
        EOR #1
        RTS


; =============== S U B R O U T I N E =======================================

; Return to A the value of buttons P1 | P2

GET_INPUT:              
        LDA DEMOPLAY
        BEQ NOT_DEMO
        LDA DEMOKEY_PAD1
        DEC DEMOKEY_TIMEOUT
        BNE SKIP_DEMO_KEY
        PHA
        LDY #0
        LDA (DEMOKEY_DATA),Y
        STA DEMOKEY_TIMEOUT
        JSR DEMO_GETNEXT    ; Fetch the next byte from the demo data
        LDA (DEMOKEY_DATA),Y
        STA DEMOKEY_PAD1
        JSR DEMO_GETNEXT    ; Fetch the next byte from the demo data
        PLA

SKIP_DEMO_KEY:              
        RTS
; ---------------------------------------------------------------------------

NOT_DEMO:               
        LDA JOYPAD1
        ORA JOYPAD2
        RTS


; =============== S U B R O U T I N E =======================================

; Fetch the next byte from the demo data

DEMO_GETNEXT:               
        INC DEMOKEY_DATA
        BNE DEMO_GETNEXT_HI
        INC DEMOKEY_DATA+1

DEMO_GETNEXT_HI:            
        RTS


; =============== S U B R O U T I N E =======================================

; Monsters.

THINK:                  
        LDA #0
        STA ENEMIES_LEFT
        LDA #$C0 ; 'L'
        STA byte_6B
        LDX #9

THINK_LOOP:             
        LDA ENEMY_TYPE,X
        BEQ THINK_NEXT
        CMP #9
        BCS loc_CFC5
        INC ENEMIES_LEFT

loc_CFC5:               
        LDY byte_5B2,X
        BEQ loc_CFCF
        DEC byte_5B2,X
        BNE THINK_NEXT

loc_CFCF:               
        ASL
        TAY
        JSR ENEMY_SAVE  ; Put the description of the current monster in temporary variables
        LDA #$CF
        PHA
        LDA #$E2
        PHA
        LDA THINK_PROC-1,Y
        PHA
        LDA THINK_PROC-2,Y
        PHA
        RTS
; ---------------------------------------------------------------------------
        JSR ENEMY_LOAD  ; Return point after the THINK monster procedure
        JSR loc_D006

THINK_NEXT:             
        DEX
        BPL THINK_LOOP

THINK_END:              
        RTS


; =============== S U B R O U T I N E =======================================


sub_CFED:               
        LDA BONUS_AVAILABLE
        CLC
        ADC #$2C ; ','
        STA M_FRAME
        LDA EXTRA_BONUS_ITEM_X
        STA M_X
        LDA EXTRA_BONUS_ITEM_Y
        STA M_Y
        LDA #8
        STA M_U
        STA M_V
        LDA #0
        BEQ loc_D010

loc_D006:               
        LDA M_TYPE
        BEQ THINK_END
        CMP #11
        BEQ loc_D08C
        LDA byte_48

loc_D010:               
        STA SPR_ATTR
        LDY #0
        STY byte_50
        LDA M_X
        ASL
        ASL
        ASL
        ASL
        ROL byte_50
        CLC
        ADC M_U
        STA byte_4F
        LDA byte_50
        ADC #0
        STA byte_50
        LDA byte_4F
        SEC
        SBC #8
        STA byte_4F
        LDA byte_50
        SBC #0
        STA byte_50
        LDA byte_4F
        SEC
        SBC H_SCROLL
        STA byte_4F
        LDA byte_50
        SBC #0
        BNE locret_D08B
        LDA byte_4F
        CMP #$F8
        BCS locret_D08B
        STA SPR_X
        LDA M_Y
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC M_V
        ADC #$17
        STA SPR_Y
        LDY M_FRAME
        LDA MONSTER_ATTR,Y
        STA SPR_COL
        LDA MONSTER_TILE,Y
        JSR SPR_DRAW    ; Update the sprite (the A register is the sequential number of the 16x16 sprite image)
        LDA M_FRAME
        CMP #$20 ; ' '
        BCS locret_D08B
        LDA DYING
        BNE locret_D08B
        LDA INVULNERABLE_TIMER
        BNE locret_D08B
        LDA M_X
        CMP BOMBMAN_X
        BNE locret_D08B
        LDA M_Y
        CMP BOMBMAN_Y
        BNE locret_D08B
        LDA #5
        STA APU_SOUND   ; Play the sound
        LDA #1
        STA DYING
        LDA #12
        STA BOMBMAN_FRAME

locret_D08B:                
        RTS
; ---------------------------------------------------------------------------

loc_D08C:               
        TXA
        PHA
        LDA #0
        STA SPR_ATTR
        LDY #0
        STY byte_50
        LDA M_X
        ASL
        ASL
        ASL
        ASL
        ROL byte_50
        CLC
        ADC M_U
        STA byte_4F
        LDA byte_50
        ADC #0
        STA byte_50
        LDA byte_4F
        SEC
        SBC #8
        STA byte_4F
        LDA byte_50
        SBC #0
        STA byte_50
        LDA byte_4F
        SEC
        SBC H_SCROLL
        STA byte_4F
        LDA byte_50
        SBC #0
        BNE loc_D0F7
        LDA byte_4F
        CMP #$F8
        BCS loc_D0F7
        STA SPR_X
        LDA M_Y
        ASL
        ASL
        ASL
        ASL
        CLC
        ADC M_V
        ADC #$1B
        STA SPR_Y
        LDA byte_4B
        CLC
        ADC M_FACE
        CMP #$10
        BCC loc_D0E3
        LDA #$10

loc_D0E3:               
        STA TEMP_X
        ASL
        CLC
        ADC TEMP_X
        TAX
        LDY byte_6B
        JSR sub_D0FA
        JSR sub_D0FA
        JSR sub_D0FA
        STY byte_6B

loc_D0F7:               
        PLA
        TAX
        RTS


; =============== S U B R O U T I N E =======================================


sub_D0FA:               
        LDA loc_D121,X
        BEQ loc_D11C
        PHA
        LDA SPR_Y
        STA SPR_TAB,Y
        INY
        PLA
        STA SPR_TAB,Y
        INY
        LDA #1
        STA SPR_TAB,Y
        INY
        LDA SPR_X
        STA SPR_TAB,Y
        INY
        CLC
        ADC #8
        STA SPR_X

loc_D11C:               
        INX
        INY
        DEY
        BNE locret_D123

loc_D121:               
        LDY #$FC

locret_D123:                
        RTS

; ---------------------------------------------------------------------------
        .DB $EC,$46,  0
        .DB $ED,$46,  0
        .DB $EE,$46,  0
        .DB $EF,$46,  0
        .DB $FC,$46,  0
        .DB $FD,$46,  0
        .DB $FE,$46,  0
        .DB $FF,$46,  0
        .DB $EC,$46,$46
        .DB $ED,$46,$46
        .DB $EE,$46,$46
        .DB $EF,$46,$46
        .DB $FC,$46,$46
        .DB $FD,$46,$46
        .DB $FE,$46,$46
        .DB $FF,$46,$46
MONSTER_TILE:   .DB $18,$19,$1A,$19,$1C,$1D,$1E,$1D,$20,$21,$22,$21,$24,$25,$26,$25
        .DB $28,$29,$2A,$29,$2C,$2D,$2E,$2D,$30,$31,$32,$31,$34,$35,$36,$35
        .DB $1B,$1F,$23,$27,$2B,$2F,$33,$37,$14,$15,$16,$17,$38,$39,$3A,$3B
        .DB $3C,$3D
MONSTER_ATTR:   .DB   1,  1,  1,  1,  3,  3,  3,  3,  2,  2,  2,  2,  1,  1,  1,  1
        .DB   3,  3,  3,  3,  2,  2,  2,  2,  1,  1,  1,  1,  1,  2,  1,  2
        .DB   1,  3,  2,  1,  3,  2,  1,  1,  1,  1,  1,  1,  1,  0,  1,  2
        .DB   3,  1,  1,  2,  4,  8, $A,$14,$28,$50,$64,$C8,  2,  4,  5, $A
        .DB $14,$28

; =============== S U B R O U T I N E =======================================

; Put the description of the current monster in temporary variables

ENEMY_SAVE:             
        STX M_ID
        LDA ENEMY_TYPE,X
        STA M_TYPE
        LDA ENEMY_X,X
        STA M_X
        LDA ENEMY_U,X
        STA M_U
        LDA ENEMY_Y,X
        STA M_Y
        LDA ENEMY_V,X
        STA M_V
        LDA ENEMY_FRAME,X
        STA M_FRAME
        LDA byte_5B2,X
        STA byte_47
        LDA byte_5BC,X
        STA byte_48
        LDA byte_5C6,X
        STA byte_49
        LDA ENEMY_FACE,X
        STA M_FACE
        LDA byte_5DA,X
        STA byte_4B
        LDA byte_5E4,X
        STA byte_4C
        RTS


; =============== S U B R O U T I N E =======================================

; Recover monster data from temporary variables

ENEMY_LOAD:             
        LDX M_ID
        LDA M_TYPE
        STA ENEMY_TYPE,X
        LDA M_X
        STA ENEMY_X,X
        LDA M_U
        STA ENEMY_U,X
        LDA M_Y
        STA ENEMY_Y,X
        LDA M_V
        STA ENEMY_V,X
        LDA M_FRAME
        STA ENEMY_FRAME,X
        LDA byte_47
        STA byte_5B2,X
        LDA byte_48
        STA byte_5BC,X
        LDA byte_49
        STA byte_5C6,X
        LDA M_FACE
        STA ENEMY_FACE,X
        LDA byte_4B
        STA byte_5DA,X
        LDA byte_4C

loc_D242:
        STA byte_5E4,X
        RTS

; ---------------------------------------------------------------------------
THINK_PROC:
        .DW $D320     ; Pink bulb
        .DW $D2E7     ; Blue Pepper
        .DW $D2C8     ; Barrel
        .DW $D305     ; Kolobok
        .DW $D2B4     ; Cloud
        .DW $D319     ; Medusa
        .DW $D3A0     ; Boar
        .DW $D38A     ; Coin
        .DW $D2A2
        .DW $D264
        .DW $D25B
; ---------------------------------------------------------------------------
        DEC byte_49
        BNE locret_D2A2
        LDA #0
        STA M_TYPE
        RTS
; ---------------------------------------------------------------------------
        DEC byte_49
        BNE locret_D2A2
        LDA #10
        STA byte_49
        INC M_FRAME
        LDA M_FRAME
        CMP #44
        BNE locret_D2A2
        LDA byte_4B
        CLC
        ADC M_FACE
        TAY
        CPY #$B
        BCC loc_D294
        CPY #$10
        BCC loc_D285
        LDY #$10

loc_D285:               
        LDA $D1B7,Y
        TAX

loc_D289:               
        LDA #$C8 ; 'L'
        JSR sub_DD83
        DEX
        BNE loc_D289
        JMP loc_D29A
; ---------------------------------------------------------------------------

loc_D294:               
        LDA $D1B7,Y
        JSR sub_DD83

loc_D29A:               
        LDA #$B
        STA M_TYPE
        LDA #$64 ; 'd'
        STA byte_49

locret_D2A2:                
        RTS
; ---------------------------------------------------------------------------
        DEC byte_49
        BNE locret_D2B3
        LDA #10
        STA M_TYPE
        LDA #40
        STA M_FRAME
        LDA #20
        STA byte_49

locret_D2B3:                
        RTS
; ---------------------------------------------------------------------------

locret_D2B4:                
        RTS
; ---------------------------------------------------------------------------
        LDA #$10        ; The fifth monster is a cloud
        LDY #$13
        JSR sub_D5DA
        JSR sub_D37E
        LDA FRAME_CNT
        AND #3
        BNE locret_D2B4
        JMP loc_D310
; ---------------------------------------------------------------------------

locret_D2C8:                
        RTS
; ---------------------------------------------------------------------------
        LDA #8      ; The Third Monster - The Barrel
        LDY #$B
        JSR sub_D5DA
        JSR sub_D37E
        LDA FRAME_CNT
        AND #3
        BEQ locret_D2C8
        DEC byte_4C
        LDA byte_4C
        CMP #$96
        BCS loc_D2E4
        JSR TURN_HORIZONTALLY

loc_D2E4:               
        JMP loc_D33F
; ---------------------------------------------------------------------------

locret_D2E7:                
        RTS
; ---------------------------------------------------------------------------
        LDA #4      ; The second monster is a blue pepper
        LDY #7
        JSR sub_D5DA
        JSR sub_D37E
        LDA FRAME_CNT
        AND #3
        BEQ locret_D2E7
        DEC byte_4C
        LDA byte_4C
        CMP #$96 ; 'Ц'
        BCS loc_D303
        JSR TURN_VERTICALLY

loc_D303:               
        JMP loc_D33F
; ---------------------------------------------------------------------------
        LDA #$C     ; The fourth monster is Kolobok.
        LDY #$F
        JSR sub_D5DA
        JSR sub_D37E

loc_D310:               
        DEC byte_4C
        LDA byte_4C
        CMP #$C8 ; 'L'
        JMP loc_D337
; ---------------------------------------------------------------------------

THINK_SKIP:             
        RTS
; ---------------------------------------------------------------------------
        LDA #20     ; The sixth monster is Medusa
        LDY #23
        JMP loc_D325
; ---------------------------------------------------------------------------
        LDA #0      ; The first monster is a pink bulb
        LDY #3

loc_D325:               
        JSR sub_D5DA
        JSR sub_D37E
        LDA FRAME_CNT
        AND #1
        BEQ THINK_SKIP
        DEC byte_4C
        LDA byte_4C
        CMP #20

loc_D337:               
        BCS loc_D33F
        JSR TURN_VERTICALLY
        JSR TURN_HORIZONTALLY

loc_D33F:               
        LDA byte_49
        BEQ loc_D365
        DEC byte_49
        LDA M_FACE
        JSR STEP_MONSTER    ; Make a monster step (in the A register - the direction of the look)
        BEQ locret_D364
        CMP #3
        BCC loc_D360
        LDY M_FACE
        LDA byte_D412,Y
        STA M_FACE
        LDA #0
        STA byte_4C
        LDA #$60 ; '`'
        STA byte_49
        RTS
; ---------------------------------------------------------------------------

loc_D360:               
        LDA #0
        STA byte_49

locret_D364:                
        RTS
; ---------------------------------------------------------------------------

loc_D365:               
        JSR RAND
        PHA
        AND #$18
        ASL
        ASL
        CLC
        ADC #$20 ; ' '
        STA byte_49
        PLA
        ROL
        ROL
        ROL
        AND #3
        CLC
        ADC #1
        STA M_FACE
        RTS

; =============== S U B R O U T I N E =======================================


sub_D37E:               
        LDY #0
        LDA M_FACE
        CMP #3
        BCC loc_D388
        LDY #$40 ; '@'

loc_D388:               
        STY byte_48
        RTS

; ---------------------------------------------------------------------------
        LDA #$1C        ; The eighth monster is a coin
        LDY #$1F
        JSR sub_D5DA
        LDY #0
        LDA M_FRAME
        CMP #$1D
        BNE loc_D39C
        LDY #$40 ; '@'

loc_D39C:               
        STY byte_48
        JMP loc_D3AB
; ---------------------------------------------------------------------------
        LDA #$18        ; The seventh monster is a boar
        LDY #$1B
        JSR sub_D5DA
        JSR sub_D37E

loc_D3AB:               
        LDA byte_4C
        BEQ loc_D3B4
        DEC byte_4C
        BNE loc_D3BA
        RTS
; ---------------------------------------------------------------------------

loc_D3B4:               
        JSR TURN_VERTICALLY
        JSR TURN_HORIZONTALLY

loc_D3BA:               
        LDA M_FACE
        ASL
        ORA byte_4B
        TAY
        LDA byte_D412+5,Y
        STA byte_53
        TAY
        LDA byte_D412+$F,Y
        STA byte_52
        JSR sub_D454
        AND byte_52
        BEQ loc_D3E0
        LDA byte_53
        STA M_FACE
        LDA #1
        EOR byte_4B
        STA byte_4B
        LDA #0
        STA byte_49

loc_D3E0:               
        INC byte_49
        LDA byte_49
        CMP #$1F
        BCC loc_D3EE
        LDA #1
        EOR byte_4B
        STA byte_4B

loc_D3EE:               
        LDA M_FACE
        JSR STEP_MONSTER    ; Make a monster step (in the A register - the direction of the look)
        BEQ locret_D405
        CMP #3
        BCS loc_D406
        INC M_FACE
        LDA M_FACE
        CMP #5
        BNE locret_D405
        LDA #1
        STA M_FACE

locret_D405:                
        RTS
; ---------------------------------------------------------------------------

loc_D406:               
        LDA #$60 ; '`'
        STA byte_4C
        LDY M_FACE
        LDA byte_D412,Y
        STA M_FACE
        RTS
; ---------------------------------------------------------------------------
byte_D412:  .DB   0,  3,  4,  1,  2,  1,  4,  4,  2,  1,  3,  2,  4
        .DB   3,  1,  0,  1,  2,  4,  8

; =============== S U B R O U T I N E =======================================


TURN_HORIZONTALLY:          
        LDA DYING
        BNE NO_VTURN
        LDA M_Y
        CMP BOMBMAN_Y
        BNE NO_VTURN    ; If BY != MY, then exit
        LDA M_X
        CMP BOMBMAN_X
        LDA #1
        BCC FACE_RIGHT  ; If BX > MX, then turn right, otherwise turn left.
        LDA #3

FACE_RIGHT:             
        STA M_FACE

NO_VTURN:               
        RTS


; =============== S U B R O U T I N E =======================================


TURN_VERTICALLY:            
        LDA DYING
        BNE NO_VTURN
        LDA M_X
        CMP BOMBMAN_X
        BNE NO_HTURN    ; If BX != MX, then exit
        LDA M_Y
        CMP BOMBMAN_Y
        LDA #4
        BCC FACE_DOWN   ; If BY > MY, turn down, otherwise turn up.
        LDA #2

FACE_DOWN:              
        STA M_FACE

NO_HTURN:               
        RTS


; =============== S U B R O U T I N E =======================================


sub_D454:               
        LDA #0
        STA byte_51
        LDA M_U
        CMP #8
        BNE loc_D462
        LDA M_V
        CMP #8

loc_D462:               
        BNE loc_D4BD
        LDY M_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        INY
        JSR ENEMY_COLLISION
        BNE loc_D47C
        LDA #1
        STA byte_51

loc_D47C:               
        DEY
        DEY
        JSR ENEMY_COLLISION
        BNE loc_D489
        LDA #4
        ORA byte_51
        STA byte_51

loc_D489:               
        LDY M_Y
        DEY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        JSR ENEMY_COLLISION
        BNE loc_D4A3
        LDA #2
        ORA byte_51
        STA byte_51

loc_D4A3:               
        LDY M_Y
        INY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        JSR ENEMY_COLLISION
        BNE loc_D4BD
        LDA #8
        ORA byte_51
        STA byte_51

loc_D4BD:               
        LDA byte_51

locret_D4BF:                
        RTS

; =============== S U B R O U T I N E =======================================


ENEMY_COLLISION:            
        LDA (STAGE_MAP),Y
        BEQ locret_D4BF
        CMP #8
        BEQ locret_D4BF
        CMP #6
        BEQ locret_D4BF
        CMP #2
        BEQ BRICK_WALL
        RTS
; ---------------------------------------------------------------------------

BRICK_WALL:             
        LDA M_TYPE
        CMP #5      ; A cloud, a jellyfish and a coin can pass through brick walls
        BEQ locret_D4BF
        CMP #6
        BEQ locret_D4BF
        CMP #8
        RTS


; =============== S U B R O U T I N E =======================================

; Make a monster step (in the A register - the direction of the look)

STEP_MONSTER:               
        LDX #0
        STX byte_4E
        TAX
        CMP #1
        BNE CASE_NOT_RIGHT
        JSR STEP_ENEMY_RIGHT

CASE_NOT_RIGHT:             
        TXA
        CMP #3
        BNE CASE_NOT_LEFT
        JSR STEP_ENEMY_LEFT

CASE_NOT_LEFT:              
        TXA
        CMP #2
        BNE CASE_NOT_UP
        JSR STEP_ENEMY_UP

CASE_NOT_UP:                
        TXA
        CMP #4
        BNE CASE_NOT_DOWN
        JSR STEP_ENEMY_DOWN

CASE_NOT_DOWN:              
        LDA byte_4E
        RTS


; =============== S U B R O U T I N E =======================================


STEP_ENEMY_DOWN:            
        LDA M_V
        CMP #8
        BCS loc_D50E
        INC M_V
        RTS
; ---------------------------------------------------------------------------

loc_D50E:               
        LDY M_Y
        INY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        JSR ENEMY_COLLISION
        BNE loc_D534
        JSR sub_D5BC
        INC M_V
        LDA M_V
        CMP #16
        BNE locret_D533
        LDA #0
        STA M_V
        INC M_Y

locret_D533:                
        RTS
; ---------------------------------------------------------------------------

loc_D534:               
        STA byte_4E
        RTS


; =============== S U B R O U T I N E =======================================


STEP_ENEMY_UP:              
        LDA M_V
        CMP #9
        BCC loc_D540
        DEC M_V
        RTS
; ---------------------------------------------------------------------------

loc_D540:               
        LDY M_Y
        DEY
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        JSR ENEMY_COLLISION
        BNE loc_D534
        JSR sub_D5BC
        DEC M_V
        BPL locret_D561
        LDA #$F
        STA M_V
        DEC M_Y

locret_D561:                
        RTS


; =============== S U B R O U T I N E =======================================


STEP_ENEMY_LEFT:            
        LDA M_U
        CMP #9
        BCC loc_D56B
        DEC M_U
        RTS
; ---------------------------------------------------------------------------

loc_D56B:               
        LDY M_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        DEY
        JSR ENEMY_COLLISION
        BNE loc_D534
        JSR sub_D5CB
        DEC M_U
        BPL locret_D58C
        LDA #$F
        STA M_U
        DEC M_X

locret_D58C:                
        RTS


; =============== S U B R O U T I N E =======================================


STEP_ENEMY_RIGHT:           
        LDA M_U
        CMP #8
        BCS loc_D596
        INC M_U
        RTS
; ---------------------------------------------------------------------------

loc_D596:               
        LDY M_Y
        LDA MULT_TABY,Y
        STA STAGE_MAP
        LDA MULT_TABX,Y
        STA STAGE_MAP+1
        LDY M_X
        INY
        JSR ENEMY_COLLISION
        BNE loc_D534
        JSR sub_D5CB
        INC M_U
        LDA M_U
        CMP #16
        BNE locret_D5BB
        LDA #0
        STA M_U
        INC M_X

locret_D5BB:                
        RTS


; =============== S U B R O U T I N E =======================================


sub_D5BC:               
        LDA M_U
        CMP #8
        BCC loc_D5C7
        BEQ locret_D5CA
        DEC M_U
        RTS
; ---------------------------------------------------------------------------

loc_D5C7:               
        INC M_U
        RTS
; ---------------------------------------------------------------------------

locret_D5CA:                
        RTS


; =============== S U B R O U T I N E =======================================


sub_D5CB:               
        LDA M_V
        CMP #8
        BCC loc_D5D6
        BEQ locret_D5D9
        DEC M_V
        RTS
; ---------------------------------------------------------------------------

loc_D5D6:               
        INC M_V
        RTS
; ---------------------------------------------------------------------------

locret_D5D9:                
        RTS


; =============== S U B R O U T I N E =======================================


sub_D5DA:               
        PHA
        LDA FRAME_CNT
        AND #7
        BNE loc_D5F0
        PLA
        INC M_FRAME
        CMP M_FRAME
        BCC loc_D5EB

loc_D5E8:               
        STA M_FRAME
        RTS
; ---------------------------------------------------------------------------

loc_D5EB:               
        CPY M_FRAME
        BCC loc_D5E8
        RTS
; ---------------------------------------------------------------------------

loc_D5F0:               
        PLA
        RTS


; =============== S U B R O U T I N E =======================================

; Update the sprite (the A register is the sequential number of the 16x16 sprite image)

SPR_DRAW:               
        STX SPR_SAVEDX
        STY SPR_SAVEDY
        ASL
        PHA
        AND #$E
        STA SPR_ID
        PLA
        ASL
        AND #$E0
        ORA SPR_ID
        STA SPR_ID
        LDA SPR_TAB_INDEX
        INC SPR_TAB_INDEX
        CLC
        ADC SPR_TAB_TOGGLE
        CMP #12
        BCC INDEX_UNBOUND
        SBC #10

INDEX_UNBOUND:              
        ASL
        ASL
        ASL
        ASL
        TAY
        LDA SPR_ATTR
        BNE loc_D622
        JSR SPR_WRITE_OBJ_HALF ; Writes one half (8x16) of a sprite image to the sprite table.
        INC SPR_ID
        JMP loc_D629
; ---------------------------------------------------------------------------

loc_D622:               
        INC SPR_ID
        JSR SPR_WRITE_OBJ_HALF ; Writes one half (8x16) of a sprite image to the sprite table.
        DEC SPR_ID

loc_D629:               
        JSR SPR_WRITE_OBJ_HALF ; Writes one half (8x16) of a sprite image to the sprite table.
        LDX SPR_SAVEDX
        LDY SPR_SAVEDY
        RTS


; =============== S U B R O U T I N E =======================================

; Writes one half (8x16) of a sprite image to the sprite table.

SPR_WRITE_OBJ_HALF:         
        LDA SPR_Y
        STA SPR_TAB,Y   ; The Y register contains the offset in the sprite table (corrected automatically).
        LDA SPR_ID
        PHA
        STA SPR_TAB+1,Y
        LDA SPR_COL
        ORA SPR_ATTR
        STA SPR_TAB+2,Y
        LDA SPR_X
        STA SPR_TAB+3,Y
        LDA SPR_Y
        CLC
        ADC #8
        STA SPR_TAB+4,Y
        PLA
        CLC
        ADC #16
        STA SPR_TAB+5,Y
        LDA SPR_COL
        ORA SPR_ATTR
        STA SPR_TAB+6,Y
        LDA SPR_X
        STA SPR_TAB+7,Y
        TYA
        CLC
        ADC #8
        TAY
        LDA SPR_X
        CLC
        ADC #8
        STA SPR_X
        RTS


; =============== S U B R O U T I N E =======================================


RAND:                   
        LDA SEED
        ROL
        ROL
        EOR #$41
        ROL
        ROL
        EOR #$93
        ADC SEED+1
        STA SEED
        ROL
        ROL
        EOR #$12
        ROL
        ROL
        ADC SEED+2
        STA SEED+1
        ADC SEED
        INC SEED+2
        BNE RAND2
        PHA
        LDA SEED+3
        CLC
        ADC #$1D
        STA SEED+3
        PLA

RAND2:                  
        EOR SEED+3
        RTS


; =============== S U B R O U T I N E =======================================


SPAWN_MONSTERS:             
        LDA STAGE
        CMP #$1A
        BCC loc_D6A8
        SBC #$19
        LDX #2
        LDY #$D8 ; '+'
        BNE loc_D6AC

loc_D6A8:               
        LDX #(MONSTER_TAB & $FF)
        LDY #(MONSTER_TAB >> 8)

loc_D6AC:               
        STX MTAB_PTR
        STY MTAB_PTR+1
        SEC
        SBC #1
        ASL
        STA TEMP_X
        ASL
        ASL
        CLC
        ADC TEMP_X
        TAY
        LDX #9

loc_D6BE:               
        LDA (MTAB_PTR),Y
        STA ENEMY_TYPE,X
        BEQ loc_D703
        SEC
        SBC #1
        ASL
        ASL
        STA ENEMY_FRAME,X
        LDA #8      ; Place the monster in the center of the cell (8; 8)
        STA ENEMY_U,X
        STA ENEMY_V,X
        JSR RAND
        AND #3
        CLC
        ADC #1
        STA ENEMY_FACE,X
        STY byte_5A

loc_D6E2:               
        JSR RAND_COORDS
        LDA TEMP_X
        CMP #5
        BCC loc_D6E2
        STA ENEMY_X,X
        LDA TEMP_Y
        STA ENEMY_Y,X
        LDA #0
        STA byte_5B2,X
        STA byte_5DA,X
        STA byte_5C6,X
        STA byte_5E4,X
        LDY byte_5A

loc_D703:               
        INY
        DEX
        BPL loc_D6BE
        RTS

; ---------------------------------------------------------------------------

; Monster population table for each of the 50 levels.
; The map can be a maximum of 10 monsters.

MONSTER_TAB
    .DB    1, 1, 1, 1, 1, 1, 0, 0, 0, 0
    .DB    1, 1, 1, 2, 2, 2, 0, 0, 0, 0 
    .DB    1, 1, 2, 2, 3, 3, 0, 0, 0, 0 
    .DB    1, 2, 3, 3, 4, 4, 0, 0, 0, 0 
    .DB    2, 2, 2, 2, 3, 3, 3, 0, 0, 0 
    .DB    2, 2, 3, 3, 3, 4, 4, 0, 0, 0 
    .DB    2, 2, 3, 3, 3, 5, 5, 0, 0, 0 
    .DB    2, 3, 3, 4, 4, 4, 4, 0, 0, 0 
    .DB    2, 3, 4, 4, 4, 4, 6, 0, 0, 0 
    .DB    2, 3, 4, 5, 6, 6, 6, 0, 0, 0 
    .DB    2, 3, 3, 4, 4, 4, 5, 6, 0, 0 
    .DB    2, 3, 4, 5, 6, 6, 6, 6, 0, 0 
    .DB    3, 3, 3, 4, 4, 4, 6, 6, 0, 0 
    .DB    5, 5, 5, 5, 5, 5, 5, 7, 0, 0 
    .DB    3, 4, 4, 4, 6, 6, 6, 7, 0, 0 
    .DB    4, 4, 4, 6, 6, 6, 6, 7, 0, 0 
    .DB    3, 3, 3, 3, 3, 6, 6, 7, 0, 0 
    .DB    1, 1, 1, 2, 2, 2, 7, 7, 0, 0 
    .DB    1, 2, 3, 3, 3, 5, 7, 7, 0, 0 
    .DB    2, 3, 4, 5, 6, 6, 7, 7, 0, 0 
    .DB    5, 5, 5, 6, 6, 6, 6, 7, 7, 0 
    .DB    3, 3, 3, 3, 4, 4, 4, 6, 7, 0 
    .DB    3, 3, 4, 4, 5, 5, 6, 6, 7, 0 
    .DB    3, 4, 5, 6, 6, 5, 6, 6, 7, 0 
    .DB    2, 2, 3, 4, 5, 5, 6, 6, 7, 0 
    .DB    1, 2, 3, 4, 5, 5, 6, 6, 7, 0 
    .DB    1, 2, 6, 6, 6, 5, 6, 6, 7, 0 
    .DB    2, 3, 3, 3, 4, 4, 4, 6, 7, 0 
    .DB    5, 5, 5, 5, 5, 6, 7, 6, 7, 0 
    .DB    3, 3, 3, 4, 4, 5, 5, 6, 7, 0 
    .DB    2, 2, 3, 3, 4, 4, 5, 5, 6, 6 
    .DB    2, 3, 4, 4, 4, 6, 6, 6, 6, 7 
    .DB    3, 3, 4, 4, 5, 6, 6, 7, 6, 7 
    .DB    3, 3, 4, 4, 4, 6, 6, 7, 6, 7 
    .DB    3, 3, 4, 5, 0, 6, 6, 7, 6, 7
    .DB    3, 3, 4, 4, 6, 6, 7, 6, 7, 7 
    .DB    3, 3, 4, 5, 6, 6, 7, 6, 7, 7
    .DB    3, 3, 4, 4, 6, 6, 7, 6, 7, 7 
    .DB    3, 4, 5, 5, 6, 7, 6, 7, 7, 7 
    .DB    3, 4, 4, 6, 6, 7, 6, 7, 7, 7 
    .DB    3, 4, 5, 6, 6, 6, 7, 7, 7, 7 
    .DB    4, 5, 6, 6, 7, 6, 7, 7, 7, 7 
    .DB    4, 5, 6, 7, 6, 7, 7, 7, 7, 7 
    .DB    4, 5, 6, 7, 6, 7, 7, 7, 7, 7 
    .DB    5, 6, 5, 6, 7, 7, 7, 7, 7, 7 
    .DB    5, 6, 5, 6, 7, 7, 7, 7, 7, 7 
    .DB    6, 5, 5, 6, 7, 7, 7, 7, 7, 7 
    .DB    6, 5, 6, 7, 7, 7, 7, 7, 7, 8 
    .DB    5, 5, 6, 7, 7, 7, 7, 7, 7, 8 
    .DB    5, 5, 6, 7, 7, 7, 7, 7, 8, 8 

; =============== S U B R O U T I N E =======================================

; Add a new tile to TILE_TAB

DRAW_TILE:              
        STX TEMP_X
        STY TEMP_Y
        PHA

loc_D901:               
        LDA TILE_CUR
        SEC
        SBC TILE_PTR
        CMP #8
        BEQ loc_D901
        PLA
        JSR sub_D924
        LDY TILE_PTR
        LDX #0

COPY_TILE:              
        LDA $17,X
        STA TILE_TAB,Y
        INY
        INX
        CPX #8
        BNE COPY_TILE
        STY TILE_PTR
        LDX TEMP_X
        LDY TEMP_Y
        RTS

; =============== S U B R O U T I N E =======================================


sub_D924:               
        TAY
        ASL
        ASL
        STA byte_1A
        LDA unk_D994,Y
        STA byte_1E
        LDY #0
        LDA byte_1F
        CMP #16
        BCC loc_D93A
        LDY #4
        SBC #16

loc_D93A:               
        STY byte_17
        ASL
        STA byte_21
        LDA byte_20
        CLC
        ADC #2
        ASL
        STA byte_22
        AND #$FC
        ASL
        STA byte_1B
        LDA byte_21
        LSR
        LSR
        CLC
        ADC byte_1B
        CLC
        ADC #$C0 ; 'L'
        STA byte_1B
        LDA #$23 ; '#'
        STA byte_1C
        LDA #2
        AND byte_22
        STA byte_23
        LDA byte_21
        AND #3
        LSR
        CLC
        ADC byte_23
        ASL
        PHA
        LDA #$FC
        STA byte_1D
        PLA
        TAX
        BEQ loc_D97C

loc_D974:               
        ASL byte_1E
        SEC
        ROL byte_1D
        DEX
        BNE loc_D974

loc_D97C:               
        LDA #1
        STA byte_19
        LDA byte_22
        LDX #5

loc_D984:               
        ASL
        ROL byte_19
        DEX
        BNE loc_D984
        CLC
        ADC byte_21
        STA byte_18
        BCC locret_D993
        INC byte_19

locret_D993:                
        RTS

; ---------------------------------------------------------------------------
unk_D994:   .DB   0       
        .DB   0
        .DB   0
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   0
        .DB   0
        .DB   0
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   1
        .DB   3
        .DB   2
        .DB   2
        .DB   2
        .DB   2
        .DB   2
        .DB   2
        .DB   2
        .DB   2
        .DB   3
TILE_MAP:   .DB $5F,$5F,$5F,$5F   
        .DB $64,$65,$66,$67
        .DB $68,$69,$6A,$6B
        .DB $6C,$6D,$6E,$6F
        .DB $70,$71,$72,$73
        .DB $74,$75,$76,$77
        .DB $78,$79,$7A,$7B
        .DB $7C,$7D,$7E,$7F
        .DB $80,$81,$82,$83
        .DB $84,$85,$86,$87
        .DB $88,$89,$8A,$8B
        .DB $8C,$8D,$8E,$8F
        .DB $90,$91,$92,$93
        .DB $94,$95,$96,$97
        .DB $98,$99,$9A,$9B
        .DB $20,$20,$21,$21
        .DB $22,$23,$22,$23
        .DB $24,$24,$25,$25
        .DB $26,$27,$26,$27
        .DB $28,$28,$29,$29
        .DB $2A,$2B,$2A,$2B
        .DB $2C,$2C,$2D,$2D
        .DB $2E,$2F,$2E,$2F
        .DB $20,$9D,$21,$9F
        .DB $9C,$9D,$22,$23
        .DB $9C,$20,$9E,$21
        .DB $22,$23,$9E,$9F
        .DB $24,$A1,$25,$A3
        .DB $A0,$A1,$26,$27
        .DB $A0,$24,$A2,$25
        .DB $26,$27,$A2,$A3
        .DB $28,$A5,$29,$A7
        .DB $A4,$A5,$2A,$2B
        .DB $A4,$28,$A6,$29
        .DB $2A,$2B,$A6,$A7
        .DB $2C,$A9,$2D,$AB
        .DB $A8,$A9,$2E,$2F
        .DB $A8,$2C,$AA,$2D
        .DB $2E,$2F,$AA,$AB
        .DB $68,$69,$6A,$6B
        .DB $3C,$3D,$3E,$3F
        .DB   0,  1,$10,$11
        .DB   2,  3,$12,$13
        .DB   4,  5,$14,$15
        .DB   6,  7,$16,$17
        .DB   8,  9,$18,$19
        .DB  $A, $B,$1A,$1B
        .DB  $C, $D,$1C,$1D
        .DB  $E, $F,$1E,$1F
        .DB $68,$69,$6A,$6B

; =============== S U B R O U T I N E =======================================


sub_DA8E:               
        JSR PPUD
        JSR VBLD
        JSR SETSTAGEPAL
        LDA #0
        STA STAGE_STARTED
        STA INMENU
        STA APU_MUSIC
        LDY #$9F
        LDA #$20
        LDX #$E7
        JSR sub_DC41
        JSR PPUE
        LDA #6
        STA byte_1F
        LDA #$3A ; ':'
        STA byte_20
        LDY #0

loc_DAB5:               
        JSR WAITVBL
        LDA #$22 ; '"'
        LDX byte_1F
        JSR VRAMADDR
        LDA byte_20
        STA PPU_DATA
        JSR PPU_RESTORE
        LDX #10

loc_DAC9:               
        JSR WAITVBL
        LDA JOYPAD1
        AND #$8F
        BNE loc_DAF8
        DEX
        BNE loc_DAC9
        JSR WAITVBL
        LDA #$22 ; '"'
        LDX byte_1F
        JSR VRAMADDR
        LDA #$3B ; ';'
        STA PPU_DATA
        JSR PPU_RESTORE
        LDX #10

loc_DAE9:               
        JSR WAITVBL
        LDA JOYPAD1
        AND #$8F
        BNE loc_DAF8
        DEX
        BNE loc_DAE9
        JMP loc_DAB5
; ---------------------------------------------------------------------------

loc_DAF8:               
        BMI loc_DB43
        PHA
        LDA #$12
        STA APU_SQUARE1_REG+3
        PLA
        CMP #1
        BEQ loc_DB24
        LDA byte_20
        CMP #$3A ; ':'
        BNE loc_DB0F
        LDA #$51 ; 'Q'
        STA byte_20

loc_DB0F:               
        LDA byte_20
        CMP #$41 ; 'A'
        BEQ loc_DB1A
        DEC byte_20
        JMP loc_DB1E
; ---------------------------------------------------------------------------

loc_DB1A:               
        LDA #$50 ; 'P'
        STA byte_20

loc_DB1E:               
        JSR WAITUNPRESS ; Wait for the button to release
        JMP loc_DAB5
; ---------------------------------------------------------------------------

loc_DB24:               
        LDA byte_20
        CMP #$3A ; ':'
        BNE loc_DB2E
        LDA #$40 ; '@'
        STA byte_20

loc_DB2E:               
        LDA byte_20
        CMP #$50 ; 'P'
        BEQ loc_DB39
        INC byte_20
        JMP loc_DB3D
; ---------------------------------------------------------------------------

loc_DB39:               
        LDA #$41 ; 'A'
        STA byte_20

loc_DB3D:               
        JSR WAITUNPRESS ; Wait for the button to release

loc_DB40:               
        JMP loc_DAB5
; ---------------------------------------------------------------------------

loc_DB43:               
        LDA #$11
        STA APU_SQUARE1_REG+3
        LDA byte_20
        CMP #$3A ; ':'
        BEQ loc_DB40
        AND #$F
        TAX
        LDA byte_DFA0,X
        STA $7F,Y
        JSR WAITVBL
        LDA #$22 ; '"'
        LDX byte_1F
        JSR VRAMADDR
        LDA byte_20
        STA PPU_DATA
        JSR PPU_RESTORE
        LDA #$3A ; ':'
        STA byte_20
        INC byte_1F
        INY
        CPY #$14
        BEQ loc_DB7A
        JSR WAITUNPRESS ; Wait for the button to release
        JMP loc_DAB5
; ---------------------------------------------------------------------------

loc_DB7A:               
        LDX #0
        STX SEED

loc_DB7E:               
        LDA PW_BUFF,X
        PHA
        CLC
        ADC #7
        CLC
        ADC SEED
        AND #$F
        STA PW_BUFF,X
        PLA
        STA SEED
        INX
        CPX #$14
        BNE loc_DB7E
        LDX #0

loc_DB95:               
        LDY #4
        LDA #0

loc_DB99:               
        CLC
        ADC PW_BUFF,X
        INX
        DEY
        BNE loc_DB99
        AND #$F
        CMP PW_BUFF,X
        BNE loc_DBCC
        INX
        CPX #$F
        BNE loc_DB95
        LDA PW_BUFF+4
        ASL
        STA byte_1F
        LDA PW_BUFF+9
        ASL
        CLC
        ADC byte_1F
        STA byte_1F
        LDA PW_BUFF+14
        ASL
        CLC
        ADC byte_1F
        LDX #4

loc_DBC0:               
        CLC
        ADC PW_BUFF+14,X
        DEX
        BNE loc_DBC0
        AND #$F
        CMP PW_BUFF+19
        BEQ loc_DBCF

loc_DBCC:               
        JMP sub_DA8E
; ---------------------------------------------------------------------------

loc_DBCF:               
        LDX #0
        LDY #0

loc_DBD3:               
        JSR _get_pass_data_var_addr
        LDA PW_BUFF,Y
        STY TEMP_Y
        LDY #0
        STA (STAGE_MAP),Y
        LDY TEMP_Y
        INY
        CPY #$14
        BNE loc_DBD3
        LDA BOMB_PWR
        ASL
        ASL
        ASL
        ASL
        STA BONUS_POWER
        LDA STAGE_HI
        ASL
        ASL
        ASL
        ASL
        ORA STAGE_LO
        STA STAGE
        RTS


; =============== S U B R O U T I N E =======================================


sub_DBF9:               
        JSR PPUD
        JSR VBLD
        JSR SETSTAGEPAL
        LDA #6
        JSR sub_DD04
        LDY #0
        JSR loc_DC39
        JSR loc_DC39
        JSR loc_DC39
        JSR loc_DC39
        JSR loc_DC39
        JSR loc_DC39
        JSR loc_DC39
        LDA #$A
        STA byte_20
        LDA #0
        STA byte_1F

loc_DC26:               
        LDA #$31 ; '1'
        JSR sub_CB4E
        INC byte_1F
        LDA byte_1F
        CMP #$10
        BNE loc_DC26
        JSR VBLE
        JMP PPUE

; ---------------------------------------------------------------------------

loc_DC39:               
        LDA unk_DC53,Y
        INY
        LDX unk_DC53,Y
        INY

; =============== S U B R O U T I N E =======================================


sub_DC41:               
        JSR VRAMADDR

loc_DC44:               
        LDA unk_DC53,Y
        INY
        CMP #0
        BEQ locret_DC52
        STA PPU_DATA
        JMP loc_DC44
; ---------------------------------------------------------------------------

locret_DC52:                
        RTS

; ---------------------------------------------------------------------------
unk_DC53:   .DB $20       
        .DB $88
        .DB "CONGRATULATIONS"
        .DB   0
        .DB $20
        .DB $E4
        .DB "YOU:HAVE:SUCCEED"
        .DB "ED:IN"
        .DB   0
        .DB $21
        .DB $22
        .DB "HELPING:BOMBERMAN:TO:BECOME"
        .DB   0
        .DB $21
        .DB $62
        .DB "A:HUMAN:BEING"
        .DB   0
        .DB $21
        .DB $A4
        .DB "MAYBE:YOU:CAN:RE"
        .DB "COGNIZE:HIM"
        .DB   0
        .DB $21
        .DB $E2
        .DB "IN:ANOTHER:HUDSO"
        .DB "N:SOFT:GAME"
        .DB   0
        .DB $22
        .DB $4B
        .DB "GOOD:BYE"
        .DB   0
        .DB "ENTER:SECRET:CODE"
        .DB   0

; =============== S U B R O U T I N E =======================================


sub_DD04:               
        PHA
        JSR WAITVBL
        LDA #$3F ; '?'
        LDX #$1C
        JSR VRAMADDR
        PLA
        ASL
        ASL
        TAX
        LDY #4

loc_DD15:               
        LDA byte_DD22,X
        STA PPU_DATA
        INX
        DEY
        BNE loc_DD15
        JMP VRAMADDRZ

; ---------------------------------------------------------------------------
byte_DD22:  .DB  $F,  0,  0,  0, $F,  0,  0,  0, $F,  0,  0,  0, $F,  0,  0,  0
        .DB  $F,  0,  0,  0, $F,  0,  0,  0, $F,$15,$36,$21

; =============== S U B R O U T I N E =======================================


GAME_OVER_SCREEN:           
        JSR PPUD
        JSR VBLD
        JSR SETSTAGEPAL
        LDA #$21
        LDX #$EA
        JSR VRAMADDR
        LDX #8

loc_DD50:               
        LDA aRevoEmag,X ; "REVO:EMAG"
        STA PPU_DATA
        DEX
        BPL loc_DD50
        JSR sub_E2BD
        JSR VBLE
        JMP PPUE

; ---------------------------------------------------------------------------
aRevoEmag:  .DB "REVO:EMAG"       
; ---------------------------------------------------------------------------

loc_DD6B:               
        STX TEMP_X
        STY TEMP_Y
        LDX DEMOPLAY
        BNE loc_DDC2
        LDX #3
        BNE loc_DD8D

; =============== S U B R O U T I N E =======================================


sub_DD77:               
        STX TEMP_X
        STY TEMP_Y
        LDX DEMOPLAY
        BNE loc_DDC2
        LDX #4
        BNE loc_DD8D


; =============== S U B R O U T I N E =======================================


sub_DD83:               
        STX TEMP_X
        STY TEMP_Y
        LDX DEMOPLAY
        BNE loc_DDC2
        LDX #6

loc_DD8D:               
        LDY #0
        CLC
        ADC SCORE,X

loc_DD92:               
        STA SCORE,X
        LDA SCORE,X
        SEC
        SBC #$A
        BCC loc_DD9E
        INY
        BNE loc_DD92

loc_DD9E:               
        CPY #0
        BEQ loc_DDAA
        TYA
        DEX
        BPL loc_DD8D
        LDA #9
        STA SCORE

loc_DDAA:               
        LDX #0

loc_DDAC:               
        LDA SCORE,X
        CMP 1,X
        BCC loc_DDC2
        BNE loc_DDB9
        INX
        CPX #8
        BNE loc_DDAC

loc_DDB9:               
        LDX #6

loc_DDBB:               
        LDA SCORE,X
        STA 1,X
        DEX
        BPL loc_DDBB

loc_DDC2:               
        LDX TEMP_X
        LDY TEMP_Y
        RTS


; =============== S U B R O U T I N E =======================================

; Draw lines "TIME" and "LEFT XX"

TIME_AND_LIFE:              
        LDA #$20 ; ' '
        LDX #0
        JSR VRAMADDR
        LDX #$80
        LDA #$3A

loc_DDD2:               
        STA PPU_DATA
        DEX
        BNE loc_DDD2
        LDA #$20 ; ' '
        LDX #$41 ; 'A'
        JSR VRAMADDR
        LDX #3

loc_DDE1:               
        LDA aEmit,X     ; "EMIT"
        STA PPU_DATA
        DEX
        BPL loc_DDE1
        LDA #$3A ; ':'
        STA PPU_DATA
        LDA #$20 ; ' '
        LDX #$52 ; 'R'
        JSR VRAMADDR
        LDA #$30 ; '0'
        STA PPU_DATA
        STA PPU_DATA
        LDA #$20 ; ' '
        LDX #$58 ; 'X'
        JSR VRAMADDR
        LDX #3

loc_DE07:               
        LDA aTfel,X     ; "TFEL"
        STA PPU_DATA
        DEX
        BPL loc_DE07
        LDA LIFELEFT
        JMP PUTNUMBER   ; Print a two-digit number given in the A register.

; ---------------------------------------------------------------------------
aEmit:      .DB "EMIT"            
aTfel:      .DB "TFEL"            

; =============== S U B R O U T I N E =======================================


STAGE_SCREEN:               
        JSR PPUD
        JSR VBLD
        LDA #0
        STA H_SCROLL
        JSR SETSTAGEPAL
        LDA #$21 ; '!'
        LDX #$EA
        JSR VRAMADDR
        LDX #4

PUT_STAGE_STR:              
        LDA aEgats,X    ; "EGATS"
        STA PPU_DATA
        DEX
        BPL PUT_STAGE_STR
        LDA #$21 ; '!'
        LDX #$F0
        JSR VRAMADDR
        LDA STAGE
        JSR PUTNUMBER   ; Print a two-digit number given in the A register.
        JSR VBLE
        JMP PPUE

; ---------------------------------------------------------------------------
aEgats:     .DB "EGATS"           

; =============== S U B R O U T I N E =======================================


BONUS_STAGE_SCREEN:         
        JSR PPUD
        JSR VBLD
        LDA #0
        STA H_SCROLL
        JSR SETSTAGEPAL
        LDA #$21
        LDX #$EA
        JSR VRAMADDR
        LDX #$A

PUT_BONUS_MSG:              
        LDA aEgatsSunob,X   ; "EGATS:SUNOB"
        STA PPU_DATA
        DEX
        BPL PUT_BONUS_MSG
        JSR VBLE
        JMP PPUE

; ---------------------------------------------------------------------------
aEgatsSunob:    .DB "EGATS:SUNOB"     

; =============== S U B R O U T I N E =======================================


DRAWMENU:               
        JSR PPUD
        JSR CLS
        JSR WAITVBL
        LDA #$3F ; '?'
        LDX #0
        JSR VRAMADDR
        LDX #0

loc_DE95:               
        LDA MENUPAL,X
        STA PPU_DATA
        INX
        CPX #$10
        BNE loc_DE95
        JSR VRAMADDRZ
        JSR DRAWMENUTEXT    ; Draw text in the menu (copyright, license)
        LDA #$20 ; ' '
        LDX #0
        JSR VRAMADDR
        LDX #$40 ; '@'
        LDA #$B0 ; '-'

loc_DEB1:               
        STA PPU_DATA
        DEX
        BNE loc_DEB1
        LDX #0

loc_DEB9:               
        LDA MAINMENU_HI,X
        STA PPU_DATA
        INX
        BNE loc_DEB9

loc_DEC2:               
        LDA MAINMENU_LO,X
        STA PPU_DATA
        INX
        BNE loc_DEC2
        LDA #$22
        LDX #$AE
        JSR VRAMADDR
        LDX #0

loc_DED4:               
        LDA TOPSCORE,X
        BNE loc_DEE4
        LDA #$3A ; ':'
        STA PPU_DATA
        INX
        CPX #7
        BNE loc_DED4
        BEQ loc_DEF1

loc_DEE4:               
        LDA TOPSCORE,X
        CLC
        ADC #$30 ; '0'
        STA PPU_DATA
        INX
        CPX #7
        BNE loc_DEE4

loc_DEF1:               
        LDA #$30 ; '0'
        STA PPU_DATA
        STA PPU_DATA
        LDA #$23 ; '#'
        LDX #$C0 ; 'L'
        JSR VRAMADDR
        LDX #$20 ; ' '
        LDA #0

loc_DF04:               
        STA PPU_DATA
        DEX
        BNE loc_DF04
        LDX #8
        LDA #$50 ; 'P'

loc_DF0E:               
        STA PPU_DATA
        DEX
        BNE loc_DF0E
        LDX #$18
        LDA #$55 ; 'U'

loc_DF18:               
        STA PPU_DATA
        DEX
        BNE loc_DF18
        JSR PPU_RESTORE
        JSR VBLE
        JMP PPUE


; =============== S U B R O U T I N E =======================================


SETSTAGEPAL:                
        LDA #0
        STA H_SCROLL
        JSR WAITVBL
        LDA #$3F ; '?'
        LDX #0
        JSR VRAMADDR
        LDX #0

loc_DF37:               
        LDA STAGEPAL,X
        STA PPU_DATA
        INX
        CPX #$10
        BNE loc_DF37
        JSR VRAMADDRZ
        JMP CLS


; =============== S U B R O U T I N E =======================================


DRAW_TIME:              
        LDY #$30 ; '0'
        SEC

loc_DF4B:               
        SBC #100
        BCC loc_DF52
        INY
        BNE loc_DF4B

loc_DF52:               
        ADC #$64 ; 'd'
        CPY #$30 ; '0'
        BNE loc_DF76
        LDY #$3A ; ':'
        STY PPU_DATA


; =============== S U B R O U T I N E =======================================

; Output a two-digit number given in the A register.

PUTNUMBER:              
        LDY #$30 ; '0'
        SEC         ; $30 - Numbers from 0 to 9

DECADES:                
        SBC #10     ; Place the number of tens in Y
        BCC DONE_DECADES
        INY
        BNE DECADES     ; Place the number of tens in Y

DONE_DECADES:               
        ADC #$3A ; ':'
        CPY #$30 ; '0'      ; If the number is from 0 to 9, print a space instead of the number of tens
        BNE PUTNUMB2
        LDY #$3A ; ':'      ; $3A - Space.

PUTNUMB2:               
        STY PPU_DATA
        STA PPU_DATA
        RTS

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR DRAW_TIME

loc_DF76:               
        STY PPU_DATA
        LDY #$30 ; '0'
        SEC

loc_DF7C:               
        SBC #10
        BCC loc_DF83
        INY
        BNE loc_DF7C

loc_DF83:               
        ADC #$3A ; ':'
        STY PPU_DATA
        STA PPU_DATA
        RTS

; ---------------------------------------------------------------------------
STAGEPAL:   .DB  $F,  0, $F,$30   
MENUPAL:    .DB  $F,  5,$30,$28, $F,  0, $F,$30 
        .DB  $F,  6,$26,$37, $F, $F, $F, $F
byte_DFA0:  .DB   5,  0,  9,  4, $D,  7,  2,  6 
        .DB  $A, $F, $C,  3,  8, $B, $E,  1
MAINMENU_HI:    .DB $B0,$B0,$DF,$C0,$C1,$C1,$C2,$C0,$C1,$C1,$C1,$C2,$C0,$B6,$E9,$B8
        .DB $C2,$C0,$C1,$C1,$C2,$C0,$C1,$C1,$C2,$C0,$C1,$C1,$C2,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$C1,$D9,$D3,$B3,$C1,$D9,$CB,$D3,$B3,$C1,$C5,$C6,$C1
        .DB $B3,$C1,$D9,$D3,$B3,$C1,$D9,$CB,$CB,$C1,$D9,$D3,$B3,$EE,$F8,$B0
        .DB $B0,$B0,$DF,$C1,$D0,$D1,$D2,$C1,$CF,$E9,$C4,$B3,$C1,$D5,$D6,$D7
        .DB $B3,$C1,$D0,$D1,$D2,$C1,$D0,$DC,$E9,$C1,$D0,$D1,$D2,$EB,$F8,$B0
        .DB $B0,$B0,$DF,$C1,$E0,$E1,$E2,$C1,$CF,$E9,$C4,$B3,$C1,$B7,$E6,$E7
        .DB $B3,$C1,$E0,$E1,$E2,$C1,$E0,$F5,$EC,$C1,$E0,$E1,$E2,$EF,$F8,$B0
        .DB $B0,$B0,$DF,$C1,$E8,$DA,$B3,$C1,$CF,$E9,$C4,$B3,$C1,$CF,$E5,$F0
        .DB $B3,$C1,$E8,$DA,$B3,$C1,$E8,$DB,$ED,$C1,$E8,$DA,$B3,$EB,$F8,$B0
        .DB $B0,$B0,$DF,$C1,$B5,$E3,$B3,$C1,$B5,$E9,$E3,$B3,$C1,$CF,$E9,$C4
        .DB $B3,$C1,$B5,$E3,$B3,$C1,$B5,$E9,$E9,$C1,$CF,$C4,$B3,$EB,$F8,$B0
        .DB $B0,$B0,$DF,$B1,$C1,$F1,$C3,$C7,$C1,$C1,$F1,$C3,$B4,$CF,$E9,$B2
        .DB $C3,$C7,$C1,$F1,$C3,$C7,$C1,$C1,$C3,$B4,$CF,$B2,$C3,$EB,$F8,$B0
        .DB $B0,$B0,$DF,$CA,$CB,$CB,$CB,$CE,$CB,$CB,$CB,$CB,$CE,$D8,$E9,$E9
        .DB $EA,$CE,$CB,$CB,$CB,$CE,$CB,$CB,$CB,$CE,$D8,$E9,$EA,$CD,$F8,$B0
MAINMENU_LO:    .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C0,$B6,$E9,$B8,$C2,$C0
        .DB $C1,$C1,$C2,$C0,$BC,$E4,$C2,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C1,$C5,$C6,$C1,$B3,$C1
        .DB $D9,$D3,$B3,$C1,$BD,$C4,$B3,$EE,$FB,$FC,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C1,$D5,$D6,$D7,$B3,$C1
        .DB $D0,$D1,$B3,$C1,$BE,$F2,$B3,$EB,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C1,$B7,$E6,$E7,$B3,$C1
        .DB $E0,$E1,$B3,$C1,$B9,$BF,$B3,$EB,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C1,$CF,$E5,$F0,$B3,$C1
        .DB $E8,$DA,$B3,$C1,$BB,$C8,$B3,$EB,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$C1,$CF,$E9,$C4,$B3,$C1
        .DB $CF,$C4,$B3,$C1,$C9,$C1,$B3,$EB,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$D4,$CF,$E9,$B2,$C3,$B4
        .DB $CF,$B2,$C3,$B4,$CF,$BA,$C3,$EB,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0,$B0,$DF,$E9,$E9,$E9,$E9,$E9,$E9,$E9,$CA,$D8,$E9,$E9,$EA,$CE
        .DB $D8,$E9,$EA,$CE,$D8,$F3,$CB,$CD,$E9,$E9,$E9,$E9,$E9,$E9,$F8,$B0
        .DB $B0 ; -
        .DB $B0 ; -
        .DB $F4
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9
        .DB $F9

; =============== S U B R O U T I N E =======================================

; Draw text in the menu (copyright, license)

DRAWMENUTEXT:               
        LDY #0
        LDX #5

NEXTSTRING:             
        JSR NEXTCHAR
        STA PPU_ADDRESS
        JSR NEXTCHAR
        STA PPU_ADDRESS

CONTINUEDRAW:               
        JSR NEXTCHAR
        CMP #$FF
        BEQ BREAKDRAW
        STA PPU_DATA
        BNE CONTINUEDRAW

BREAKDRAW:              
        DEX
        BNE NEXTSTRING
        RTS


; =============== S U B R O U T I N E =======================================


NEXTCHAR:               
        LDA MENUTEXT,Y
        INY
        RTS

; ---------------------------------------------------------------------------
MENUTEXT:   .DB $22       
        .DB $69
        .DB "START",$B0,$B0,$B0,"CONTINUE"
        .DB $FF
        .DB $22
        .DB $AA
        .DB "TOP"
        .DB $FF
        .DB $22
        .DB $E3
        .DB "TM",$B0,"AND",$B0
        .DB $FE
        .DB $B0,"1987",$B0,"HUDSON",$B0,"SOFT"
        .DB $FF
        .DB $23
        .DB $2A
        .DB "LICENSED",$B0,"BY"
        .DB $FF
        .DB $23
        .DB $64
        .DB "NINTENDO",$B0,"OF",$B0,"AMERICA",$B0,"INC"
        .DB $FD
        .DB $FF
STAGE_ROWS:
		.DB   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1
        .DB   1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1
        .DB   1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  1

MULT_TABY:  .DB   0,$20,$40,$60,$80,$A0,$C0,$E0,  0,$20,$40,$60,$80
MULT_TABX:  .DB   2,  2,  2,  2,  2,  2,  2,  2,  3,  3,  3,  3,  3

; =============== S U B R O U T I N E =======================================


sub_E2BD:               
        LDA BONUS_POWER
        LSR
        LSR
        LSR
        LSR
        STA BOMB_PWR
        LDA STAGE
        AND #$F
        STA STAGE_LO
        LDA STAGE
        LSR
        LSR
        LSR
        LSR
        STA STAGE_HI
        LDY #0
        LDX #0
        LDA #3
        STA byte_1F

loc_E2DB:               
        JSR sub_E33C
        JSR _get_pass_data_var_addr
        LDA TEMP_X
        STA (STAGE_MAP),Y
        DEC byte_1F
        BNE loc_E2DB
        JSR sub_E33C
        LDA PW_CXSUM1
        ASL
        CLC
        ADC TEMP_X
        STA TEMP_X
        LDA PW_CXSUM2
        ASL
        CLC
        ADC TEMP_X
        STA TEMP_X
        LDA PW_CXSUM3
        ASL
        CLC
        ADC TEMP_X
        STA PW_CXSUM4
        LDY #0
        STY SEED
        LDX #0

loc_E30A:               
        JSR _get_pass_data_var_addr
        LDA (STAGE_MAP),Y
        AND #$F
        SEC
        SBC SEED
        SEC
        SBC #7
        AND #$F
        STA _password_buffer,X
        STA SEED
        CPX #$28 ; '('
        BNE loc_E30A
        LDA #$23 ; '#'
        LDX #6
        JSR VRAMADDR
        LDX #2

loc_E32B:               
        LDA _password_buffer,X
        TAY
        LDA aAofkcpgelbhmjd,Y ; "AOFKCPGELBHMJDNI"
        STA PPU_DATA
        INX
        INX
        CPX #$2A ; '*'
        BNE loc_E32B
        RTS


; =============== S U B R O U T I N E =======================================


sub_E33C:               
        LDA #4
        STA byte_20
        LDA #0
        STA TEMP_X

loc_E344:               
        JSR _get_pass_data_var_addr
        LDA (STAGE_MAP),Y
        CLC
        ADC TEMP_X
        STA TEMP_X
        DEC byte_20
        BNE loc_E344
        RTS


; =============== S U B R O U T I N E =======================================


_get_pass_data_var_addr:        
        LDA _pass_data_vars,X
        STA STAGE_MAP
        INX
        LDA _pass_data_vars,X
        STA STAGE_MAP+1
        INX
        RTS

; ---------------------------------------------------------------------------
_pass_data_vars:
		.DW   $67,  $77,  $DD,  $61,  $99,  $66,  $DC,  $64,  $79,  $9A
        .DW   $74,  $63,  $75,  $62,  $9B,  $65,  $94,  $DE,  $76,  $95
aAofkcpgelbhmjd:
		.DB "AOFKCPGELBHMJDNI" 
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR sub_E399

locret_E398:                
        RTS

; =============== S U B R O U T I N E =======================================


sub_E399:               
        LDA ENEMIES_LEFT
        BNE loc_E3A7
        LDA byte_B1
        BNE loc_E3A7
        INC byte_B1
        LDA #6
        STA APU_SOUND   ; Play the sound

loc_E3A7:               
        LDA BONUS_STATUS
        BEQ loc_E3E7
        CMP #2
        BEQ locret_E398
        LDA FRAME_CNT
        AND #1
        BNE loc_E3BD
        DEC BONUS_TIMER
        BNE loc_E3BD
        LDA #2
        STA BONUS_STATUS

loc_E3BD:               
        JSR sub_CFED
        LDA EXTRA_BONUS_ITEM_X
        CMP BOMBMAN_X
        BNE locret_E3E6
        LDA BOMBMAN_Y
        CMP EXTRA_BONUS_ITEM_Y
        BNE locret_E3E6
        LDA #4
        STA APU_SOUND   ; Play the sound
        LDX BONUS_AVAILABLE
        LDA byte_E4BC,X
        CMP #$64 ; 'd'
        BCC loc_E3DF
        JSR loc_DD6B
        JMP loc_E3E2
; ---------------------------------------------------------------------------

loc_E3DF:               
        JSR sub_DD77

loc_E3E2:               
        LDA #2
        STA BONUS_STATUS

locret_E3E6:                
        RTS
; ---------------------------------------------------------------------------

loc_E3E7:               
        LDA BOMBMAN_X
        CMP #1
        BNE loc_E401
        LDA BOMBMAN_Y
        CMP #1
        BNE loc_E3F8
        INC VISITS_TOP_LEFT
        JMP loc_E416
; ---------------------------------------------------------------------------

loc_E3F8:               
        CMP #$B
        BNE loc_E401
        INC VISITS_BOTTOM_LEFT
        JMP loc_E416
; ---------------------------------------------------------------------------

loc_E401:               
        CMP #$1D
        BNE loc_E416
        LDA BOMBMAN_Y
        CMP #1
        BNE loc_E410
        INC VISITS_TOP_RIGHT
        JMP loc_E416
; ---------------------------------------------------------------------------

loc_E410:               
        CMP #$B
        BNE loc_E416
        INC VISITS_BOTTOM_RIGHT

loc_E416:               
        LDA BOMBMAN_X
        CMP #1
        BEQ loc_E434
        CMP #$1D
        BEQ loc_E434
        LDA BOMBMAN_Y
        CMP #1
        BEQ loc_E434
        CMP #$B
        BEQ loc_E434
        LDA #0
        STA VISITS_TOP_LEFT
        STA VISITS_TOP_RIGHT
        STA VISITS_BOTTOM_LEFT
        STA VISITS_BOTTOM_RIGHT

loc_E434:               
        LDX BONUS_AVAILABLE
        BEQ loc_E448
        DEX
        BEQ loc_E468
        DEX
        BEQ loc_E47D
        DEX
        BEQ loc_E486
        DEX
        BEQ loc_E48D
        DEX
        BEQ loc_E498
        RTS
; ---------------------------------------------------------------------------

loc_E448:               
        LDA ENEMIES_DEFEATED
        BNE locret_E467
        LDA EXIT_DWELL_TIME
        BEQ locret_E467

loc_E450:               
        LDA BONUS_STATUS
        BNE locret_E467
        LDA #1
        STA BONUS_STATUS
        LDA #0
        STA BONUS_TIMER
        JSR RAND_COORDS
        LDA TEMP_X
        STA EXTRA_BONUS_ITEM_X
        LDA TEMP_Y
        STA EXTRA_BONUS_ITEM_Y

locret_E467:                
        RTS
; ---------------------------------------------------------------------------

loc_E468:               
        LDA ENEMIES_LEFT
        BNE locret_E467
        LDA VISITS_TOP_LEFT
        BEQ locret_E467
        LDA VISITS_TOP_RIGHT
        BEQ locret_E467
        LDA VISITS_BOTTOM_LEFT
        BEQ locret_E467
        LDA VISITS_BOTTOM_RIGHT
        BNE loc_E450
        RTS
; ---------------------------------------------------------------------------

loc_E47D:               
        LDA ENEMIES_LEFT
        BNE locret_E467
        LDA BRICKS_BLOWN_UP
        BEQ loc_E450
        RTS
; ---------------------------------------------------------------------------

loc_E486:               
        LDA CHAIN_REACTIONS
        CMP #$F8
        BCS loc_E450
        RTS
; ---------------------------------------------------------------------------

loc_E48D:               
        LDA EXIT_DWELL_TIME
        BEQ locret_E467
        LDA KEY_TIMER
        CMP #$F8
        BCS loc_E450
        RTS
; ---------------------------------------------------------------------------

loc_E498:               
        LDA ENEMIES_DEFEATED
        BNE locret_E467
        LDA STAGE
        ASL
        CLC
        ADC #$32 ; '2'
        CMP BRICKS_BLOWN_UP
        BEQ loc_E4A8
        BCS locret_E467

loc_E4A8:               
        LDA EXIT_BOMBED_COUNT
        CMP #3
        BEQ loc_E450
        RTS


; =============== S U B R O U T I N E =======================================


sub_E4AF:               
        LDA STAGE
        AND #7
        CMP #6
        BCC loc_E4B9
        AND #1

loc_E4B9:               
        STA BONUS_AVAILABLE
        RTS

; ---------------------------------------------------------------------------
byte_E4BC:  .DB   1,  2,$64,$32,  3,$C8 
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR APU_PLAY_MELODY

APU_STOP:               
        LDA #0
        STA APU_MUSIC

APU_ABORT:              
        RTS

; =============== S U B R O U T I N E =======================================

; Play a tune

APU_PLAY_MELODY:            
        LDA APU_DISABLE
        BNE APU_ABORT
        LDA APU_MUSIC
        BEQ APU_ABORT
        BMI UPDATE_MELODY
        CMP #$B
        BCS APU_STOP
        STA APU_TEMP
        ORA #$80
        STA APU_MUSIC
        DEC APU_TEMP
        LDA APU_TEMP
        ASL
        ASL
        ASL
        TAY
        LDX #0

START_MELODY:               
        LDA APU_MELODIES_TAB,Y ; 1: TITLE
        STA APU_CHANDAT,X
        INY
        INX
        CPX #6
        BNE START_MELODY
        LDA APU_MELODIES_TAB,Y ; 1: TITLE
        STA byte_D3
        LDA APU_MELODIES_TAB+1,Y ; 1: TITLE
        STA byte_D4
        LDA #0
        STA APU_CNT
        STA APU_CNT+1
        STA APU_CNT+2
        STA byte_D5
        STA byte_CD
        STA byte_CE
        STA byte_CF
        STA byte_D0
        STA byte_D1
        STA byte_D2
        LDA #1
        STA byte_B6
        STA byte_B6+1
        STA byte_B6+2
        STA byte_B9
        STA byte_BA
        STA byte_BB
        STA byte_D6
        STA byte_D7
        STA byte_D8
        LDA #8
        STA byte_D9
        STA byte_DA

UPDATE_MELODY:              
        LDA #2
        STA APU_CHAN

NEXT_CHANNEL:               
        LDX APU_CHAN
        DEC $B6,X
        BEQ PLAY_CHANNEL

ADVANCE_CHANNEL:            
        DEC APU_CHAN
        BPL NEXT_CHANNEL
        RTS
; ---------------------------------------------------------------------------

PLAY_CHANNEL:               
        TXA
        ASL
        TAX
        LDA APU_CHANDAT,X
        STA APU_PTR
        LDA APU_CHANDAT+1,X
        STA APU_PTR+1
        ORA APU_PTR
        BEQ ADVANCE_CHANNEL
        JSR APU_WRITE_REGS
        JMP ADVANCE_CHANNEL


; =============== S U B R O U T I N E =======================================


APU_WRITE_REGS:             
        LDX APU_CHAN
        LDY APU_CNT,X
        LDA (APU_PTR),Y
        STA APU_TEMP
        INC APU_CNT,X
        LDA APU_TEMP
        BMI CONTROL_BYTE
        LDA byte_B9,X
        STA byte_B6,X
        CPX #2
        BEQ FIX_TRIANGLE
        LSR
        LSR
        CMP #$10
        BCC FIX_DELAY
        LDA #$F
        BNE FIX_DELAY

FIX_TRIANGLE:               
        ASL
        BPL FIX_DELAY
        LDA #$7F

FIX_DELAY:              
        STA byte_D6,X
        LDA byte_D0,X
        BEQ loc_E57B
        LSR byte_D6,X

loc_E57B:               
        LDY APU_CHAN_DIS,X
        BNE ABORT_WRITE
        LDA APU_TEMP
        CMP #0
        BEQ ABORT_WRITE
        TXA
        ASL
        ASL
        TAY
        LDA byte_CD,X
        BEQ loc_E59D
        BPL loc_E593
        INC byte_CD,X
        BEQ loc_E59D

loc_E593:               
        LDA #$9F
        CPX #2
        BNE loc_E5A1
        LDA #$7F
        BNE loc_E5A1

loc_E59D:               
        LDA byte_D6,X
        ORA byte_D3,X

loc_E5A1:               
        STA $4000,Y
        LDA byte_CD,X
        CMP #2
        BNE loc_E5AB
        RTS
; ---------------------------------------------------------------------------

loc_E5AB:               
        CPX #2
        BCS SET_WAVELEN
        LDA byte_D9,X
        STA $4001,Y

SET_WAVELEN:                
        LDA APU_TEMP
        ASL
        TAX
        LDA WAVELEN_TAB,X
        STA $4002,Y
        LDA WAVELEN_TAB+1,X
        ORA #8
        STA $4003,Y

ABORT_WRITE:                
        RTS
; ---------------------------------------------------------------------------

CONTROL_BYTE:               
        AND #$F0
        CMP #$F0
        BEQ EXEC_EFFECT
        LDA APU_TEMP
        AND #$7F
        STA byte_B9,X
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------

EXEC_EFFECT:                
        SEC
        LDA #$FF
        SBC APU_TEMP
        ASL
        TAY
        LDA off_E5E6+1,Y
        PHA
        LDA off_E5E6,Y
        PHA
        RTS

; ---------------------------------------------------------------------------
off_E5E6:
		.DW off_E5F4+1    
        .DW locret_E5FA
        .DW loc_E5FF+2
        .DW loc_E60D+2
        .DW loc_E618+2
        .DW loc_E62A+2
        .DW loc_E631+2
off_E5F4:
		.DW loc_E638+2    
; ---------------------------------------------------------------------------
        LDA #0
        STA APU_MUSIC

locret_E5FA:                
        RTS
; ---------------------------------------------------------------------------
        LDA #0
        STA APU_CNT,X

loc_E5FF:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        LDY APU_CNT,X
        LDA (APU_PTR),Y
        STA unk_CA,X
        INY
        STY APU_CNT,X
        STY unk_C7,X

loc_E60D:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        DEC unk_CA,X
        BEQ loc_E618
        LDA unk_C7,X
        STA APU_CNT,X

loc_E618:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        LDA byte_CD,X
        BEQ loc_E626
        LDA #2
        STA byte_CD,X
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------

loc_E626:               
        LDA #1
        STA byte_CD,X

loc_E62A:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        LDA #$FF
        STA byte_CD,X

loc_E631:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        LDA #$FF
        STA byte_D0,X

loc_E638:               
        JMP APU_WRITE_REGS
; ---------------------------------------------------------------------------
        LDA #0
        STA byte_D0,X

loc_E63F:
        JMP APU_WRITE_REGS

; =============== S U B R O U T I N E =======================================

; Reset APU state

APU_RESET:              
        LDA #0
        STA APU_DELTA_REG+1
        STA APU_CHAN_DIS
        STA APU_CHAN_DIS+1
        STA APU_CHAN_DIS+2
        STA APU_SQUARE1_REG
        STA APU_SQUARE2_REG
        STA APU_TRIANGLE_REG
        STA APU_NOISE_REG
        LDA #$F
        STA APU_MASTERCTRL_REG
        RTS


; =============== S U B R O U T I N E =======================================

; Play the sound

APU_PLAY_SOUND:             
        LDX #2

MUTE_CHANNEL:               
        LDA APU_CHAN_DIS,X
        BEQ MUTE_NEXT_CHAN
        DEC APU_CHAN_DIS,X

MUTE_NEXT_CHAN:             
        DEX
        BPL MUTE_CHANNEL
        LDA APU_SOUND   ; Play the sound
        BMI UPDATE_SOUND
        CMP #7
        BCS WRONG_SOUND ; >= 7
        CMP #3
        BCS START_SOUND ; >= 3
        LDX APU_PATTERN
        BEQ START_SOUND
        TXA
        ORA #$80
        STA APU_SOUND   ; Play the sound
        BNE UPDATE_SOUND

START_SOUND:                
        STA APU_PATTERN
        ORA #$80
        STA APU_SOUND   ; Play the sound
        LDA #0
        STA APU_SOUND_MOD
        STA APU_SOUND_MOD+1
        STA APU_SOUND_MOD+2
        LDA APU_PATTERN
        ASL
        TAX
        LDA MOD_SOUND_TAB+1,X
        PHA
        LDA MOD_SOUND_TAB,X
        PHA
        RTS
; ---------------------------------------------------------------------------

UPDATE_SOUND:               
        LDA APU_PATTERN
        CMP #7
        BCS WRONG_SOUND
        ASL
        TAX
        LDA CONST_SOUND_TAB+1,X
        PHA
        LDA CONST_SOUND_TAB,X
        PHA

WRONG_SOUND:                
        RTS

; ---------------------------------------------------------------------------
MOD_SOUND_TAB:  
        .DW APU_RESET-1   ; Reset APU state
        .DW S1_START-1
        .DW S2_START-1
        .DW S3_START-1
        .DW S4_START-1
        .DW S5_START-1
        .DW S6_START-1
CONST_SOUND_TAB:
        .DW WRONG_SOUND-1 
        .DW WRONG_SOUND-1
        .DW WRONG_SOUND-1
        .DW S3_UPDATE-1
        .DW S4_UPDATE-1
        .DW WRONG_SOUND-1
        .DW S6_UPDATE-1
; ---------------------------------------------------------------------------

S1_START:               
        LDA #4
        BNE loc_E6CF

S2_START:               
        LDA #$C

loc_E6CF:               
        STA APU_NOISE_REG+2
        LDA #0
        STA APU_PATTERN
        STA APU_NOISE_REG
        LDA #$10
        STA APU_NOISE_REG+3
        RTS
; ---------------------------------------------------------------------------

S3_START:               
        LDA #$10
        STA APU_SOUND_MOD+1
        LDA #1
        STA APU_NOISE_REG
        LDA #$F
        STA APU_NOISE_REG+2
        LDA #$10
        STA APU_NOISE_REG+3
        LDA #$FF
        STA APU_SQUARE2_REG
        LDA #$84
        STA APU_SQUARE2_REG+1
        LDA #0
        STA APU_SQUARE2_REG+2
        LDA #2
        STA APU_SQUARE2_REG+3
        LDA #4
        STA APU_SDELAY
        RTS
; ---------------------------------------------------------------------------

S3_UPDATE:              
        DEC APU_SDELAY
        BNE locret_E727
        LDA #$DF
        STA APU_SQUARE2_REG
        LDA #$84
        STA APU_SQUARE2_REG+1
        LDA #0
        STA APU_SQUARE2_REG+2
        LDA #$81
        STA APU_SQUARE2_REG+3
        LDA #0
        STA APU_PATTERN

locret_E727:                
        RTS
; ---------------------------------------------------------------------------

S4_START:               
        LDA #$FF
        STA APU_SOUND_MOD+1
        LDA #0
        STA APU_SDELAY
        LDA #4
        STA APU_SDELAY+1

S4_UPDATE:              
        LDA APU_SDELAY
        BNE S4_PITCH1
        LDA APU_SDELAY+1
        BNE S4_PITCH2
        LDA #0
        STA APU_PATTERN
        STA APU_SOUND_MOD+1
        RTS
; ---------------------------------------------------------------------------

S4_PITCH2:              
        DEC APU_SDELAY+1
        LDA #$84
        STA APU_SQUARE2_REG
        LDA #$8B
        STA APU_SQUARE2_REG+1
        LDX APU_SDELAY+1
        LDA S4_PITCH_TAB,X
        STA APU_SQUARE2_REG+2
        LDA #$10
        STA APU_SQUARE2_REG+3
        LDA #4
        STA APU_SDELAY

S4_PITCH1:              
        DEC APU_SDELAY
        RTS
; ---------------------------------------------------------------------------
S4_PITCH_TAB:   .DB $65,$87,$B4,$F0   
; ---------------------------------------------------------------------------

S5_START:               
        LDA #$30 ; '0'
        STA APU_SOUND_MOD+1
        LDA #9
        STA APU_NOISE_REG
        LDA #7
        STA APU_NOISE_REG+2
        LDA #$30 ; '0'
        STA APU_NOISE_REG+3
        LDA #$1F
        STA APU_SQUARE2_REG
        LDA #$8F
        STA APU_SQUARE2_REG+1
        LDA #0
        STA APU_SQUARE2_REG+2
        LDA #$33 ; '3'
        STA APU_SQUARE2_REG+3
        LDA #0
        STA APU_PATTERN
        RTS
; ---------------------------------------------------------------------------

S6_START:               
        LDA #$1D
        STA APU_SDELAY
        LDA #$FF
        STA APU_SOUND_MOD+0
        STA APU_SOUND_MOD+1
        STA APU_SOUND_MOD+2

S6_UPDATE:              
        DEC APU_SDELAY
        BEQ S6_PITCH
        LDA APU_SDELAY
        AND #3
        BNE S6_END
        LDA APU_SDELAY
        LSR
        LSR
        AND #1
        TAX
        LDA S6_SQ1MOD_TAB,X
        STA APU_SQUARE1_REG+2
        LDA S6_SQ2MOD_TAB,X
        STA APU_SQUARE2_REG+2
        LDA #8
        STA APU_SQUARE1_REG
        STA APU_SQUARE2_REG
        STA APU_SQUARE1_REG+1
        STA APU_SQUARE2_REG+1
        STA APU_SQUARE1_REG+3
        STA APU_SQUARE2_REG+3

S6_END:                 
        RTS
; ---------------------------------------------------------------------------

S6_PITCH:               
        LDA #$20 ; ' '
        STA APU_SOUND_MOD+0
        STA APU_SOUND_MOD+1
        STA APU_SOUND_MOD+2
        LDA #0
        STA APU_PATTERN
        RTS
; ---------------------------------------------------------------------------
S6_SQ1MOD_TAB: .DB $A9, $A0
S6_SQ2MOD_TAB: .DB $6A, $64

; Wavelength for square wave notes on an NTSC system (triangle wave are one octave lower)
WAVELEN_TAB:
        .DW     0     ; Silence
        ;       A    Bb     B     C    C#     D    D#     E     F    F#     G    G#     Scientific designation
        .DW  $7F0, $77E, $712, $6AE, $64E, $5F3, $59F, $54D, $501, $4B9, $475, $435       ; Octave 2
        .DW  $3F8, $3BF, $389, $357, $327, $2F9, $2CF, $2A6, $280, $25C, $23A, $21A       ; Octave 3
        .DW  $1FC, $1DF, $1C4, $1AB, $193, $17C, $167, $152, $13F, $12D, $11C, $10C       ; Octave 4 (With middle C)
        .DW   $FD,  $EE,  $E1,  $D4,  $C8,  $BD,  $B2,  $A8,  $9F,  $96,  $8D,  $85       ; Octave 5
        .DW   $7E,  $76,  $70,  $69,  $63,  $5E,  $58,  $53,  $4F,  $4A,  $46,  $42       ; Octave 6
        .DW   $3E,  $3A,  $37,  $34,  $31,  $2E,  $2B,  $29,  $27,  $24,  $22,  $20       ; Octave 7
        .DW   $1E,  $1C,  $1B,  $1A                                                       ; Octave 8

APU_MELODIES_TAB:
        .DW TUNE1_TRI,    TUNE1_SQ2,    TUNE1_SQ1,  $8080 ; 1: TITLE
        .DW TUNE2_TRI,    TUNE2_SQ2,    TUNE2_SQ1,  $4040 ; 2: STAGE_SCREEN
        .DW         0,            0,    TUNE3_SQ1,  $8080 ; 3: STAGE
        .DW TUNE4_TRI,    TUNE4_SQ2,    TUNE4_SQ1,  $8080 ; 4: STAGE2
        .DW TUNE5_TRI,    TUNE5_SQ2,    TUNE5_SQ1,  $8080 ; 5: GODMODE
        .DW TUNE6_TRI,    TUNE6_SQ2,    TUNE6_SQ1,  $8080 ; 6: BONUS
        .DW TUNE7_TRI,    TUNE7_SQ2,    TUNE7_SQ1,  $0040 ; 7: FANFARE
        .DW TUNE8_TRI,    TUNE8_SQ2,            0,  $8080 ; 8: DIED
        .DW TUNE9_TRI,    TUNE9_SQ2,    TUNE9_SQ1,  $8080 ; 9: GAMEOVER
        .DW TUNE7_TRI+55, TUNE7_SQ2+59, TUNE10_SQ1, $0040 ; 10: ??? (not used music)

TUNE7_TRI:  .DB $B0,$29,$AA,$29,$86,$29,$A4,$30,$86,$30,$35,$F9,$8C,$2E,$F8,$98
        .DB $2D,$86,$2D,$2E,$8C,$2D,$C8,$2B,$86,$32,$33,$8C,$32,$B0,$30,$8C
        .DB   0,$26,$28,$B0,$29,$AA,$29,$86,$29,$A4,$30,$86,$30,$35,$F9,$8C
        .DB $2E,$F8,$98,$2D,$86,$2D,$2E,$8C,$2D,$2B,$32,$33,$30,  0,$92,$30
        .DB $83,$32,$34,$8C,$35,  0,$1D,$86,$1D,$1D,$8C,$1D,  0,$98,  0,$FF
TUNE7_SQ2:  .DB $B0,$21,$AA,$21,$86,$21,$A4,$2D,$86,$2D,$30,$F9,$8C,$29,$F8,$98
        .DB $29,$86,$24,$29,$8C,$24,$C8,$27,$86,$2E,$2B,$8C,$2E,$28,$92,$24
        .DB $86,$24,$8C,$24,$24,$24,$24,$B0,$21,$AA,$21,$86,$21,$A4,$2D,$86
        .DB $2D,$30,$F9,$8C,$29,$F8,$98,$29,$86,$24,$29,$8C,$29,$26,$2B,$2E
        .DB $28,  0,$92,$28,$83,$29,$2B,$8C,$2D,  0,$11,$86,$11,$11,$8C,$11
        .DB   0,$98,  0,$FF
TUNE7_SQ1:  .DB $F9,$FD,  2,$98,$1D,$1C,$1A,$18,$FC,$1B,$1A,$18,$16,$18,$18,$1A
        .DB $1C,$FD,  2,$1D,$1C,$1A,$18,$FC
TUNE10_SQ1: .DB $F8,$8C,$1F,$1D,$1B,$2B,$18,  0,$92,$18,$83,$18,$18,$8C,$29,  0
        .DB $11,$86,$11,$11,$8C,$11,  0,$98,  0,$FF
TUNE9_TRI:  .DB $98,$28,$92,$24,$86,$24,$98,$27,$92,$24,$86,$24,$28,$29,$2A,$2B
        .DB $F9,$8C,$28,$24,$F8,$98,$22,$29,$28,$92,$24,$86,$24,$98,$27,$92
        .DB $24,$86,$24,$8C,$22,$84,$21,$20,$1F,$F9,$8C,$22,$23,$F8,$24,  0
        .DB $98,  0,$FF
TUNE9_SQ2:  .DB $E0,  0,$86,$1F,$21,$22,$23,$F9,$8C,$1F,$1C,$F8,$98,$1D,$22,$1F
        .DB $92,$1C,$86,$1C,$98,$1E,$92,$1B,$86,$1E,$8C,$16,$84,$15,$14,$13
        .DB $F9,$8C,$16,$17,$F8,$18,  0, $C,  0,$FF
TUNE9_SQ1:  .DB $8C,$18,$1F,  0,$1F,$18,$1F,  0,$1F,$18,$1F,  0,$1F,$14,$1B,  0
        .DB $1B,$18,$1F,  0,$1F,$14,$1B,  0,$1B,$16,$84,$15,$14,$13,$F9,$8C
        .DB $16,$17,$F8,$18,  0, $C,  0,$FF
TUNE6_TRI:  .DB $94,  0,$85,$2C,$2C,$33,$33,$8A,$33,  0,$85,$2C,$2C,$33,$33,$32
        .DB $32,$30,$30,$2E,$2E,$29,$29,$26,$26,$24,$24,$94,$22,  0,$85,$31
        .DB $31,$36,$36,$8A,$36,  0,$85,$31,$31,$3A,$3A,$37,$37,$35,$35,$33
        .DB $33,$31,$31,$30,$30,$2E,$2E,$2C,$2C,$2B,$2B,$FE
TUNE6_SQ2:  .DB $94,  0,$85,$24,$24,$30,$30,$8A,$30,  0,$85,$24,$24,$30,$30,$2E
        .DB $2E,$2D,$2D,$29,$29,$26,$26,$22,$22,$1D,$1D,$94,$1A,  0,$85,$2E
        .DB $2E,$31,$31,$8A,$31,  0,$85,$2E,$2E,$31,$31,$33,$33,$31,$31,$30
        .DB $30,$2E,$2E,$2C,$2C,$2B,$2B,$24,$24,$22,$22,$FE
TUNE6_SQ1:  .DB $85,$14,$14,$20,$20,$2C,$2C,$20,$20,$14,$14,$20,$20,$2C,$2C,$20
        .DB $20,$16,$16,$22,$22,$2E,$2E,$22,$22,$16,$16,$22,$22,$16,$16,$22
        .DB $22,$12,$12,$1E,$1E,$2A,$2A,$1E,$1E,$12,$12,$1E,$1E,$2A,$2A,$1E
        .DB $1E, $F, $F,$1B,$1B,$27,$27,$1B,$1B, $F, $F,$1B,$1B,$27,$27,$25
        .DB $25,$FE
TUNE8_TRI:  .DB $83,$30,$2B,$24,$1F,$18,$13, $C,  7,$18,$17,$16,$15,$14,$15,$16 ; +
        .DB $17,$92,$18,$86,$18,$F9,$8C,$1B,$1B,$F8,$98,$18,  0,$FF ;
TUNE8_SQ2:  .DB $98,  0,$83, $C, $B, $A,  9,  8,  9, $A, $B,$92, $C,$86, $C,$F9
        .DB $8C, $F, $F,$F8,$98, $C,  0,$FF
TUNE1_TRI:  .DB $87,$27,$33,$3F,$33,$36,$37,$33,$31,$27,$33,$3F,$33,$36,$37,$33
        .DB $31,$16,$16,$F9,$8E,$16,$F8,$87,$22,$22,$F9,$8E,$2E, $D, $F,$F8
        .DB $87,$38,$2E,$33,$38,$FD,  3,$F9,$8E,$37,$33,$32,$33,$F8,$9C,$2E
        .DB $87,$2C,$2E,$2A,$2B,$8E,  0,$3A,  0,$3A,$87,$33,$33,$F9,$8E,$33
        .DB $F8,$87,$38,$2E,$33,$38,$FC,$F9,$8E,$37,$F8,$87,$32,$33,$2C,$2E
        .DB $F9,$8E,$2B,$F8,$87,$2C,$2C,$F9,$8E,$2C,$F8,$87,$2B,$2B,$F9,$8E
        .DB $2B,$27,$27,  0,$F8,$87,$25,$26,$8E,$27,  0,$9C,  0,$FF
TUNE1_SQ2:  .DB $87,$1B,$27,$33,$27,$2A,$2B,$27,$25,$1B,$27,$33,$27,$2A,$2B,$27
        .DB $25,$13,$13,$F9,$8E,$13,$F8,$87,$1F,$1F,$F9,$8E,$2B,  1,  2,$F8
        .DB $87,$2C,$22,$27,$2C,$FD,  3,$F9,$8E,$31,$2E,$2A,$2B,$F8,$9C,$25
        .DB   0,$8E,$27,$22,$25,$2C,$9C,$2B,$87,$35,$22,$30,$33,$FC,$F9,$8E
        .DB $33,$F8,$87,$2A,$2B,$26,$27,$F9,$8E,$22,$F8,$87,$27,$27,$F9,$8E
        .DB $27,$F8,$87,$27,$27,$F9,$8E,$27,$1F,$1F,  0,$F8,$87,$19,$1A,$8E
        .DB $1B,  0,$9C,  0,$FF
TUNE1_SQ1:  .DB $87,$1B,$1B,$1B,$1B,$9C,  0,$87,$1B,$1B,$1B,$1B,$9C,  0,$87,$19
        .DB $19,$F9,$8E,$19,$F8,$87,$25,$25,$F9,$8E,$32,$F8,$B8,  0,$FD,  3
        .DB $87,$1B,$1B,$F9,$8E,$1B,$1E,$F8,$87,$1F,$22,$27,$1B,$1B,$1B,$1E
        .DB $F9,$8E,$1F,$F8,$87,$18,$19,$19,$19,$25,$18,$1A,$8E,$16,$87,$25
        .DB $19,$19,$19,$9C,  0,$FC,$F9,$8E,$2E,$F8,$87,$2D,$2E,$2A,$2B,$27
        .DB $22,$9C,  0,$87,$23,$23,$F9,$8E,$23,$22,$22,$F8,  0,$87,$19,$1A
        .DB $8E,$1B,  0,$9C,  0,$FF
TUNE5_TRI:  .DB $FD,  2,$90,$25,$88,$27,$29,  0,$29,$2B,  0,$FC,$C0,  0,$88,$22
        .DB $19,$22,$20,$1F,$19,$1F,$20,$FD,  2,$27,$29,$27,$2A,  0,$29,$27
        .DB   0,$FC,$C0,  0,$88,$20,$17,$20,$1E,$1D,$17,$1D,$1F,$FE
TUNE5_SQ2:  .DB $FD,  2,$90,$22,$88,$24,$26,  0,$26,$27,  0,$FC,$FD,  2,$1B,$13
        .DB $1B,$19,$18,$13,$18,$19,$FC,$FD,  2,$23,$25,$23,$27,  0,$25,$23
        .DB   0,$FC,$FD,  2,$19,$11,$19,$17,$16,$11,$16,$19,$FC,$FE
TUNE5_SQ1:  .DB $FD,  4,$90,$1B,$1B,$1B,$1B,$FC,$FD,  4,$19,$19,$19,$19,$FC,$FE
TUNE2_TRI:  .DB $85,$33,  0,$32,$33,$32,$33,$32,$33,$2E,  0,$2D,$2E,$2D,$2E,$2D
        .DB $2E,$2B,$2C,$2D,$2E,$2B,$2C,$2D,$2E,$2B,  0,$27,  0,$94,$25,$FF
TUNE2_SQ2:  .DB $85,$2B,  0,$2A,$2B,$2A,$2B,$2A,$2B,$27,  0,$26,$27,$26,$27,$26
        .DB $27,$27,$29,$2A,$2B,$27,$29,$2A,$2B,$27,  0,$1F,  0,$94,$22,$FF
TUNE2_SQ1:  .DB $F9,$8A,$1B,$1B,$1F,$22,$1B,$1B,$1F,$22,$F8,$85,$22,$24,$26,$27
        .DB $22,$24,$26,$27,$F9,$8A,$22,$1B,$F8,$94,$16,$FF
TUNE4_SQ1:  .DB $FD,  2,$87,$27,$27,$F9,$8E,$30,$31,$F8,$87,$22,$22,$F9,$8E,$2E
        .DB $30,$F8,$87,$31,$30,$F9,$8E,$2E,$F8,$FC,$FD,  2,$87,$25,$25,$F9
        .DB $8E,$2E,$2F,$F8,$87,$20,$20,$F9,$8E,$2C,$2E,$F8,$87,$2F,$2E,$F9
        .DB $8E,$2C,$F8,$FC,$FE
TUNE4_TRI:  .DB $9C,  0,$87,$25,$95,  0,$B8,  0,$9C,  0,$95,$27,$87,$27,$F9,$8E
        .DB $2C,$2B,$F8,$27,  0,$9C,  0,$87,$23,$95,  0,$B8,  0,$9C,  0,$95
        .DB $25,$87,$25,$F9,$8E,$2A,$F8,$87,$29,$2A,$8E,$25,  0,$FE
TUNE4_SQ2:  .DB $9C,  0,$87,$1D,$95,  0,$B8,  0,$9C,  0,$87,$1D,$95,  0,$B8,  0
        .DB $9C,  0,$87,$1B,$95,  0,$B8,  0,$9C,  0,$87,$1B,$95,  0,$B8,  0
        .DB $FE
TUNE3_SQ1:  .DB $87,$27,$27,$33,$27,$F9,$8E,$2A,$F8,$87,$2E,$30,$F9,$8E,$31,$31
        .DB $F8,$30,  0,$87,$25,$25,$31,$25,$F9,$8E,$29,$F8,$87,$2C,$2E,$F9
        .DB $8E,$2F,$F8,$87,$2E,$2F,$25,$24,$F9,$8E,$25,$F8,$87,$22,$22,$2E
        .DB $22,$F9,$8E,$2C,$F8,$87,$2B,$2C,$F9,$8E,$22,$2E,$F8,$22,  0,$87
        .DB $22,$22,$2E,$22,$F9,$8E,$2C,$F8,$87,$2B,$2C,$F9,$8E,$22,$2E,$F8
        .DB $87,$22,$22,$24,$26,$FE

DEMO_KEYDATA:   .DB $3D,  1,  3,$81,  3,$80,$1B,  4,  6,$84,$1B,  4,  2,  5,$34,  1,  8,$41,$13,  1
        .DB   1,  0,  6,  1,  1,  0, $F,  1,  1,  0,  3,  1,  1,  0,$11,  1,  6,$81,$1B,  1
        .DB   3,$81, $E,  1,$1A,  0,$11,  1,  5,$81,$16,  1,  2,  0,  1,  1,$11,  4,$10,  0
        .DB $10,$40,$10,  0,  2,  4,  1,  0,  1,  4,  1,  0, $E,  4,  1,  0,  2,  4,  1,  0
        .DB   1,  4,$38,  0,$1A,  4,  3,  0,  4,  2,  1,  0,  4,$80,  9,  0,$16,  2,  2,  0
        .DB   2,  4,  5,  2,  1,  0,$15,  4,$3A,  0, $A,$40,$17,  0, $D,  4,  2,  0,  6,$80
        .DB   6,  0,$1D,  8,  1,  0, $C,  1,  2,  0,  9,$40, $A,  0,$28,  2,  1,  0,$20,  2
        .DB $1E,  4,  2,$84,  5,$80,$5D,  1,  6,  0,$1D,  2,$21,  8,  4,  0,  6,$80,  3,  0
        .DB $1A,  2,  2,  0, $F,  8,  2,  0,  9,$40,  8,  0,  8,$40,$14,  0, $F,  8,  1,  0
        .DB  $D,  8,  1,  0,  1,  8,  1,  0,$11,  8,  2,  0,$1E,  1,  6,$81,$15,  1,  5,$81
        .DB $19,  1,  6,$81,  6,  0,$1C,  4,  6,$84,  1,$81,  1,  1,  3,  0,$1B,  1,  1,  0
        .DB  $E,  8,  1,$48,  8,$40,$17,  0, $D,  4,  1,$84,  6,$80,  2,  0,$1E,  2,  4,$82
        .DB   1,$80,  1,  0,$1F,  4,  5,$84,$1E,  4,  4,$84,  2,$80,$1C,  2,  2,  0, $F,  8
        .DB   1,  0,  9,$40,$11,  0, $F,  4,  1,  5,  1,  0,  4,  1,  9,$81,$14,  1,  6,$81
        .DB $19,  1,  1,  0, $E,  8,  3,$48,  1,  0,  6,$40,$14,  0,  6,$80,  2,$88,  4,  8
        .DB   1,  0,  8,  8,  1,  0,  3,  8,  2,$88,  1,  0,  2,$88,  1,  0,$14,  8,  5,$88
        .DB   4,  8,  2,  0,$1B,  1,  7,$81,$18,  1,  6,$81,$15,  1,  2,  9,$10,  8, $A,$40
        .DB $1A,  0, $A,  4,  1,  0,  6,  4,  1,  0,$1E,  2,  6,  0,$10,  8,  3,$84,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .DB $FF,$FF,$FF,$FF,$FF,$FF

    .ORG $F000
    .INCLUDE "BOOM.asm"


DUMMY:      .DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ---------------------------------------------------------------------------

IRQ:                    
        RTI
; ---------------------------------------------------------------------------
        .DW NMI
        .DW RESET
        .DW IRQ

		.INCBIN "assets/BOMBER.CHR"
