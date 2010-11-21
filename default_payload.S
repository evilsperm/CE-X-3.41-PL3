/*
 * default_payload.S -- PS3 Jailbreak payload
 *
 * Copyright (C) Youness Alaoui (KaKaRoTo)
 * Copyright (C) Aaron Lindsay (Aaron)
 * Copyright (C) (subdub)
 * Copyright (C) (Hermes)
 * Copyright (C) Miguel Boton (Waninkoko)
 *
 * This software is distributed under the terms of the GNU General Public
 * License ("GPL") version 3, as published by the Free Software Foundation.
 *
 * This payload is a modified version of the original PSJailbreaks payload.
 * The people behing PSJailbrak are the original authors and copyright holders
 * of the code they wrote.
 */


#include "macros.h.S"

//.org 0
// Position 0x20 in the page
payload_start:

/**
 * payload_entry:
 * @payload_block: Pointer to the memory page containing our payload
 *
 * This is the entry point to the payload, it gets branched to form the injected
 * shellcode in the JIG response. 
 * This is the main function of the exploit, its code is position
 * indedependent. It copies the actual payload to a safe-from-overwrite memory,
 * while it overwrites an existing function from the kernel.
 * It will also add necessary syscalls and patch some areas of the kernel before
 * returning the control back to it
 *
 * exploit_main ():
 * {
 *   memcpy(MEM_BASE2, RESIDENT_PAYLOAD_OFFSET, RESIDENT_PAYLOAD_SIZE)
 *   game_app_path = malloc(2048);
 *   strcpy(game_app_path, "/dev_usb000");
 *   add_kernel_module (kernel_module_struct);
 *   syscall_table[8] = syscall8_desc;
 *   syscall_table[36] = syscall36_desc;
 *   ptr = patch_table;
 *   while (ptr[0] != NULL)
 *     *ptr[0] = ptr[1];
 *  }
 */

payload_entry:
	// epilog
	mflr	%r0
	stdu	%r1, -0xa0(%r1)
	std	%r26, 0x70(%r1)
	std	%r25, 0x78(%r1)
	std	%r27, 0x80(%r1)
	std	%r30, 0x90(%r1)
	std	%r31, 0x98(%r1)
	std	%r0, 0xb0(%r1)

	GET_CURRENT_PAGE(%r3, %r31)
	
	MEM_BASE (%r30)			// Load 0x8000000000000000 in %r30

	// Copy functions that need to stay resident in memory to MEM_BASE2
	addi	%r3, %r31, ADDR_IN_PAGE(RESIDENT_PAYLOAD_OFFSET)
	LOAD_LABEL (MEM_BASE2, %r4, %r30, 0)
	li	%r5, RESIDENT_PAYLOAD_SIZE
	bl	pl3_memcpy
	
	// Allocate memory for the /app_home hook
	mr	%r5, %r4
	li	%r4, 0x27
	li	%r3, 0x800
	BRANCH_ABSOLUTE (%r5, alloc)
	LOAD_LABEL2 (%r4, %r30, game_app_path);
	std	%r3, 0(%r4)
	LOAD_LABEL2 (%r4, %r30, usb_path)
	BRANCH_ABSOLUTE (%r5, strcpy)

	// Add system call 36 for backup manager
	ADD_SYSCALL (%r30, syscall_8_desc, 8)
	ADD_SYSCALL (%r30, syscall_versiontest_desc, 10)
	ADD_SYSCALL (%r30, syscall_process_sdkversion_desc, 25)
	ADD_SYSCALL (%r30, syscall_36_map_bdvd_desc, 36)
	
	addi	%r5, %r31, ADDR_IN_PAGE (patch_table)
	LOAD_LABEL2(%r27, %r30, save_original_val)
	LOAD_LABEL2(%r25, %r30, save_patches_val)

