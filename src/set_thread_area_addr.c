/*
  Copyright (C) 2004 Valery Reznic
  This file is part of the Elf Statifier project
  
  This project is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License.
  See LICENSE file in the doc directory.
*/

/*
 * This program should print to stdout 
 * offset to system call __NR_set_thread_area
 * in the loader (offset is relative to the loader's base address
 */ 
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ptrace.h>
#ifdef __alpha__
   #include <asm/reg.h>
#else
   #include <sys/reg.h>
#endif
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

static const char *pgm_name;

unsigned long my_strtoul(const char *string)
{
	unsigned long result;
	char *endptr;
	result = strtoul(string, &endptr, 0);
	if ( (*endptr != 0) || *string == 0) {
		fprintf(
			stderr,
			"%s: '%s' can't be converted with strtoul\n",
			pgm_name,
			string
		);
		exit(1);
	}
	if (errno != 0) {
		fprintf(
			stderr,
			"%s: '%s' - overflow in strtoul\n",
			pgm_name,
			string
		);
		exit(1);
	}
	return result;
}
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

void do_work(
		const char *name, 
		const char *process, 
		const pid_t child, 
		unsigned long loader_file_entry_point
)
{
	int stat;
	unsigned long loader_entry_point, pc_val, syscall_val;
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
				one_get_pc_reg(name, child, &loader_entry_point`);
			} else {
				one_get_syscall_reg(name, child, &syscall_val);
				if (syscall_val == syscall_num) {
					one_get_pc_reg(name, child, &pc_val);
					printf("0x%lx\n", pc_val - PC_OFFSET_AFTER_SYSCALL - (loader_entry_point - loader_file_entry_point));
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
	const char *program;
	const char *s_loader_file_entry_point;
	unsigned long loader_file_entry_point;

	pid_t child;
	long int long_res;

	pgm_name = argv[0];
	if (argc != 3) {
		fprintf(
			stderr, 
			"Usage: %s <loader_file_entry_point> <program>\n", 
			pgm_name
		);
		exit(1);
	}

	s_loader_file_entry_point = argv[1];
	program = argv[2];
	loader_file_entry_point = my_strtoul(s_loader_file_entry_point);

	child = fork();
	switch(child) {
		case 0: /* It's child */
			long_res = ptrace(PTRACE_TRACEME, 0, 0, 0);
			if (long_res == -1) {
				fprintf(
					stderr,
					"%s (child): can't PTRACE_TRACEME errno=%d (%s)\n",
					pgm_name, errno, strerror(errno)
				);
				exit(1);
			}
			execve(program, &argv[2], envp);
			fprintf(
				stderr,
				"%s (child): can't execve '%s' errno=%d (%s)\n",
				pgm_name, program, errno, strerror(errno)
			);
			exit(1);
		break;

		case -1: /* error in the parent */
			fprintf(
				stderr, 
				"%s: Can't fork: errno=%d (%s)\n",
				pgm_name, errno, strerror(errno)
			);
		exit(1);

		default: /* Parent */
			do_work(
				pgm_name, 
				program, 
				child, 
				loader_file_entry_point
			);
		break;
	}
	exit(0);
}
#endif
