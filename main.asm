#include <p16f684.inc>

; communicate with dioder using pulse lengths
; setup serial as 9600 8N1, and connect host tx to pin4 (RA3/MCLR/Vpp)
; sending SD0 1D0 1D0 bits over serial: start, data1, 0, 1, data2, 0, 1, data3, 0, stop
; which is in host bits                  ....,     0, 1, 2,     3, 4, 5,     6, 7, ...

;          stop_7D5_4D2_1D_start
; to send zero: 001_001_00 = 36
; to send 7:    011_011_01 = 109 (36 + 1 + 8 + 64)

; when receiving a single bit, the dioder right shifts it into red,green,blue
; the first bit received is reds most significant bit

PULSE_IN equ RA3 ; pin4, host rx, 9600 8N1
RED equ 2        ; pin11
GREEN equ 0      ; pin13
BLUE equ 1       ; pin12

    PAGE
; MCLRE_OFF
    __CONFIG _FCMEN_OFF & _IESO_OFF & _BOD_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT

    UDATA

W_TEMP RES 1
STATUS_TEMP RES 1

; rgb data to actually display
red RES 1
green RES 1
blue RES 1

; pwm counter
pwmtick RES 1
out RES 1

; pulse counter, short pulse = 0, long pulse = 1. Short pulse = 26 timer1 ticks with max prescaler
SHORT_PULSE_MAX equ 0xd9 ; 26 * 1.5 in -hex (-39 turns into something weird)
LONG_PULSE_MAX equ 0xbf ; 26 * 2.5 in -hex

; pulse data
in_count RES 1 ; counts bits received, at 3 * 8 will copy the 3 colors
in_red RES 1
in_green RES 1
in_blue RES 1

reset_vector CODE 0x00
    goto main

interrupt_vector CODE 0x04
; save state
    movwf W_TEMP
    swapf STATUS, w
    movwf STATUS_TEMP

; check input hi/lo
    btfss PORTA, PULSE_IN
    goto is_clear

is_set
; reset timer1, and switch it on, 8MHz / 4 / 8 = 250 KHz = 26 incs @ 9600 baud
    clrf TMR1H
    clrf TMR1L
    bsf T1CON, TMR1ON
    goto exit_isr

is_clear
; stop timer
    bcf T1CON, TMR1ON
; shift input
    bcf STATUS, C
    rlf in_blue, f
    rlf in_green, f
    rlf in_red, f
    movf TMR1L, w ; if timer >= SHORT: blue |= 1
    addlw SHORT_PULSE_MAX
    btfss STATUS, C
    goto post_pulse
; long pulse
    bsf in_blue, 0
post_pulse
    decfsz in_count, f ; if --in_count == 0: red = in_red; green = in_green; blue = in_blue
    goto exit_isr
; copy received values in and restart
    movf in_red, w
    movwf red
    movf in_green, w
    movwf green
    movf in_blue, w
    movwf blue
    movlw 0x18 ; 24
    movwf in_count

exit_isr
; restore state
    swapf STATUS_TEMP, w
    movwf STATUS
    swapf W_TEMP, f
    swapf W_TEMP, w
    retfie

main
; setup PORTA, only one input, RA3
    bcf STATUS, RP0 ; bank 0
    clrf PORTA
    movlw 0x07
    movfw CMCON0
    bsf STATUS, RP0 ; bank 1
    clrf ANSEL ; set porta all digital
    movlw b'00001000'
    movwf TRISA ; porta input/output
    movlw b'00001000'
    movwf IOCA  ; ra0 interrupt on change
    bcf STATUS, RP0 ; bank 0

; in_count = 24
    movlw 0x18 ; 24
    movwf in_count

; setup timer
    bcf T1CON, TMR1CS
    bsf T1CON, T1CKPS0
    bsf T1CON, T1CKPS1

; setup interrupt on porta change
    movlw b'11001000'
    movwf INTCON

; without interrupts this should run pwm at 390 Hz
; while receiving at 9600 baud constantly, will drop to around 340 Hz (= 9600 * 2 interrupts)
; but we expect 30 color updates per second = 30 * 24 * 2 = 1440 interupts
mainloop
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

; copy out to PORTA
    movfw out
    movwf PORTA
    goto mainloop
    END
