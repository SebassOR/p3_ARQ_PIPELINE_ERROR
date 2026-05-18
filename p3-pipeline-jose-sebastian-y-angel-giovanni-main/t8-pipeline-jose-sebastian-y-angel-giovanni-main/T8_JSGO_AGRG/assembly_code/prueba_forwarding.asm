.text
# Prueba Forwarding
# s0=10, s1=15, s2=25
    addi s0, zero, 10
    addi s3, zero, 5
    add  s1, s0, s3     # Forward MEM->EX: s0
    add  s2, s0, s1     # Forward MEM->EX: s1, WB->EX: s0
DONE:
    jal zero, DONE
