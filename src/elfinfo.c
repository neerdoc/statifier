/*
  Copyright (C) 2004 Valery Reznic
  This file is part of the Elf Statifier project
  
  This project is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License.
  See LICENSE file in the doc directory.
*/

/*
 * This program print out "ELF" if elf and nothing if not
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <elf.h>
#include <link.h>

static FILE *my_fopen(
	const char *path,
	const char *mode,
	const char *pgm_name
)
{
	FILE *file;
	file = fopen(path, mode);
	if (file == NULL) {
		fprintf(
			stderr,
			"%s: Can't open '%s' file. Errno = %d (%s)\n",
		        pgm_name, path, errno, strerror(errno)
		);	
		return NULL;
	}
	return file;
}

static size_t my_fread(
		void *      ptr, 
		size_t      nmemb, 
		FILE *      file, 
		const char *item,
		const char *pgm_name,
		const char *file_name
)
{
	size_t result;
	result = fread(ptr, 1, nmemb, file);
	if (result != nmemb) {
		fprintf(
			stderr, 
			"%s: can't read '%s' from file '%s'. Errno=%d, (%s).\n",
			pgm_name, item, file_name, errno, strerror(errno)
		);
		return 0;
	}	
	return result;
}

int main(int argc, char *argv[])
{
	FILE *input;
	ElfW(Ehdr) ehdr;
	int result;
	const char *pgm_name = argv[0];	
	const char *file_name;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s <file_name>\n", pgm_name);
		exit(1);
	}

	file_name = argv[1];

	input = my_fopen(file_name, "r", pgm_name);
	if ( input == NULL) exit(1);

	result = my_fread(
			&ehdr, 
			sizeof(ehdr), 
			input, 
			"ehdr", 
			file_name, 
			pgm_name
	);
	if (result == 0) exit(1);
	fclose(input);

	if (
		(ehdr.e_ident[EI_MAG0] == ELFMAG0) &&
		(ehdr.e_ident[EI_MAG1] == ELFMAG1) &&
		(ehdr.e_ident[EI_MAG2] == ELFMAG2) &&
		(ehdr.e_ident[EI_MAG3] == ELFMAG3)
	) {
		printf("ELF\n");
	}

 	exit(0);
	return 0;
}
