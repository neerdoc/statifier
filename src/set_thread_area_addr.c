/*
  Copyright (C) 2004 Valery Reznic
  This file is part of the Elf Statifier project
  
  This project is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License.
  See LICENSE file in the doc directory.
*/

/*
 * This program should print to stdout 
 * address of system call __NR_set_thread_area
 */ 
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ptrace.h>
#include <sys/reg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/syscall.h>
#include "processor.h"

#ifndef __NR_set_thread_area
int main(int argc, char *argv[0])
{
	fprintf(
		stderr, 
		"%s: this program built on the platform without THREAD LOCAL STORAGE (TLS) support.\n",
		argv[0]
	);
	exit(1);
}
#else

void one_syscall(const char *name, pid_t child)
{
	long int res;
	res = ptrace(PTRACE_SYSCALL, child, 0, 0);
	if (res == -1) {
		fprintf(
			stderr,
			"%s: can't ptrace syscall: errno=%d (%s)\n",
			name, errno, strerror(errno)
		);
		ptrace(PTRACE_KILL, child, 0, 0);
		exit(1);
	}
}

void one_getreg(const char *name, pid_t child, long reg, unsigned long *result)
{
	*result = ptrace(PTRACE_PEEKUSER, child, REGISTER_SIZE * reg, 0);
	if (errno != 0) {
		fprintf(
			stderr,
			"%s: can't ptrace peekuser: errno=%d (%s)\n",
			name, errno, strerror(errno)
		);
		ptrace(PTRACE_KILL, child, 0, 0);
		exit(1);
	}
}

#define one_get_syscall_reg(name, child, result) \
	one_getreg(name, child, SYSCALL_REG, result)

#define one_get_pc_reg(name, child, result) \
	one_getreg(name, child, PC_REG, result)

void do_work(const char *name, const char *process, const pid_t child)
{
	int stat;
	unsigned long pc_val, syscall_val;
	const unsigned long syscall_num = __NR_set_thread_area;
	static int first = 1;
	while(1) {
		wait(&stat);
		if (WIFEXITED(stat)) {
			if (WEXITSTATUS(stat)) {
				fprintf(
					stderr,
					"%s: '%s' exited with status=%d without execute syscall 'set_thread_area' (%ld)\n",
					name,
		       			process,
					WEXITSTATUS(stat),
					syscall_num
				);
				exit(1);
			} else {
				exit(0);
			}
		}
		if (WIFSIGNALED(stat)) {
			fprintf(
				stderr,
				"%s: '%s' killed by signal=%d without pass syscall 'set_thread_area' (%ld)\n",
				name,
		       		process,
				WTERMSIG(stat),
				syscall_num
			);
			exit(1);
		}
	
		if (WIFSTOPPED(stat)) {
			if (first) {
				first = 0;
			} else {
				one_get_syscall_reg(name, child, &syscall_val);
				if (syscall_val == syscall_num) {
					one_get_pc_reg(name, child, &pc_val);
					printf("0x%lx\n", pc_val - PC_OFFSET_AFTER_SYSCALL);
					ptrace(PTRACE_KILL, child, 0, 0);
					exit(0);
				}
			}
			one_syscall(name, child);
			continue;
		}
		fprintf(stderr, "%s: unexpected case\n", name);
		exit(1);
	}	
}	

int main(int argc, char *argv[], char *envp[])
{
	pid_t child;
	long int long_res;
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <program>\n", argv[0]);
		exit(1);
	}
	child = fork();
	switch(child) {
		case 0: /* It's child */
			long_res = ptrace(PTRACE_TRACEME, 0, 0, 0);
			if (long_res == -1) {
				fprintf(
					stderr,
					"%s (child): can't PTRACE_TRACEME errno=%d (%s)\n",
					argv[0], errno, strerror(errno)
				);
				exit(1);
			}
			execve(argv[1], &argv[1], envp);
			fprintf(
				stderr,
				"%s (child): can't execve '%s' errno=%d (%s)\n",
				argv[0], argv[1], errno, strerror(errno)
			);
			exit(1);
		break;

		case -1: /* error in the parent */
			fprintf(
				stderr, 
				"%s: Can't fork: errno=%d (%s)\n",
				argv[0], errno, strerror(errno)
			);
		exit(1);

		default: /* Parent */
			do_work(argv[0], argv[1], child);
		break;
	}
	exit(0);
}
#endif
