;*
;* Messing around
;*
; Based on this tutorial: http://wiki.ladecadence.net/doku.php?id=tutorial_de_ensamblador

INCLUDE "gbhw.inc"           ; Import file definitions

; Define sprite constants
_SPR0_Y   EQU _OAMRAM        ; Sprite Y 0 is the beginning of the sprite mem
_SPR0_X   EQU _OAMRAM+1
_SPR0_NUM EQU _OAMRAM+2
_SPR0_ATT EQU _OAMRAM+3

; Variable to save the state of the pad
_PAD EQU _RAM                ; At the beginning of the internal RAM

; The program begins here:
SECTION "start",ROM0[$0100]
    nop
    jp start

    ; Head of the ROM (Macro defined in gbhw.inc)
    ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

;***************************************************************************
;*
;* Program loops
;*
;***************************************************************************

; Actual start of program
start:
    nop
    di                       ; Disable interrupts
    ld sp, $ffff             ; We aim pile atop the ram

initialization:
    ld a, %11100100          ; Palette colors from the darkest to lighter, 11 10 01 00
    ld [rBGP], a             ; We write this in the background palette register
    ld [rOBP0], a            ; and sprite palette 0

    ; Create another palette to the palette 2 sprites, reverse to normal
    ld a, %00011011
    ld [rOBP1], a

    ld a, 0                  ; write 0 records scroll in X and Y
    ld [rSCX], a             ; positioned so that the visible screen
    ld [rSCY], a             ; at the beginning (upper left) of the fund.

    call turn_off_lcd        ; We call the routine that turns off the LCD

    ; We load the tiles in memory of tiles
    ld hl, Tiles             ; HL loaded in the direction of our tile
    ld de, _VRAM             ; address in the video memory
    ld b, 32                 ; b = 32, number of bytes to copy (2 tiles)

.loop_load:
    ld  a,[hl]               ; load in the data pointed to by HL
    ld  [de], a              ; and we put in the address pointed in DE
    dec b                    ; decrement b, b = b-1
    jr  z, .fin_loop_load    ; if b = 0, finished, nothing left to copy
    inc hl                   ; We increased the read direction
    inc de                   ; We increased the write direction
    jr  .loop_load           ; we follow

.fin_loop_load:
    ;  We clean the screen (fill entire background map), with tile 0
    ld hl, _SCRN0
    ld de, 32*32             ; number of tiles on the background map

.loop_clean_bg:
    ld  a, 0                 ; tile 0 is our empty tile
    ld  [hl], a
    dec de

    ; Now I have to check if it is zero, to see if I have it
    ; finishes copying. dec not modify any flag, so I can not
    ; check the zero flag directly, but that is zero, dye
    ; They must be zero two, so I can make or including
    ; and if the result is zero, both are zero.
    ld  a, d                  ; d loaded in to
    or  e                     ; and make a or e
    jp  z, .fin_loop_clean_bg ; if d or e is zero, it is zero.
    inc hl                    ; We increased the write direction
    jp  .loop_clean_bg

.fin_loop_clean_bg
    ; Well, we have all the map tiles filled with tile 0
    ; We clean the memory of sprites
    ld hl, _OAMRAM           ; sprite attribute memory
    ld de, 40*4              ; 40 sprites x 4 bytes each

.loop_clean_sprites
    ld  a, 0                 ; we will start fresh, so the sprites
    ld  [hl], a              ; unused, will be offscreen
    dec de

    ; As in previous loop
    ld  a, d                       ; d loaded in to a
    or  e                          ; and make a or e
    jp  z, .fin_loop_clean_sprites ; if d or e is zero, it is zero.
    inc hl                         ; We increased the write direction
    jp  .loop_clean_sprites

.fin_loop_clean_sprites
    ; Now we will create the sprite.
    ld a, 16
    ld [_SPR0_Y], a          ; Y position of the sprite
    ld a, 8
    ld [_SPR0_X], a          ; X position of the sprite
    ld a, 1
    ld [_SPR0_NUM], a        ; number of tile on the table that we will use tiles
    ld a, 0
    ld [_SPR0_ATT], a        ; special attributes, so far nothing.

    ; Configure and activate the display
    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld [rLCDC], a

; Main loop
movement:
    ; We read the pad
    call read_pad
    ; first, we wait for the VBlank, since we can not change
    ; VRAM out of it, or weird things will happen

.wait:
    ld a, [rLY]
    cp 145
    jr nz, .wait

    ; Perform an action based on which button was pressed
    ld   a, [_PAD]           ; We charge status pad
    and  %00010000           ; Control pad right
    call nz, move_right      ; if the result is not zero, there had 1

    ld   a, [_PAD]
    and  %00100000           ; Control pad left
    call nz, move_left

    ld   a, [_PAD]
    and  %01000000           ; Control pad up
    call nz, move_up

    ld   a, [_PAD]
    and  %10000000           ; Control pad down
    call nz, move_down

    ld   a, [_PAD]
    and  %00000001           ; A button
    call nz, change_palette

    ; Small delay
    call time_delay

    ; We start
    jr movement


