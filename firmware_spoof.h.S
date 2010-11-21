
syscall_versiontest_desc:
	QUAD_MEM2(syscall_versiontest)

syscall_versiontest:
	stdu	%r1, -0x80(%r1)
	std	%r31, 0x78(%r1)
	mflr	%r0
	std	%r0, 0x90(%r1)
	MEM_BASE(%r31)
	addi	%r3, %r3, 0x20
	LOAD_LABEL2(%r4, %r31, version_ptr)
	ld	%r4, 0(%r4)
	li	%r5, 0x2D0
	bl	ABSOLUTE_MEM2(memcpy)
	li	%r3, 0
	ld	%r0, 0x90(%r1)
	ld	%r31, 0x78(%r1)
	mtlr	%r0
	addi	%r1, %r1, 0x80
	blr

syscall_process_sdkversion_desc:
	QUAD_MEM2(syscall_process_sdkversion)

// syscall_process_sdkversion(uint32_t pid, uint32_t *sdk_version)
syscall_process_sdkversion:
	lis	%r5, 0x0100
	ori	%r5, %r5, 0x0300
	cmpw	%r3, %r5
	bne	orig_func // if not vsh pid, return to orig proc
	lis	%r5, 0x35 // 3.50 sdk version
	stw	%r5, 0(%r4)
	li	%r3, 0
	blr
orig_func:
	b	ABSOLUTE_MEM2(orig_syscall_25) 

version_ptr:
	.quad	0

