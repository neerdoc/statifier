/*
 * Copyright (C) 2004 Valery Reznic
 * This file is part of the Elf Statifier project
 * 
 * This project is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License.
 * See LICENSE file in the doc directory.
 */

/*
 * This program is "gdb_runner". It's aim to allow gdb to get
 * control BEFORE first loader's instruction executed.
 * The problem that no one is know where kernel will load loader.
 * With exec-shield and randomization it's ever more problematic.
 *
 * Idea is followig:
 * - set breakpoint on the execve
 * - run this program under gdb.
 * - when hit breakpoint gdb will do "single-instruction"
 *   and verify what next instruction is.
 *   When next instruction is "syscall" we are about to exec 
 *   "program of interest".
 *   One more "single-instruction" - and new program is loaded
 *   and waited for gdb. 
 *   Program counter now is REAL loader's entry point. 
 *
 * Implementation notes.
 * 1) This program should be linked static for the following reason:
 *    LD_PRELOAD libraries may interfere It's not desirable.
 *    But if i link progam static, gdb will give warning to stderr:
 *    warning: shared library handle failed to enable breakpoint
 *    I want avoid it, so i play with partial link
 *
 * 2) This program should be compiled with -g and should not be stripped
 *    Strictly speak it's needed only for alpha/mips, because otherwise
 *    gdb on this arch will give annoying warnings.
 *
 * 3) This program can't be run "standalone" - on the very begin it'll kill
 *    itself with "QUIT" signal.
 *    I do it in order to help gdb get control without messing with 
 *    looking for address for set breakpoint on.
 *    gdb have to catch this (i.e QUIT) signal with 
 *    'handle SIGQUIT stop nopass'
 *    So, when signal will be sent, gdb get control, 
 *    and gdb_runner will be stopped.
 *   From here gdb can do single-insruction steps.
 *    "nopass" disable delivering signal to the program,
 *    so it will not be killed but coninue executing.
 *
 * 4) Syscall instructions mnemonic (and binary representation)
 *    are changed from one processor to another.
 *    So when gdb looking for this instruction, gdb should take it into account
 */

#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#define MY_WRITE(arg) write(STDERR_FILENO, arg, strlen(arg))
int main(int argc, char *argv[], char *envp[])
{
	/* argv[1] - program to be execed. it can has an argument */

	const char *msg1 = ": can't execve '";
	const char *msg2 = "'\n";
	raise(SIGQUIT);
	execve(argv[1], &argv[1], envp);
	MY_WRITE(argv[0]);
	MY_WRITE(msg1);
	MY_WRITE(argv[1]);
	MY_WRITE(msg2);
	_exit(1);
}
