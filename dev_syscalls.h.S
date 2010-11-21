/*
 * dev_syscalls.S -- PS3 Jailbreak payload - Development system calls
 *
 * Copyright (C) Youness Alaoui (KaKaRoTo)
 * Copyright (C) Aaron Lindsay (Aaron)
 * Copyright (C) (subdub)
 *
 * This software is distributed under the terms of the GNU General Public
 * License ("GPL") version 3, as published by the Free Software Foundation.
 */

syscall_8_desc:
	QUAD_MEM2(syscall_8)

syscall_8:
	b 	syscall8

