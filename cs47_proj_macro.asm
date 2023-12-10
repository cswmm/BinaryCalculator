# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#

	# Macro: extract nth bit from a bit pattern
	.macro extract_nth_bit($regD, $regS, $regT)
	# $regD will contain 0x0 or 0x1 depending on the nth bit being 0 or 1
	# $regS: source bit pattern
	# $regT: Register containing bit position n (0-31)
	li $regD, 0x1
	sllv $regD, $regD, $regT
	and $regD, $regD, $regS
	srlv $regD,$regD, $regT
	.end_macro
	
	# Macro: insert bit 1 or 0 at nth bit to a bit pattern
	# does NOT only insert a 1
	.macro insert_one_to_nth_bit($regD, $regS, $regT, $maskReg)
	# $regD: bit pattern in which 1 or 0 is to be inserted at nth position
	# $regS: value n, from which position of the bit to be inserted is (0-31)
	# $regT: register that contains 0x1 or 0x0 (bit value to be inserted)
	# $maskReg: register to hold temporary mask
	li $maskReg 0x1
	sllv $maskReg, $maskReg, $regS
	not $maskReg, $maskReg
	and $regD, $regD, $maskReg
	sllv $regT, $regT, $regS
	or $regD, $regD, $regT
	srlv $regT, $regT, $regS
	.end_macro