;***************************************************************************
;*
;* Movement routines
;*
;***************************************************************************

; Move right
move_right:
    ld      a,  [_SPR0_X]   ; Get current x-coordinate
    cp      160             ; Sprite on the right edge?
    ret     z               ; If on the edge, return

    add     a, 8            ; Move x-coordinate right
    ld      [_SPR0_X], a    ; Save x-coordinate

    ret

; Move left
move_left:
    ld      a,  [_SPR0_X]   ; Get current x-coordinate
    cp      8               ; Sprite on the left edge?
    ret     z               ; If on the edge, return

    sub     8               ; Move x-coordinate right
    ld      [_SPR0_X], a    ; Save x-coordinate

    ret

; Move up
move_up:
    ld      a,  [_SPR0_Y]   ; Get current y-coordinate
    cp      16              ; Sprite on the top edge?
    ret     z               ; If on the edge, return

    sub     8               ; Move y-coordinate up
    ld      [_SPR0_Y], a    ; Save y-coordinate

    ret

; Move down
move_down:
    ld      a,  [_SPR0_Y]   ; Get current y-coordinate
    cp      152             ; Sprite on bottom edge?
    ret     z               ; If on the edge, return

    add     a, 8            ; Move y-coordinate down
    ld      [_SPR0_Y], a    ; Save y-coordinate

    ret

;***************************************************************************
;*
;* Controls
;*
;***************************************************************************

; Change palette
change_palette:
    ld      a, [_SPR0_ATT]
    and     %00010000       ; in bit 4, is the number of palette
    jr      z, .palette0    ; If zero was selected palette 0

    ; if not, was selected blade 1
    ld      a, [_SPR0_ATT]
    res     4, a            ; we zero bit 4, selecting the palette 0
    ld      [_SPR0_ATT], a  ; We keep attributes

    call    time_delay      ; the change is very fast, we will wait a bit
    ret                     ; return
.palette0:
    ld      a, [_SPR0_ATT]
    set     4, a            ; We put one bit 4, selecting blade 1
    ld      [_SPR0_ATT], a  ; We keep attributes

    call    time_delay
    ret                     ; return

; Read the control pad
read_pad:
    ld      a, %00100000    ; bit 4-0, 5-1 bit (on control pad, no buttons)
    ld      [rP1], a

    ; now we read the status of the control pad, to avoid bouncing
    ; We do several readings
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]

    and     $0F             ; only care about the bottom 4 bits.
    swap    a               ; lower and upper exchange.
    ld      b, a            ; We keep control pad status in b

    ; we go for the buttons
    ld      a, %00010000    ; bit 4 to 1, bit 5 to 0 (enabled buttons, not control pad)
    ld      [rP1], a

    ; read several times to avoid bouncing
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]
    ld      a, [rP1]

    ; we at A, the state of the buttons
    and     $0F             ; only care about the bottom 4 bit
    or      b               ; or make a to b, to "meter" in Part
                            ; A superior, control pad status.

    ; we now have at A, the state of all, we complement and
    ; store it in the variable
    cpl
    ld      [_PAD], a

    ret

; LCD shutdown routine
turn_off_lcd:
    ld   a, [rLCDC]
    rlca                     ; Sets the high bit of LCDC in the carry flag
    ret  nc                  ; Display is already off, again

; Display can only be turned off in VBlank
.wait_for_vblank
    ld a, [rLY]
    cp 145
    jr nz, .wait_for_vblank

    ; Currently in VBlank, so turn off LCD
    ld  a, [rLCDC]           ; Load contents of LCDC into a
    res 7, a                 ; Reset bit 7
    ld  [rLCDC], a           ; Write contents of a into LCDC register

    ret

; rdelay routine
time_delay:
    ld      de, 6000        ; number of times to execute the loop
.delay:
    dec     de              ; decrement
    ld      a, d            ; see if zero
    or      e
    jr      z, .fin_delay
    nop
    jr      .delay
.fin_delay:
    ret

;***************************************************************************
;*
;* Tiles
;*
;***************************************************************************

Tiles:
    ; Background
    DB  $FF, $00, $81, $00, $81, $00, $81, $00
    DB  $81, $00, $81, $00, $81, $00, $FF, $00

    ; Cursor
    DB  $00, $00, $7E, $7E, $7E, $7E, $7E, $7E
    DB  $7E, $7E, $7E, $7E, $7E, $7E, $00, $00
EndTiles: