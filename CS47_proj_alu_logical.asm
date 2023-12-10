.include "./cs47_proj_macro.asm"
.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
	addi $sp, $sp, -24
	sw $fp, 24($sp)
	sw $ra, 20($sp)
	sw $a0, 16($sp)
	sw $a1, 12($sp)
	sw $a2, 8($sp)
	addi $fp, $sp, 24
	
	beq $a2, '+', add_logical
	beq $a2, '-', sub_logical
	beq $a2, '*', mul_logical
	beq $a2, '/', div_logical

mul_logical:
	jal mul_signed
	j au_logical_return
	
div_logical:
	jal div_signed
	j au_logical_return
	
add_logical:
	li $a2, 0x0
	j add_sub_logical
	
sub_logical:
	li $a2, 0xFFFFFFFF

	# returns $a0+$a1 in addition mode and $a0-$a1 in subtraction mode
add_sub_logical:
	# $t0: A
	# $t1: B
	# Mode
	# $t2: Index
	# $t3: Carry
	# $t4: Intermediate sum
	
	li $t2, 0x0
	li $t4, 0x0
	li $v0, 0x0
	extract_nth_bit($t3, $a2, $zero)
	beqz $t3, addition_mode
	
subtraction_mode:
	not $a1, $a1
	
addition_mode:
	extract_nth_bit($t0, $a0, $t2)
	extract_nth_bit($t1, $a1, $t2)
	xor $t5, $t0, $t1 # A XOR B
	and $t6, $t0, $t1 # A AND B
	and $t7, $t3, $t5 # CI AND (A XOR B)
	xor $t4, $t3, $t5 # Intermediate sum- CI XOR (A XOR B)
	or $t3, $t7, $t6 # COUT- CI AND (A XOR B) OR (A AND B)
	insert_one_to_nth_bit($v0, $t2, $t4, $t9)
	addi $t2, $t2, 0x1
	blt $t2, 32, addition_mode
	# return final carryout in $v1
	move $v1, $t3
	j au_logical_return

# Arguments:
	# $a0: Number of which 2's compliment is to be computed
	# Return
	# $v0: Two's complement of $a0
twos_complement:
	addi $sp, $sp, -20
	sw $fp, 20($sp)
	sw $ra, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 20
	
	not $a0, $a0
	li $a1, 1
	li $a2, '+'
	jal au_logical
	
	lw $fp, 20($sp)
	lw $ra, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra

	# $a0: Number of which 2's complement is to be computed
	# Return:
	# $v0: 2's complement of $a0 if $a0 is negative
twos_complement_if_neg: 
	addi $sp, $sp, -20
	sw $fp, 20($sp)
	sw $ra, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 20
	
	bgez $a0, positive
	jal twos_complement
	j twos_complement_if_neg_return
positive:
	move $v0, $a0
twos_complement_if_neg_return:
	lw $fp, 20($sp)
	lw $ra, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra

	# $a0: Lo of number
	# $a1: Hi of number
	# Return:
	# $v0: Lo part of 2's complemented 64-bit
	# $v1: Hi part of 2's complemented 64-bit
twos_complement_64bit:
	addi $sp, $sp, -28
	sw $fp, 28($sp)
	sw $ra, 24($sp)
	sw $a0, 20($sp)
	sw $a1, 16($sp)
	sw $a2, 12($sp)
	sw $s1, 8($sp)	
	addi $fp, $sp, 28
	
	move $s1,$a1 #store Hi
	not $a0,$a0 #inverse Lo
	li $a2, '+' 
	li $a1, 1
	jal au_logical #inverse Lo + 1
	move $a0,$s1 #store Hi
	move $s1,$v0 #store result
	move $a1,$v1 #store carryout
	not $a0,$a0 
	jal au_logical #inverse Hi + carryout
	move $v1,$v0 #return both results
	move $v0,$s1
	
	lw $fp, 28($sp)
	lw $ra, 24($sp)
	lw $a0, 20($sp)
	lw $a1, 16($sp)
	lw $a2, 12($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 28
	jr $ra

	# $a0: bit value to be replicated (0x0 or 0x1)
	# Return:
	# $v0: 0x00000000 if $a0 is 0x0, 0xFFFFFFFF if $a0 is 0x1
bit_replicator:
	addi $sp, $sp, -16
	sw $fp, 16($sp)
	sw $ra, 12($sp)
	sw $a0, 8($sp)
	addi $fp, $sp, 16
	
	beqz $a0, bit_replicator_zero
	
	li $v0, 0xFFFFFFFF
	j bit_replicator_return
	
bit_replicator_zero:
	li $v0, 0x00000000

bit_replicator_return:
	lw $fp, 16($sp)
	lw $ra, 12($sp)
	lw $a0, 8($sp)
	addi $sp, $sp, 16
	jr $ra
	
# $a0: Multiplicand
	# $a1: Multiplier
	# Return:
	# $v0: Lo
	# $v1: Hi
mul_unsigned:
	addi $sp, $sp, -32
	sw $fp, 32($sp)
	sw $ra, 28($sp)
	sw $s0, 24($sp)
	sw $s1, 20($sp)
	sw $s2, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 32
	
	li $s0, 0 # I=0
	li $v1, 0 # H=0
	move $v0, $a1 # L = MLPR
mul_loop:
	extract_nth_bit($t0, $v0, $zero)
	move $s1, $v0
	move $s2, $a0
	move $a0, $t0
	jal bit_replicator # R={32{L[0]}}
	move $t0,$v0
	move $v0,$s1
	move $a0,$s2
	and $t1, $t0, $a0 # X = M & R
	move $s1, $v0
	move $s2, $a0
	move $a0, $v1
	move $a1, $t1
	li $a2, '+' # H = H + X
	jal au_logical
	move $v1, $v0
	move $v0, $s1
	move $a0, $s2
	srl $v0, $v0, 1 # L = L >> 1
	extract_nth_bit($t2, $v1, $zero) # H[0]
	li $t3, 31
	insert_one_to_nth_bit($v0, $t3, $t2, $t4) # L[31] = H[0]
	srl $v1, $v1, 1 # H = H >> 1
	addi $s0, $s0, 1 # I++
	blt $s0, 32, mul_loop

	lw $fp, 32($sp)
	lw $ra, 28($sp)
	lw $s0, 24($sp)
	lw $s1, 20($sp)
	lw $s2, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 32
	jr $ra
	
# $a0: Multiplicand
	# $a1: Multiplier
	# Return:
	# $v0: Lo part of result
	# $v1: Hi part of result
mul_signed:
	addi $sp, $sp, -32
	sw $fp, 32($sp)
	sw $ra, 28($sp)
	sw $s0, 24($sp)
	sw $s1, 20($sp)
	sw $s2, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 32
	
	move $s1, $a0
	move $s2, $a1
	jal twos_complement_if_neg # Make N1 two's complement if negative
	move $s0, $v0
	move $a0, $a1
	jal twos_complement_if_neg # Make N2 two's complement if negative
	move $a1, $v0
	move $a0, $s0
	jal mul_unsigned
	# Determine sign S of result
	li $t2, 31
	extract_nth_bit($t0, $s1, $t2)
	extract_nth_bit($t1, $s2, $t2)
	xor $t0, $t0, $t1 # S = $a0[31] XOR $a1[31]
	move $a0, $v0
	move $a1, $v1
	beqz $t0, mul_signed_return
	jal twos_complement_64bit # If S is 1, use the 'twos_complement_64bit' to determine twos complement form of result
mul_signed_return:
	lw $fp, 32($sp)
	lw $ra, 28($sp)
	lw $s0, 24($sp)
	lw $s1, 20($sp)
	lw $s2, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 32
	jr $ra
	
	# $a0: Dividend
	# $a0: Divisor
	# Return:
	# $v0: Quotient
	# $v1: Remainder
div_unsigned:
	addi $sp, $sp, -32
	sw $fp, 32($sp)
	sw $ra, 28($sp)
	sw $s0, 24($sp)
	sw $s1, 20($sp)
	sw $s2, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 32
	
	li $s0, 0 # I = 0
	move $s1, $a0 # Q = DVND
	li $s2, 0 # R = 0
div_loop:
	sll $s2, $s2, 1 # R = R << 1
	li $t0, 31
	extract_nth_bit($t1, $s1, $t0)
	insert_one_to_nth_bit($s2, $zero, $t1, $t9) # R[0] = Q[31]
	sll $s1, $s1, 1 # Q = Q << 1
	move $a0, $s2 
	li $a2, '-'
	jal au_logical # S = R - D
	bltz $v0, div_loop_return
	move $s2, $v0 # R = S
	li $t2, 1
	insert_one_to_nth_bit($s1, $zero, $t2, $t9) # Q[0] = 1
div_loop_return:
	addi $s0, $s0, 1
	blt $s0, 32, div_loop
	move $v0, $s1
	move $v1, $s2
	
	lw $fp, 32($sp)
	lw $ra, 28($sp)
	lw $s0, 24($sp)
	lw $s1, 20($sp)
	lw $s2, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 32
	jr $ra
	
	# $a0: Dividend
	# $a1: Divisor
	# Return:
	# $v0: Quotient
	# $v1: Remainder
div_signed:
	addi $sp, $sp, -40
	sw $fp, 40($sp)
	sw $ra, 36($sp)
	sw $s0, 32($sp)
	sw $s1, 28($sp)
	sw $s2, 24($sp)
	sw $s3, 20($sp)
	sw $s4, 16($sp)
	sw $a0, 12($sp)
	sw $a1, 8($sp)
	addi $fp, $sp, 40
	
	move $s0, $a0 # N1
	move $s1, $a1 # N2
	jal twos_complement_if_neg
	move $s2, $v0
	move $a0, $a1
	jal twos_complement_if_neg
	move $a1, $v0
	move $a0, $s2
	jal div_unsigned
	move $a0, $v0 # Q
	move $s3, $v0 
	move $a1, $v1 # R
	move $s4, $v1
	# Determine S of Q
	li $t0, 31
	extract_nth_bit($t1, $s0, $t0)
	extract_nth_bit($t2, $s1, $t0)
	move $s2, $t1
	xor $t0, $t1, $t2 # $a0[31] xor $a1[31]
	beqz $t0, remainder_check # If S is 1, two's complement of Q
	move $a0, $s3
	jal twos_complement
	move $s3, $v0
remainder_check:
	beqz $s2, div_signed_return # If S is 1, two's complement of R
	move $a0, $s4
	jal twos_complement
	move $s4, $v0
div_signed_return:
	move $v0, $s3
	move $v1, $s4
	
	lw $fp, 40($sp)
	lw $ra, 36($sp)
	lw $s0, 32($sp)
	lw $s1, 28($sp)
	lw $s2, 24($sp)
	lw $s3, 20($sp)
	lw $s4, 16($sp)
	lw $a0, 12($sp)
	lw $a1, 8($sp)
	addi $sp, $sp, 40
	jr $ra

au_logical_return:
	lw $fp, 24($sp)
	lw $ra, 20($sp)
	lw $a0, 16($sp)
	lw $a1, 12($sp)
	lw $a2, 8($sp)
	addi $sp, $sp, 24
	jr 	$ra
