
#include "macros.h.S"

syscall8:
	mflr    %r0
	stdu    %r1, -0xA0(%r1)
	std     %r27, 0x78(%r1)
	std     %r28, 0x80(%r1)
	std     %r29, 0x88(%r1)
	std     %r30, 0x90(%r1)
	std     %r31, 0x98(%r1)
	std     %r0, 0xB0(%r1)

	MEM_BASE(%r31)

	LOAD_LABEL2(%r27, %r31, save_syscall_values)		// Save_syscall_values address to r27

	
	lwz    %r28, 0(%r27)	   							// Stealth mode			//save_syscall_values address to r28
	cmplwi  %r28, 0x0									// If 0 jump to syscall8_ok
	beq	syscall8_ok	   									// If not stealth mode work normally

	cmplwi  %r28, 8
	bge	syscall8_stealth 								// If stealth mode >=8 ignore all
	
	cmpldi  %r3, 1	           							// Test for command == 1
        bne	syscall8_stealth

	cmpldi  %r4, 0	           							// compare if key is 0 to skip count times
        beq	syscall8_skip_count

	addi	%r28, %r28, 1	  							// Stealth_mode++ (count times)
	stw     %r28, 0(%r27)

 syscall8_skip_count:
	ld      %r28,  8(%r27)	   							// get key and compares if same key
	cmpld	%r4, %r28
        bne	syscall8_stealth
	li	%r28, 1
	stw     %r28, 0(%r27) 								// stealth mode

	// syscall8 enabled: system_call_2(8, 1, key)
	LOAD_ABS(%r4, %r31, syscall_table)

	//ld      %r28,  16(%r27)
	//std     %r28,  6*8(%r4) 							// patch syscall 6 to enable

	//ld      %r28,  24(%r27)
	//std     %r28,  7*8(%r4) 							// patch syscall 7 to enable
	
	LOAD_LABEL2(%r28, %r31, syscall_36_map_bdvd_desc)
	std     %r28, 36*8(%r4) 							// patch syscall 36 to enable

	li	%r28, 0
	stw     %r28, 0(%r27) // stealth mode off
	
	//li	%r3, SYS8_VERSION
	lis	%r3, SYS8_VERSION@highest
	ori	%r3, %r3, SYS8_VERSION@higher
	rldicr  %r3, %r3, 32, 31
	oris	%r3, %r3, SYS8_VERSION@h
	ori	%r3, %r3, SYS8_VERSION@l
	b	syscall8_end

 syscall8_ok:
	// syscall switch
	andi.    %r3, %r3, 0xff
	cmpldi  %r3, 13
	bge	syscall8_unsupported
	
	LOAD_LABEL2(%r27, %r31, syscall8_table)
	sldi 	%r28, %r3, 3
	add 	%r27, %r27, %r28
	
	ld	%r29, 0(%r27)

	// move param registers
	mr      %r3, %r4
	mr      %r4, %r5
	mr      %r5, %r6

	// jump to register address with link
	bl	syscall8_bl

 syscall8_end:

	ld      %r27, 0x78(%r1)
        ld      %r28, 0x80(%r1)
        ld      %r29, 0x88(%r1)
        ld      %r30, 0x90(%r1)
        ld      %r31, 0x98(%r1)
        ld      %r0, 0xB0(%sp)
        addi    %r1, %r1, 0xA0
	mtlr    %r0
	blr

 syscall8_stealth:
	lis     %r3, -0x7FFF
	ori     %r3, %r3, 3
	b syscall8_end

 syscall8_unsupported:
	li     %r3, -1
	b syscall8_end

 syscall8_bl:
	mtctr   %r29
	bctr

