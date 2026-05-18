.text
# Prueba Flush por Branch
# s0=1, s1=99 (no cambia), s2=2
    addi t0, zero, 5
    addi t1, zero, 5
    addi s1, zero, 99

    beq  t0, t1, TOMADO     # branch tomado -> flush de NO_BRANCH

NO_BRANCH:
    addi s1, zero, 0        # nunca debe ejecutarse
    addi s1, zero, 0
    addi s1, zero, 0

TOMADO:
    addi s0, zero, 1        # confirma llegada

    addi t2, zero, 9
    beq  t0, t2, FALSO      # branch NO tomado

    addi s2, zero, 2        # debe ejecutarse
    jal  zero, DONE

FALSO:
    addi s2, zero, 0        # nunca debe ejecutarse
    addi s2, zero, 0

DONE:
    jal zero, DONE
