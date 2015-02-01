#include <p16f684.inc>

RED equ 2
GREEN equ 0
BLUE equ 1

    UDATA
; set these values to intensity wanted; 0 = off, 1 = 1/255 on, 255 = always on
red RES 1
green RES 1
blue RES 1

; current pwm tick
pwmtick RES 1
out RES 1

reset_vector CODE 0x00
    goto boot

interrupt_vector CODE 0x04
    retfie

    CODE
boot
init
    clrf red
    clrf green
    clrf blue

; 75% red
    movlw 0xC8
    movwf red

    clrf pwmtick

loop
; if pwmtick == 0: pwmtick -= 1; because 255 means full on
    movfw pwmtick
    btfsc STATUS, Z
    decf pwmtick, f

    decf pwmtick, f
    clrf out

; if pwmtick < red: out |= RED
    movfw red
    subwf pwmtick, w
    skpc
    bsf out, RED

; green
    movfw green
    subwf pwmtick, w
    skpc
    bsf out, GREEN

; blue
    movfw blue
    subwf pwmtick, w
    skpc
    bsf out, BLUE

; copy out to GPIO
    movfw out
    movwf PORTA
    goto loop

    END
