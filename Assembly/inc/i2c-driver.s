


.segment "CODE"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    VIA_DDRA    = $9F03            ;0=input, 1=output
    VIA_ORA     = $9F0F     
    VIA_IRA     = $9F01

    I2C_SDA     = %00000001
    I2C_SCL     = %00000010

    I2C_WRITE   = %00000000
    I2C_READ    = %00000001


  

        i2c_byte:   .res 1
        i2c_tmp:    .res 1
        i2c_tmp2:   .res 1
        i2c_tmp3:   .res 1

        
    .macro SDA_LOW
        lda VIA_DDRA
        ora #I2C_SDA
        sta VIA_DDRA
    .endmacro    
    .macro SDA_HIGH
        lda VIA_DDRA
        and #(I2C_SDA^$FF)
        sta VIA_DDRA
    .endmacro   

    .macro SCL_LOW
        lda VIA_DDRA
        ora #I2C_SCL
        sta VIA_DDRA
    .endmacro  

    .macro SCL_HIGH
        lda VIA_DDRA
        and #(I2C_SCL^$FF)
        sta VIA_DDRA
        :
        lda VIA_IRA
        and #I2C_SCL
        beq :-
    .endmacro  


    i2c_start_condition:
        ;make sure the output register for SDA and SCL are LOW, so changing DDRA takes care of the effect
        lda #%00000011
        trb VIA_ORA

        SDA_HIGH
        SCL_HIGH

        jsr i2c_wait_for_idle_bus
        
        SDA_LOW
        jsr i2c_delay
        SCL_LOW
        rts

    ;A contains byte to send, Returns: C=0=ACK C=1=NACK
    i2c_send_byte: 
        ldx #0
        i2c_send_byte_loop:
            asl A
            bcc i2c_send_low
            bra i2c_send_high
            i2c_continue_send_byte:
            inx
            cpx #8
            bne i2c_send_byte_loop
            jsr i2c_read_bit
        rts

    i2c_read_bit:
        SDA_HIGH
        jsr i2c_delay    
        SCL_HIGH
        jsr i2c_delay
                    
        lda VIA_IRA
        and #I2C_SDA            
        pha
        SCL_LOW
        pla
        lsr
        rts
        
    i2c_send_low:
        jsr i2c_send_low_jsr
        bra i2c_continue_send_byte

    i2c_send_low_jsr:
        pha
        SDA_LOW
        jsr i2c_pulse_clock
        pla        

        rts

    i2c_send_high:
        jsr i2c_send_high_jsr
        bra i2c_continue_send_byte

    i2c_send_high_jsr:
        pha
        SDA_HIGH
        jsr i2c_pulse_clock           
        pla
        rts

    ;reads byt with NACK
    i2c_read_byte:
        ldx #0
        :
            jsr i2c_read_bit
            rol i2c_byte
            inx
            cpx #8
            bne :-
        jsr i2c_send_high_jsr    ;send NACK NACK should be the send if it is last byte read, ele ACK should be send
        lda i2c_byte   
        rts

    i2c_read_byte_with_ack:
        ldx #0
        :
            jsr i2c_read_bit
            rol i2c_byte
            inx
            cpx #8
            bne :-
        jsr i2c_send_low_jsr    ;send NACK NACK should be the send if it is last byte read, ele ACK should be send
        lda i2c_byte   
        rts

    i2c_stop_condition:
        pha
        SDA_LOW
        jsr i2c_delay
        SCL_HIGH
        jsr i2c_delay
        SDA_HIGH
        jsr i2c_delay
        pla
        rts

    i2c_pulse_clock:
        SCL_HIGH
        jsr i2c_delay
        SCL_LOW
        jsr i2c_delay
        rts

    i2c_delay:
        .repeat 2
        pha
        pla
        .endrepeat
        rts
        
    i2c_wait_for_idle_bus:
        lda VIA_IRA        
        and #(I2C_SCL | I2C_SDA)      
        beq i2c_wait_for_idle_bus 
        rts
        

    ;A -> devicenr
    ;X -> register to read
    ;Result in A    
    i2c_read_register:
        sta i2c_tmp
        stx i2c_tmp2

        jsr i2c_start_condition
        lda i2c_tmp
        asl
        ora #I2C_WRITE

        jsr i2c_send_byte    ;send slave number
        bcs not_valid_responce_from_smc

        lda i2c_tmp2
        jsr i2c_send_byte    
        bcs not_valid_responce_from_smc     
        
        jsr i2c_stop_condition
        jsr i2c_start_condition
        lda i2c_tmp
        asl
        ora #I2C_READ
        jsr i2c_send_byte    ;send slave number
        bcs not_valid_responce_from_smc
        
        
        jsr i2c_read_byte
        jsr i2c_stop_condition

        clc
        
        rts

    ;A -> devicenr
    ;X -> register to write
    ;Y -> byte to write   
    i2c_write_register:
        sta i2c_tmp
        stx i2c_tmp2
        sty i2c_tmp3
        
        jsr i2c_start_condition
        lda i2c_tmp
        asl
        ora #I2C_WRITE

        jsr i2c_send_byte    ;send slave number
        bcs not_valid_responce_from_smc

        lda i2c_tmp2
        jsr i2c_send_byte    
        bcs not_valid_responce_from_smc     
        
      ;  jsr i2c_stop_condition
      ;  jsr i2c_start_condition
        
      ;  lda i2c_tmp
      ;  asl
      ;  ora #I2C_WRITE
      ;  jsr i2c_send_byte    ;send slave number
     ;   bcs not_valid_responce_from_smc
        
        lda i2c_tmp3
        jsr i2c_send_byte
        jsr i2c_stop_condition

        clc
        
        rts
        
    not_valid_responce_from_smc:
      ;  cli
        sec
        rts

