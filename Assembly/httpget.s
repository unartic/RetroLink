;This demo lets you connect to a wifi network and fetch an url. 
;The first 10kb of the result is printed to the screen, filtering out html tags.

;Kernal routines
CHROUT              := $FFD2
SCREEN_SET_CHARSET  := $FF62

.segment "ONCE"
.segment "ZEROPAGE"
    ptr:    .res 2
    ptr2:   .res 2
.segment "DATA"
    ;Wifinetwork to connect to. Fill in your own ssid and password
    wifi_ssid:          .literal "BR53",$0
    wifi_pw:            .literal "hp99plbnx",$0

    ;Buffer to store http-get result in
    result_buffer:        .res 1024*20  ;10kb
    result_buffer_end: 

    ;Url to fetch. Change as you please.
    url:                .literal "https://nxtbasic.com/",$0
    in_html_tag_flag:   .res 1
   
    ;Some text
    txt_connecting:     .literal "Connecting to wifi...",$0
    txt_connected:      .literal "Wifi connected.",$0   
    txt_fetching:       .literal "Fetching ",$0  
    txt_notfound:       .literal "RetroLink NOT found!",$0   
    txt_found:          .literal "RetroLink found!",$0  
    txt_version:        .literal "Version: ",$0  
.segment "CODE"

jmp start
.include "inc/i2c-driver.s"     ;i2c driver
.include "inc/retrolink.s"      ;retrolink specifics

.include "inc/debug.s" 
 
start:
    jsr to_iso      ;we will operate in ISO-mode
    
    jsr find_retro_link
    bcc retrolink_found
        ldx #<txt_notfound
        ldy #>txt_notfound
        jsr print
        jsr lf
        jsr lf
        rts    
    
    retrolink_found:
    ldx #<txt_found
    ldy #>txt_found
    jsr print
    jsr lf
    jsr lf    
    
    ldx #<txt_version
    ldy #>txt_version
    jsr print

    lda #I2C_SLAVE
    ldx #REG_ESP_MAJOR 
    jsr i2c_read_register    
    jsr CHROUT
    lda #'.'
    jsr CHROUT
    lda #I2C_SLAVE
    ldx #REG_ESP_MINOR
    jsr i2c_read_register    
    jsr CHROUT
    jsr lf
    jsr lf
    
    ;Print message 'Connecting to wifi...'
    ldx #<txt_connecting
    ldy #>txt_connecting
    jsr print
    jsr lf
    jsr wait_a_bit     ;we are delaying so we can see the message
    
    ;Tell RetroLink to connect to wifi
    jsr connect_wifi
    
    ;Print message 'Wifi connected.'
    ldx #<txt_connected
    ldy #>txt_connected
    jsr print
    jsr lf
    jsr wait_a_bit     ;we are delaying so we can see the message
    
    ;Print message 'Fetching....."
    ldx #<txt_fetching
    ldy #>txt_fetching
    jsr print
    ldx #<url
    ldy #>url
    jsr print    
    jsr lf
    jsr wait_a_bit     ;we are delaying so we can see the message
    
    ;Perform http-get
    ldx #<url
    ldy #>url
    jsr http_get       ;get first 10kb of http response
    

    ;Read http get response
    ;Address to store response in ptr. Make sure it is large enough as read_http_response will keep reading 
    lda #<result_buffer
    sta ptr
    lda #>result_buffer
    sta ptr+1
    jsr read_http_response_to_mem
    
    lda ptr
    sta ptr2
    lda ptr+1
    sta ptr2+1
    
  
    
    ;Print http response, we filter out html a bit in a rudumentary way
    lda #<result_buffer
    sta ptr
    lda #>result_buffer
    sta ptr+1
    
    stz in_html_tag_flag    ;0=we are not in html tag, 1=we are in html tag
    print_loop:
        lda (ptr)
        beq at_end_of_buffer
        cmp #'<'
        beq html_toggle
        cmp #'>'
        beq html_toggle
             
        ;Check if we are in html-tag
        ldx in_html_tag_flag
        bne do_not_print
        
        jsr CHROUT
        do_not_print:
        
        ;increment ptr
        inc ptr
        bne :+
        inc ptr+1
        :
        
        lda ptr
        cmp ptr2
        bne print_loop
        lda ptr+1
        cmp ptr2+1
        bne print_loop
        
        

    at_end_of_buffer:
    jsr lf
    jsr lf
rts

html_toggle:
    ;toggle between 0 and 1
    lda in_html_tag_flag
    eor #$01
    sta in_html_tag_flag
    
    ;increment ptr
    inc ptr
    bne :+
    inc ptr+1
    :
    
    jmp print_loop


    

to_iso:
    clc
    lda #6
    jsr SCREEN_SET_CHARSET 
    
    ;Switch to ISO
    lda #$0F
    jsr CHROUT
    rts
    

;x/y pointer to text
print:
    stx ptr2
    sty ptr2+1
    ldy #0
    :
        lda (ptr2),y
        beq :+
        jsr CHROUT
        iny
        bra :-
    :
    rts
    
lf:
    lda #$0d
    jsr CHROUT
    rts
    
wait_a_bit:
    ldx #0
    :
        ldy #0
        :
            .repeat 10
            pha
            pla
            .endrepeat
            iny
            bne :-
        inx
        bne :--
 

    rts