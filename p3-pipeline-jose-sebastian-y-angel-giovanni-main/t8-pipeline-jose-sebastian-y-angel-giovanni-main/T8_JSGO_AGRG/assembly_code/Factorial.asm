.text
INIT:
    lui  s0, 0x10013
    lui  s1, 0x10011
    addi s1, s1, 0x20
    addi s2, s1, 0x4

CONFIG_UART:
    sw   zero, 0x34(s0)
    addi t0, zero, 0x46
    sw   t0, 0x20(s0)
    addi t0, zero, 0x01
    sw   t0, 0x24(s0)
    addi t0, zero, 0x03
    sw   t0, 0x0C(s0)
    lui  t0, 0x6
    addi t0, t0, 0x1
    sw   t0, 0x30(s0)

SANITY_CHECK:
    addi t1, zero, 0x55
    jal  ra, UART_SEND

WAIT_START:
    lw   t0, 0x0(s1)
    addi zero, zero, 0
    andi t1, t0, 0x80
    beq  t1, zero, WAIT_START
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    andi a0, t0, 0x7F
    sw   a0, 0x0(s2)

    jal  ra, FACTORIAL
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    sw   a0, 0x0(s2)

SEND_RESULT:
    andi t1, a0, 0xFF
    jal  ra, UART_SEND
    srli t1, a0, 8
    andi t1, t1, 0xFF
    jal  ra, UART_SEND
    srli t1, a0, 16
    andi t1, t1, 0xFF
    jal  ra, UART_SEND
    srli t1, a0, 24
    andi t1, t1, 0xFF
    jal  ra, UART_SEND

WAIT_RELEASE:
    lw   t0, 0x0(s1)
    addi zero, zero, 0
    andi t1, t0, 0x80
    bne  t1, zero, WAIT_RELEASE
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    jal  zero, WAIT_START
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

UART_SEND:
POLL_THRE:
    lw   t0, 0x14(s0)
    addi zero, zero, 0
    andi t0, t0, 0x20
    beq  t0, zero, POLL_THRE
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    sw   t1, 0x00(s0)
    jalr zero, ra, 0

FACTORIAL:
    addi t0, zero, 1
    bge  t0, a0, FACT_BASE
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    addi a0, a0, -1
    jal  ra, FACTORIAL
    addi zero, zero, 0
    addi zero, zero, 0
    addi zero, zero, 0

    lw   ra, 4(sp)
    addi zero, zero, 0
    lw   t0, 0(sp)
    addi zero, zero, 0
    addi sp, sp, 8
    mul  a0, t0, a0
    jalr zero, ra, 0

FACT_BASE:
    addi a0, zero, 1
    jalr zero, ra, 0