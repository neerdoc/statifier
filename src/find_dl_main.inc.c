/*
 * Copyright (C) 2004 Valery Reznic
 * This file is part of the Elf Statifier project
 * 
 * This project is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License.
 * See LICENSE file in the doc directory.
 */

/*
 * NOTE: PURPOSE OF THIS PROGRAM IS FIND OUT LOADER'S VARIABLES ADDRESSES,
 * SO IT MUST BE LINKED DYNAMICALLY !!!
 */

/*
 * Problem description:
 *   Starter (used in statified program) need to adjust values of
 *   some loaders variable.
 *   For now they are:
 *   _dl_argc, _dl_argv, _environ, _dl_auxv, _dl_platform and _dl_platformlen.
 * Last two are optional, not every loader has it.
 *
 * In order to be able adjust variable's values I have find out variable's
 * addresses.
 *
 * Sure, the simplest way is have a lookup in the loader's symbol table,
 * but unfortunally, there are a lot of distributions with stripped loader,
 * so, it's not always possible.
 *
 * Ok, what I am going to do when there is no symbol table ?
 *
 * Before I'll answer this questions, let's ask another one:
 * why adjustment is needed at all ? 
 *
 * Adjustment is needed because these values may be different from
 * one invocation to another: number of arguments may be differnt,
 * arguments themselves and environment.
 * 
 * So, solution is following: 
 *  for current invocation find value of variable (argc for example)
 *  and try to find it in the loader's read/write memory.
 * If not found - simple exit(0) and print nothing.
 * If found - reinvoce itself with additional arguments and once again
 * try to find it. If it found in the same place - it's looks like
 * we found correct address. Print it out and exit.
 * Otherwise reinvoce itself with additional arguments again.
 */

/*
 * dl_platformlen can not be found this way, because it does not changed from
 * one invocation to another. 
 * There is only one case, when we need change this variable: executable
 * was statified on one platform nd after than run on the other computer,
 * which different platform name and different platform length.
 * For example i386 and i686 lucky have same length, but i386 and athlon -
 * different.
 * In any case dl_platform and dl_platformlen go away in the latest loaders,
 * so let us leave dl_platform as is.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

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
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

int main(int argc, char *argv[], char *envp[])
{
	/* Program's arguments */
	const char *found_s; /*
                              * Offset from the begin of loader's
                              * READ/WRITE segment, where pattern
                              * was found.
			      * on first invocation should be -1 
                              * i.e no pattern found (yet)
                              * This offset may be only increased
                              * from invocation to invocation
                              * I need to pass this argument to be sure
                              * my search will terminated and not
                              * jump backward/forward forever
                              */

	const char *base_s;   /* 
                               * loader's base address (real address)
                               * As always I hope it not changed from
                               * invocation to invocaton
                               */

	const char *virt1_s;  /*
                               * loaders's virtual address. (Usually 0)
                               */

	const char *virt2_s;  /*
                               * loader's READ/WRITE segment wirtual address
                               */

	const char *size_s;   /* loader READ/WRITE segment's size */

	/* Arguments'es converted value */
	unsigned long found;
	unsigned long base;
	unsigned long virt1;
	unsigned long virt2;
	unsigned long size;

	unsigned long new_found; /* nw offset for pattern */

	unsigned char *start_ptr; /* real start address of loader's READ/WRITE
				     segment */
	unsigned char *end_ptr;   /* real end address of loader's READ/WRITE
				     degment */
	unsigned char *ptr;	  /* current pointer */

	pgm_name = argv[0]; 

	if (argc < 6) {
		fprintf(
			stderr,
			"Usage: %s <found> <base> <virt1> <virt2> <size> <dummy 1> [ <dummy2> ...]\n",
			pgm_name
		);
		exit(1);
	}

	found_s = argv[1];
	base_s  = argv[2];
	virt1_s = argv[3];
	virt2_s = argv[4];
	size_s  = argv[5];

			
	found = my_strtoul(found_s);
	base  = my_strtoul(base_s );
	virt1 = my_strtoul(virt1_s);
	virt2 = my_strtoul(virt2_s);
	size  = my_strtoul(size_s );

	/* Calculate real address for loader's READ/WRITE segment */
 	start_ptr = (unsigned char *)(base + (virt2 - virt1));
	/* Address after the end of loader's READ/WRITE segment */
	end_ptr   = start_ptr + size;

	if (found == (unsigned long)-1L) { /* first invocation */
		ptr = start_ptr;
	} else {
		ptr = start_ptr + found;
	}

	/* Init my_patter variable if this function return
	 * non-zero - we have nothing to look for.
	 * So, just exit(0) and print nothing */
	if (init_my_pattern(argc, argv, envp)) exit(0);

	/* Look for my_pattern in the loader's READ/WRITE memory */
	for (; (ptr + sizeof(my_pattern)) < end_ptr; ptr++) {
		if (memcmp(&my_pattern, ptr, sizeof(my_pattern)) == 0) {
			break; /* Pattern found */
		}
	}

	if (ptr == end_ptr) {
		/* Pattern not found exit with status 0 and print nothing */
		exit(0);
	}

	/* Pattern found */
	new_found = ptr - start_ptr; /* Calculate new offset */
	if (new_found == found) { /* Pattern found at same offset !
				     I find this address ! */
		printf("%p\n", ptr);
		exit(0);
	} 

	/*
	 * No, it was found in the different offset,
	 * so it may be just occasionly.
	 * Let's run us again with bigger arguments number.
	 */
	{
		char found_buf[100];
		/* 
		 * Array of additional arguments to be appended to
		 * original argv
		 * I make it NULL terminated, because execve need NULL
		 * as last element in the argv array
		 */
		char *add_argv[] = {
			"0", "1", "2", "3", "4",
			"5", "6", "7", "8", "9",
			NULL
		};
		char *new_argv[argc + ARRAY_SIZE(add_argv)];
		int ind;

		/* Copy all current argv to the new one */ 
		for (ind = 0; ind < argc; ind++) {
			new_argv[ind] = argv[ind];
		}

		/* Append additional arguments */
		for (ind = 0; ind < ARRAY_SIZE(add_argv); ind++) {
			new_argv[argc + ind] = add_argv[ind];
		}

		/* Convert new_found to ascii, so it can be used as arg */
		snprintf(found_buf, sizeof(found_buf), "0x%lx", new_found);

		/* Change first program's argument (i.e found) to the new
		 * value */
		new_argv[1] = found_buf;

		/* Run us again */
		execve(new_argv[0], new_argv, envp);

		/* 
		 * I should not get here, unless execve failed.
		 * Let's give error message and exit(1);
		 */
		fprintf(
			stderr,
			"%s: can't execve - '%s' (errno = %d)\n",
			pgm_name, 
			strerror(errno),
			errno
		);
		fprintf(stderr, "%s: command line: ['", pgm_name);
		/* Print all but last (i.e NULL) elements */
		for (ind = 0; ind < (ARRAY_SIZE(new_argv) - 1); ind++) {
			fprintf(stderr, "%s%s", ind ? " " : "", new_argv[ind]);
		} 
		fprintf(stderr, "']\n");
	}
	exit(1);
}
