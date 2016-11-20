.word $0801
.org  $0801

.scope

	.word _next, 10
	.byte $9e," 2062",0

_next:
	.word 0

.scend

.advance 2062

.alias USB_ID          $de08
.alias USB_STATUS      $de09
.alias USB_DATA        $de0a

.alias LAST_LINE       $07c0
.alias LAST_LINE_COLOR $dbc0

get_from_usb:

    lda $20
    sta $0798

    lda $21
    sta $0799

    lda current_state
    sta $079b

    bit USB_STATUS
    bpl get_from_usb

    lda USB_DATA
    sta the_data

; debug line
    ldx current_dbg_char
    sta LAST_LINE, x

    lda current_dbg_color
    sta LAST_LINE_COLOR, x

    inx

    stx current_dbg_char
    cpx #40
    bne +

    ldx #0
    stx current_dbg_char
    ldx current_dbg_color
    inx
    stx current_dbg_color

; end debug line

*

    lda current_state
    cmp #$00
    bne +
        ldx the_data
        stx $20
        ldx #$01
        stx current_state
        jmp continue
    *

    cmp #$01
    bne +
        ldx the_data
        stx $21
        ldx #$02
        stx current_state    
        jmp continue
    *

    cmp #$02
    bne +
        lda the_data
        ldy #$00
        sta ($20),y
        sty current_state
        jmp continue
    *

continue:
    jmp get_from_usb

the_data:          .byte 0
current_dbg_char:  .byte 0
current_dbg_color: .byte 0
current_state:     .byte 0
