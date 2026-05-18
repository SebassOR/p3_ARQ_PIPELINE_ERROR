.text
# Prueba Stall LW (Load-Use Hazard)
# t1 = 0xAB + 5 = 0xB0
    lui  s0, 0x10010        # base memoria datos
    addi t2, zero, 0xAB
    sw   t2, 0(s0)          # Mem[0x10010000] = 0xAB
    addi t3, zero, 5

    lw   t0, 0(s0)          # stall: t0 no esta listo
    add  t1, t0, t3         # Hazard Unit inserta NOP aqui

DONE:
    jal zero, DONE