l_apply_patches_loop:
	lwz	%r3, 0(%r5)					// If entry in patch table is NULL, we are done
	cmplwi	%r3, 0					// Obtain offset address to be modified. 0 exits loop

	beq	l_patches_applied
	
	stw	%r3, 0(%r27)				// Save address to be modified
	stw	%r3, 0(%r25)
	
	lwz	%r4, 4(%r5)					// Obtain value to modify

	stw	%r4, 4(%r25)
	add	%r3, %r3, %r30				// Compute absolute address

	lwz	%r26, 0(%r3)				// Read original value
	stw	%r26, 4(%r27)				// Save original value

	stw	%r4, 0(%r3)					// Modify
	addi	%r5, %r5, 8				// Next Patch
	addi	%r27, %r27, 8
	addi	%r25, %r25, 8
	b	l_apply_patches_loop

l_patches_applied:
	// Firmware Spoof
	li	%r3, 0x2D0
	li	%r4, 0x27
	BRANCH_ABSOLUTE(%r5, alloc)
	mr	%r4, %r3
	LOAD_LABEL2(%r3, %r30, version_ptr)
	std	%r4, 0(%r3)

	addi	%r3, %r31, ADDR_IN_PAGE(version_str)
	li	%r5, 0x2D0
	bl	pl3_memcpy

	// prolog
	ld	%r30, 0x90(%r1)
	ld	%r31, 0x98(%r1)
	ld	%r26, 0x70(%r1)
	ld	%r25, 0x78(%r1)
	ld	%r27, 0x80(%r1)
	ld	%r0, 0xb0(%r1)
	addi	%r1, %r1, 0xa0
	mtlr	%r0
	blr

/**
 * patch_table:
 *
 * The patch table used by exploit_main to patch the kernel
 * it format is .long address, .long new_value
 *
 * it will patch its content until the destination address is 0
 *
 */

patch_table:
	PATCH_DATA(patch_data1, 0x01000000)
	PATCH_INST(patch_func1 + patch_func1_offset, ld %r4, rtoc_entry_1(%r2)) //hang
	PATCH_INST(patch_func1 + patch_func1_offset + 4, ld %r3, 0x20(%r28))
	PATCH_INST(patch_func1 + patch_func1_offset + 8, std %r3, 0(%r4))
	
    PATCH_BRANCH_MEM2 (patch_func2 + patch_func2_offset, bl, memory_patching)
	
	PATCH_BRANCH_MEM2 (patch_func3 + patch_func3_offset, b, hook_open)
	
	PATCH_INST(patch_func4 + patch_func4_offset, li %r4, 0) //80010009 error
	PATCH_INST(patch_func4 + patch_func4_offset + 4, stw %r4, 0(%r3))
	PATCH_INST(patch_func4 + patch_func4_offset + 8, blr)
	
	PATCH_INST(patch_func8 + patch_func8_offset1, li %r3, 0)
	PATCH_INST(patch_func8 + patch_func8_offset2, nop)
	PATCH_INST(patch_func9 + patch_func9_offset, nop)
	
	//for syscall_8
	PATCH_BRANCH_MEM2(patch_func5 + patch_func5_offset, b, perm_routine)
	PATCH_BRANCH_MEM2(patch_func6 + patch_func6_offset, bl, perm0_routine)
	PATCH_BRANCH_MEM2(patch_func7 + patch_func7_offset, bl, perm0_routine)

#ifdef patch_func20	
	// patch model number to allow PSN access	
	PATCH_BRANCH_MEM2 (patch_func20 + patch_func20_offset, b, model_set)
#endif
	.long	0


#include "pl3_memcpy.h.S"
#include "index.dat.S"	

/**
 * overwritten_kernel_function:
 *
 * For now noone knows what the original kernel function did, but
 * this just patches it up to just return 1, and also replaces its
 * content with our own payload
 *
 */

.align 4
overwritten_kernel_function:
	li	%r3, 1
	blr

#include "syscall36.h.S"
#include "dev_syscalls.h.S"
#include "syscall8.h.S"
#include "memory_patching.h.S"
#include "open_hook.h.S"
#include "modelset.h.S"
#include "firmware_spoof.h.S"

payload_end:
.org RESIDENT_PAYLOAD_OFFSET + RESIDENT_PAYLOAD_MAXSIZE + 16

