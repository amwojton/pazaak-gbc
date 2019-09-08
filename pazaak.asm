;*
;* The pazaak minigame from Star Wars: Knights of the Old Republic, recreated for the Game Boy Color.
;*

include "gbhw.inc"

_SPR0_Y   equ _OAMRAM
_SPR0_X   equ _OAMRAM+1
_SPR0_NUM equ _OAMRAM+2
_SPR0_ATT equ _OAMRAM+3
_PAD      equ _RAM

section "start", rom0[$0100]
    nop
    jp  start

    ROM_HEADER ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

;***************************************************************************
;*
;* Program loops
;*
;***************************************************************************

start:
    nop
    di
    ld sp, $ffff  ; Aim pile at top of ram

initialization:
    ; Palette colors from darkest to lightest (11 10 01 00)
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a

    ; Create another palette for the palette 2 sprites, as an inverse of the first
    ld a, %00011011
    ld [rOBP1], a

    ; Visible screen at beginning (top left) of fund
    ld a, 0
    ld [rSCX], a
    ld [rSCY], a

    call turn_off_lcd

    ld hl, Tiles
    ld de, _VRAM
    ld b, 32  ; Number of bytes to copy (2 tiles)

.load_data:
    ld  a,[hl]   ; hl is read direction
    ld  [de], a  ; de is write direction
    dec b
    jr  z, .clean_bg
    inc hl
    inc de
    jr  .load_data

.clean_bg:
    ld hl, _SCRN0
    ld de, 32*32  ; Number of tiles on the background map

.copy_bg:
    ; Tile 0 is the empty tile
    ld  a, 0
    ld  [hl], a
    dec de
    ld  a, d
    or  e
    jp  z, .clean_sprites
    inc hl
    jp  .copy_bg

.clean_sprites
    ld hl, _OAMRAM
    ld de, 40*4  ; 40 sprites x 4 bytes each

.copy_sprites
    ; Unused sprites will be offscreen
    ld  a, 0
    dec de
    ld  a, d
    or  e
    jp  z, .create_sprites
    inc hl
    jp  .copy_sprites

.create_sprites
    ld a, 16
    ld [_SPR0_Y], a
    ld a, 8
    ld [_SPR0_X], a
    ld a, 1
    ld [_SPR0_NUM], a  ; Tile number from the table
    ld a, 0
    ld [_SPR0_ATT], a  ; Special attributes (none for now)

    ; Configure and activate the display
    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld [rLCDC], a

main_program_loop:
    call read_pad

; Changing vram outside of vblank causes Very Bad Things, so wait for it
.wait:
    ld a, [rLY]
    cp 145
    jr nz, .wait

    ; Control pad down
    ld   a, [_PAD]
    and  %10000000
    call nz, move_down

    ; Control pad up
    ld   a, [_PAD]
    and  %01000000
    call nz, move_up

    ; Control pad left
    ld   a, [_PAD]
    and  %00100000
    call nz, move_left

    ; Control pad right
    ld   a, [_PAD]
    and  %00010000
    call nz, move_right

    ; A button
    ld   a, [_PAD]
    and  %00000001
    call nz, change_palette

    call time_delay
    jr   main_program_loop

;***************************************************************************
;*
;* Helper routines
;*
;***************************************************************************

turn_off_lcd:
    ld   a, [rLCDC]
    rlca
    ret  nc  ; Display is already off

.wait_for_vblank
    ld a, [rLY]
    cp 145
    jr nz, .wait_for_vblank

    ; Currently in vblank, so turn off LCD
    ld  a, [rLCDC]
    res 7, a
    ld  [rLCDC], a
    ret

read_pad:
    ; Bit 4 to 0, bit 5 to 1 (control pad only)
    ld a, %00100000
    ld [rP1], a

    ; Read control pad several times to avoid bouncing
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]

    ; Only care about the bottom 4 bits
    and  $0F
    swap a
    ld   b, a

    ; Bit 4 to 1, bit 5 to 0 (buttons only)
    ld a, %00010000
    ld [rP1], a

    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]

    and $0F

    ; Combine control pad and buttons and take complement
    or  b
    cpl
    ld  [_PAD], a
    ret

move_down:
    ld  a, [_SPR0_Y]
    cp  152             
    ret z  ; Already at bottom edge of screen
    add a, 8
    ld  [_SPR0_Y], a
    ret

move_up:
    ld  a, [_SPR0_Y]
    cp  16
    ret z  ; Already at top edge of screen
    sub 8
    ld  [_SPR0_Y], a
    ret

move_left:
    ld  a, [_SPR0_X]
    cp  8
    ret z  ; Already at left edge of screen
    sub 8
    ld  [_SPR0_X], a
    ret

move_right:
    ld  a, [_SPR0_X]
    cp  160
    ret z  ; Already at right edge of screen
    add a, 8
    ld  [_SPR0_X], a
    ret

change_palette:
    ld  a, [_SPR0_ATT]
    and %00010000     ; Bit 4 is the number of the palette
    jr  z, .palette0  ; Palette 0 was selected

    ; Else palette 1 was selected
    ld  a, [_SPR0_ATT]
    res 4, a  ; Zero bit 4, selecting palette 0
    ld  [_SPR0_ATT], a
    call time_delay
    ret

.palette0:
    ld  a, [_SPR0_ATT]
    set 4, a  ; Set bit 4, selecting palette 1
    ld  [_SPR0_ATT], a
    call time_delay
    ret

time_delay:
    ld de, 6000

.loop:
    dec de
    ld  a, d
    or  e
    jr  z, .exit_loop
    nop
    jr  .loop

.exit_loop:
    ret

;***************************************************************************
;*
;* Tiles
;*
;***************************************************************************

Tiles:
    ; Background
    db  $FF, $00, $81, $00, $81, $00, $81, $00
    db  $81, $00, $81, $00, $81, $00, $FF, $00

    ; Cursor
    db  $00, $00, $7E, $7E, $7E, $7E, $7E, $7E
    db  $7E, $7E, $7E, $7E, $7E, $7E, $00, $00
EndTiles:
