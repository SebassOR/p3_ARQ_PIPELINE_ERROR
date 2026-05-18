.data
M:.word 5
.text
start:
	addi t2, zero, 4
    auipc   t0, 0x123

    addi    t1, t0, 5   

loop:
    beq x0, zero, loop             
