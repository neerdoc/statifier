# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!
#

#include "regs.inc"	

	GET_DATA_ADDR	v0
					# Let restore registers now
	ldq	t0,	T0(v0)
	ldq	t1,	T1(v0)
	ldq	t2,	T2(v0)
	ldq	t3,	T3(v0)
	ldq	t4,	T4(v0)
	ldq	t5,	T5(v0)
	ldq	t6,	T6(v0)
	ldq	t7,	T7(v0)
	ldq	s0,	S0(v0)
	ldq	s1,	S1(v0)
	ldq	s2,	S2(v0)
	ldq	s3,	S3(v0)
	ldq	s4,	S4(v0)
	ldq	s5,	S5(v0)
	ldq	fp,	FP(v0)
	ldq	a0,	A0(v0)
	ldq	a1,	A1(v0)
	ldq	a2,	A2(v0)
	ldq	a3,	A3(v0)
	ldq	a4,	A4(v0)
	ldq	a5,	A5(v0)
	ldq	t8,	T8(v0)
	ldq	t9,	T9(v0)
	ldq	t10,	T10(v0)
	ldq	t11,	T11(v0)
	ldq	ra,	RA(v0)
	ldq	t12,	T12(v0)
	ldq	at,	AT(v0)
	ldq	gp,	GP(v0)
	ldq	t0,	PC(v0)
	ldq	v0,	V0(v0)

	wmb
	mb

	jmp	(t0)
