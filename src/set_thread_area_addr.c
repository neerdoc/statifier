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
#include <sys/wait.h>
#include <sys/syscall.h>

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

#undef REGISTER_SIZE
#ifdef __i386__
	#define REGISTER_SIZE 4
	#define SYSCALL_REG   (ORIG_EAX)
	#define PC_REG        (EIP)
	#define PC_OFFSET_AFTER_SYSCALL 2
#endif
#ifdef __x86_64__
	#define REGISTER_SIZE 8
	#define SYSCALL_REG   (ORIG_RAX)
	#define PC_REG        (RIP)
	#define PC_OFFSET_AFTER_SYSCALL 2
#endif

#ifndef REGISTER_SIZE
	#error This cpu not supported (yet)
#endif

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

void do_work(const char *name, const pid_t child)
{
	int stat;
	unsigned long pc_val, syscall_val;
	static int first = 1;
	while(1) {
		wait(&stat);
		if (WIFEXITED(stat)) {
			exit(WEXITSTATUS(stat));
		}
		if (WIFSIGNALED(stat)) {
			exit(128 + WTERMSIG(stat));
		}
	
		if (WIFSTOPPED(stat)) {
			if (first) {
				first = 0;
			} else {
				one_get_syscall_reg(name, child, &syscall_val);
				if (syscall_val == __NR_set_thread_area) {
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
			do_work(argv[0], child);
		break;
	}
	exit(0);
}
#endif
