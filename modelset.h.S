
#include "macros.h.S"

.align 4

model_set:
	lis	%r31, 1
	ori	%r31, %r31, 0x9004
	cmpw	%r31, %r3
	bne	l_model_skip_check

	// Device model
	// 0x81 = Reftool
	// 0x82 = Debugging station
	// 0x83 = Retail Japan
	// 0x84 = Retail USA
	// 0x85 = Retail Europa
	// 0x89 = Kiosk Australia(?)
	// 0x8E = Retail Hong Kong
	// 0xA0 = System debugger
	li	%r29, 0x82
	stb	%r29, 3(%r4)

	// Motherboard type
	// 0x01 = CECHA (60GB Full PS2) - COK-001 + Memcard Daughterboard
	// 0x02 = CECHB (20GB Full PS2) - COK-001
	// 0x03 = CECHC (60GB Partial PS2) - COK-002 + Memcard Daughterboard
	// 0x04 = CECHE (80GB Partial PS2) - COK-002W + Memcard Daughterboard
	// 0x05 = CECHG (40GB No PS2) - SEM-001
	// 0x06 = CECHH (40GB No PS2) - DIA-001
	// 0x07 = CECHJ / CECHK (40GB/80GB No PS2) - DIA-002
	// 0x08 = CECHL / CECHM / CECHP / CECHQ (80GB/160GB No PS2) - VER-001
	// 0x09 = CECH20A / CECH20B (120GB/250GB Slim) - DYN-001
	// 0x0A = CECH21A / CECH21B (120GB/250GB Slim) - SUR-001
	// 0x0B = CECH25A / CECH25B (160GB/320GB Slim)
	li	%r29, 0x09
	stb	%r29, 5(%r4)
	
	li	%r29, 1
	stb	%r29, 1(%r4)
	stb	%r29, 7(%r4) // Possibly BD Drive / firmware

	ld	%r0, 0xC0(%r1)
	ld	%r29, 0x98(%r1)
	ld	%r30, 0xA0(%r1)
	mtlr	%r0
	ld	%r31, 0xA8(%r1)
	addi	%r1, %r1,0xB0
	li	%r3, 0
	blr

l_model_skip_check:
	mr	%r30, %r3
	b	ABSOLUTE_MEM2(patch_func20 + 4)

model_set_end:
