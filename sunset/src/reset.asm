reset_handler
    sei         ; Disable all interrupts
    cld         ; Disable decimal mode
    ldx #$40
    stx $4017   ; Disable APU frame IRQ
    ldx #$FF
    txs         ; Setup stack
    inx         ; Now X=0
    
    stx PPUCTRL ; Disable NMI
    stx PPUMASK ; Disable rendering
    stx $4010   ; Disable DMC IRQs

-	bit PPUSTATUS
    bpl -
    jmp main