#############################################################################################################################################################

	// system_call_2(8, 0, key): disables the syscalls vectors and fix a key to enable it again using system_call_2(8, 1, key)
 sys8_disable:

	LOAD_LABEL2(%r27, %r31, save_syscall_values)
	std     %r3,  8(%r27) 							// save key

	li	%r28, 1
	stw     %r28, 0(%r27) 							// stealth mode

	LOAD_ABS(%r4, %r31, syscall_table)

	ld      %r3, 37*8(%r4) 							// get unused syscall addr

	//ld      %r28, 6*8(%r4)
	//std     %r3,  6*8(%r4) 						// patch syscall 6 to stealth
	//std     %r28,  16(%r27)

	//ld      %r28, 7*8(%r4)
	//std     %r3,  7*8(%r4) 						// patch syscall 7 to stealth
	//std     %r28,  24(%r27)
	

    std     %r3, 36*8(%r4) 							// patch syscall 36 to stealth

	li	%r3, 0
	blr

    // dummy for system_call_2(8, 1, key)

 sys8_enable: // system_call_2(8, 1, key) when syscalls are enabled
	lis	%r3, SYS8_VERSION@highest
	ori	%r3, %r3, SYS8_VERSION@higher
	rldicr  %r3, %r3, 32, 31
	oris	%r3, %r3, SYS8_VERSION@h
	ori	%r3, %r3, SYS8_VERSION@l
	blr

 sys8_memcpy: // system_call_4(8, 2, dest, src, len)

	b      ABSOLUTE_MEM2(memcpy)

 sys8_memset: // system_call_4(8, 3, dest, dat, len)
	b      ABSOLUTE_MEM2(memset)

 sys8_call: // system_call_4(8, 4, addr, param1, param2)

	
	mtctr   %r3
	mr	%r3, %r4
	mr	%r4, %r5
	bctr

 sys8_alloc: // system_call_3(8, 5, size, pool)

	b      ABSOLUTE_MEM2(alloc)

 sys8_free: // system_call_3(8, 6, ptr, pool)

	b      ABSOLUTE_MEM2(free)

 sys8_panic: // system_call_1(8, 7)
	PANIC()

 sys8_perm_mode: // system_call_2(8, 8, perm)

	LOAD_LABEL2(%r27, %r31, perm_mode)			// Read perm_mode address
	stw	%r3, 0(%r27)							// Save input parameter to perm_mode
	li	%r3, 0									// Return 0
	blr

 sys8_open_table:  // system_call_2(8, 9, ptr)

	mr	%r4, %r3
	LOAD_LABEL2(%r27, %r31, str_open_cmp)
	ld	%r3, 0(%r27)
        std	%r4, 0(%r27)
	blr

 sys8_peek:	// system_call_2(8,0xa, ptr)
	ld	%r3, 0x00(%r3)
	blr

 sys8_poke:	// system_call_3(8,0xb, addr, data)
	std	%r4, 0x00(%r3)
	blr	

sys8_restore:
	LOAD_LABEL2(%r5, %r31, save_patches_val)	// 0=Return to normal cracked mode 1=Restricted mode

	mr	%r28, %r3
	cmpldi	%r3, 0
	beq	l_sys8_restore_process
	LOAD_LABEL2(%r5, %r31, save_original_val)

l_sys8_restore_process:
	addi	%r5, %r5, 0x40

l_sys8_patches_loop:
	lwz	%r3, 0(%r5)								// If entry in patch table is NULL, were done
	cmplwi	%r3, 0								// Get offset address to be modified, 0 exits loop
	beq	l_sys8_patches_applied
	lwz	%r4, 4(%r5)								// Get value to modify
	add	%r3, %r3, %r31							// Calculate absolute address
	stw	%r4, 0(%r3)								// Modify
	addi	%r5, %r5, 8							// Next Patch
	b	l_sys8_patches_loop

l_sys8_patches_applied:
	mr	%r3, %r28
	blr


 perm_routine:
	
	MEM_BASE(%r9)
	LOADI_LABEL2(%r9, perm_mode)
	lwz	%r0, 0(%r9)
	cmplwi  %r0, 0
	bne	return1
	ld      %r9, rtoc_entry_3(%r2)
	mflr    %r0
	b	ABSOLUTE_MEM2(patch_func5 + patch_func5_offset + 8)

 perm0_routine:

	MEM_BASE(%r9)
	LOADI_LABEL2(%r9, perm_mode)
	lwz	%r0, 0(%r9)
	cmplwi  %r0, 1
	beq	return1
	cmplwi  %r0, 2
	beq	return0
	ld      %r9, rtoc_entry_3(%r2)
	mflr    %r0
	b	ABSOLUTE_MEM2(patch_func5 + patch_func5_offset + 8)

 return1:
	li	%r3, 1
        blr
		 
 return0:
	li      %r3, 0
        blr


 syscall8_table:
	QUAD_MEM2(sys8_disable);
	QUAD_MEM2(sys8_enable);
	QUAD_MEM2(sys8_memcpy);
	QUAD_MEM2(sys8_memset);
	QUAD_MEM2(sys8_call);
	QUAD_MEM2(sys8_alloc);
	QUAD_MEM2(sys8_free);
	QUAD_MEM2(sys8_panic);
	QUAD_MEM2(sys8_perm_mode);
	QUAD_MEM2(sys8_open_table);
	QUAD_MEM2(sys8_peek);
	QUAD_MEM2(sys8_poke);
	QUAD_MEM2(sys8_restore);
	QUAD_MEM2(sys8_enable);

 str_open_cmp:
	.quad 0
 
 save_syscall_values: // (for stealth)
	.quad 0 // stealth mode
	.quad 0 // key

 save_original_val:
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.long 0 
 save_patches_val:
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.quad 0 
	.long 0 

 perm_mode:
	.long PERM_MODE

