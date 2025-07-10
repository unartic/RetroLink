;i2c slave registers of RetroLink
REG_ESP_MAJOR       = $00
REG_ESP_MINOR       = $01
REG_WIFI_SSID       = $02 
REG_WIFI_PASSWORD   = $03 
REG_WIFI_STATUS     = $04 
REG_HTTP_GET        = $10 
REG_HTTP_STATE      = $11
REG_HTTP_RESPONSE   = $12
REG_HTTP_LEFT       = $13

BLOCK_SIZE = 120
    
I2C_SLAVE = $50       ;RetroLink is device $50 on the i2c bus

http_bytes_left:    .res 4      ;32bit value to store length of http response
retrolink_tmp:      .res 1


;Checks if device $50 is present
;carry set      -> not present
;carry clear -> present
find_retro_link:
    jsr i2c_start_condition
    lda #I2C_SLAVE
    asl
    jsr i2c_send_byte    ;send slave number
    php
    jsr i2c_stop_condition
    plp
    rts

;------------------------------------------------------------------
; In:
;    - wifi_ssid    -> null terminated ssid
;    - wifi_pw      -> null terminated password
; Out: 
;   Nothing
;
; TODO: set timeout and use carry to return if succesful
;------------------------------------------------------------------
connect_wifi:
    ;we want the kernal to leave the i2c bus alone
    sei     
        ;we send the wifi-ssid to the RetroLink
        ldx #<wifi_ssid
        ldy #>wifi_ssid
        lda #REG_WIFI_SSID
        jsr send_i2c_stream     

        ;we send the password to the RetroLink
        ldx #<wifi_pw
        ldy #>wifi_pw
        lda #REG_WIFI_PASSWORD
        jsr send_i2c_stream     

        ;After sending the password the Retrolink will automaticly connect to 
        ;the wifi network
        
        ;wait until connected
        wifi_wait_loop:
            ;Get wifi-state: 0=not connected, 1=connected
            lda #I2C_SLAVE
            ldx #REG_WIFI_STATUS 
            jsr i2c_read_register
            
            jsr i2c_delay   ;we might want to add some more delay
            beq wifi_wait_loop            
    cli
    rts

;------------------------------------------------------------------
; In:
;    - x/y          -> pointer to null terminated url
; Out: 
;   Nothing
;
; TODO: set timeout and use carry to return if succesful
;------------------------------------------------------------------
http_get:
    ;we want the kernal to leave the i2c bus alone
    sei
        ;send url in x/y to RetroLink
        lda #REG_HTTP_GET
        jsr send_i2c_stream
        
        ;wait for http-get to finish
        wait_http_get:
            ;pass a bit of time so we don't overload the RetroLink
            ldx #10
            :
                jsr i2c_delay
                dex
                bne :-
      
            ;Read http-status (0=idle, 1=data ready, 2=busy)            
            lda #I2C_SLAVE
            ldx #REG_HTTP_STATE 
            jsr i2c_read_register
            cmp #$01
            bne wait_http_get
    cli
    jsr http_get_response_length
    rts

; Reads the length of the http response
http_get_response_length:
    lda #<http_bytes_left
    sta ptr
    lda #>http_bytes_left
    sta ptr+1
    
    sei
    lda #I2C_SLAVE
    ldx #REG_HTTP_LEFT
    ldy #4
    jsr read_i2c_stream_by_len
    cli
    rts


;------------------------------------------------------------------
; In:
;    - ptr          -> pointer to addres to store result in
; Out: 
;   Nothing
;------------------------------------------------------------------
read_http_response:
    sei

        ;due to the wire lib blocksize is limited.
        read_next_block:
        
        ldy #BLOCK_SIZE             ;Retrolink will send 120byte blocks
        
        ;Check if next block is 120bytes or larger
        lda http_bytes_left+3
        bne not_less_then_block_size
        lda http_bytes_left+2
        bne not_less_then_block_size    
        lda http_bytes_left+1
        bne not_less_then_block_size       
        lda http_bytes_left
        cmp #(BLOCK_SIZE+1)
        bcs not_less_then_block_size
        ldy http_bytes_left
        not_less_then_block_size:

        sty retrolink_tmp       ;the blocksize of the next block
        
        lda #I2C_SLAVE
        ldx #REG_HTTP_RESPONSE
        jsr read_i2c_stream_by_len      ;read up to 120 bytes (y=number of bytes)
        
        ;Decrement bytes left to read with block read size
        sec
        lda http_bytes_left
        sbc retrolink_tmp
        sta http_bytes_left
        lda http_bytes_left+1
        sbc #0
        sta http_bytes_left+1
        lda http_bytes_left+2
        sbc #0
        sta http_bytes_left+2
        lda http_bytes_left+3
        sbc #0
        sta http_bytes_left+3
        
    
        ;check if we have read all bytes
        lda http_bytes_left
        ora http_bytes_left+1
        ora http_bytes_left+2
        ora http_bytes_left+3
        bne read_next_block
        
        ;end with $00
        lda #0
        sta (ptr)
    
    
    cli


    rts