goto_not_valid_responce_from_i2c: jmp not_valid_responce_from_i2c 
    
read_i2c_stream:
        sta i2c_tmp
        stx i2c_tmp2
 
        jsr i2c_start_condition
         
        lda i2c_tmp
        asl
        ora #I2C_WRITE

        jsr i2c_send_byte    ;send slave number
        bcs goto_not_valid_responce_from_i2c

        lda i2c_tmp2
        jsr i2c_send_byte    
        bcs goto_not_valid_responce_from_i2c     
        
        jsr i2c_stop_condition
        jsr i2c_start_condition
        lda i2c_tmp
        asl
        ora #I2C_READ
        jsr i2c_send_byte    ;send slave number
        bcs goto_not_valid_responce_from_i2c
        

        
        read_loop:
        .repeat 10
        jsr i2c_delay
        .endrepeat           
            jsr i2c_read_byte_with_ack
            cmp #$FD
            beq done
            cmp #$FF
            beq done
           
            sta (ptr)
  
            
            inc ptr
            bne :+
            inc ptr+1
            :       
            
        
            bra read_loop
            
        
            
          
        done:
        lda #0
        sta (ptr)
        jsr i2c_stop_condition
    rts

read_i2c_stream_by_len:
        sta i2c_tmp
        stx i2c_tmp2
        sty i2c_tmp3
 
        jsr i2c_start_condition
         
        lda i2c_tmp
        asl
        ora #I2C_WRITE

        jsr i2c_send_byte    ;send slave number
        bcs not_valid_responce_from_i2c

        lda i2c_tmp2
        jsr i2c_send_byte    
        bcs not_valid_responce_from_i2c     
        
        jsr i2c_stop_condition
        jsr i2c_start_condition
        lda i2c_tmp
        asl
        ora #I2C_READ
        jsr i2c_send_byte    ;send slave number
        bcs not_valid_responce_from_i2c
        
        
        read_loop2:
        .repeat 10
        jsr i2c_delay
        .endrepeat
            lda i2c_tmp3
            cmp #1
            bne read_with_ack
            jsr i2c_read_byte       ;we read and end with NACK, saying we are done reading
            bra continue_read
            read_with_ack:
            jsr i2c_read_byte_with_ack
            continue_read:
            
           
            sta (ptr)

            
            inc ptr
            bne :+
            inc ptr+1
            :       

            dec i2c_tmp3
            beq done2
            
           bra read_loop2
            
        
            
          
        done2:
       
        jsr i2c_stop_condition


    rts
    

not_valid_responce_from_i2c:
    lda #$CC
   ; jsr dbg
    jmp not_valid_responce_from_i2c
    
    

    send_i2c_stream:
        phy
        phx
        pha
            jsr i2c_start_condition
            lda #I2C_SLAVE
            asl
            ora #I2C_WRITE
            jsr i2c_send_byte ;send slavenr with writw
        pla
        jsr i2c_send_byte    ;send reg number
        plx
        ply
        stx ptr
        sty ptr+1
        
        ldy #0
        :
            lda (ptr),y
            beq at_and_of_stream
 
            jsr i2c_send_byte 
            iny
            bne :-
        at_and_of_stream:
        jsr i2c_stop_condition
        
    rts