/*
 * Copyright (C) 2004 Valery Reznic
 * This file is part of the Elf Statifier project
 * 
 * This project is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License.
 * See LICENSE file in the doc directory.
 */

/*
 * This program try to find pattern passed as sequience of byte
 * from the command line in the specified (from the command line)
 * elf file. Search begin from the elf file's entry point (e_entry)
 */

#include "./my_lib.inc.c"
#include <limits.h>

static unsigned char *my_fread_from_position(
		const char *path,
		long        offset, 
		size_t      size,
		const char *item
)
{
	FILE *input;
	int result;
	unsigned char *data;

	data = my_malloc(size, item);
	if (data == NULL) exit(1);

	input = my_fopen(path, "r");
	if (input == NULL) exit(1);

	result = my_fseek(input, offset, path);
	if (result == -1) exit(1);

	result = my_fread(data, size, input, item, path);
	if (result == -1) exit(1);

	result = my_fclose(input, path);
	if (result == -1) exit(1);

	return data;
}

int main(int argc, char *argv[])
{
	ElfW(Ehdr) ehdr;
	ElfW(Phdr) *phdrs;
	ElfW(Phdr) *ph;
	const char *loader;
	unsigned char *pattern;
	unsigned char *data;
	char *endptr;
	int arg_ind = 0;
	int pattern_size; 
	int ind;

	const unsigned long SIZE_FOR_LOOKUP = 20;

	pgm_name = argv[arg_ind++];	
	if (argc < 3) {
		fprintf(
			stderr, 
			"Usage: %s <loader> <byte1> [<byte2>...]\n",
		       	pgm_name
		);
		exit(1);
	}

	loader = argv[arg_ind++];
	pattern_size = argc - arg_ind;
	pattern = my_malloc(pattern_size, "pattern");
	if (pattern == NULL) exit(1);
	for (ind = 0; ind < pattern_size; ind++, arg_ind++) {
		const char *current;
		unsigned long value;
		current = argv[arg_ind];
		value = strtoul(current, &endptr, 0);
		if ( (*endptr != 0) || *current == 0) {
			fprintf(
				stderr, 
				"%s: '%s' can't be converted with strtoul\n",
				pgm_name,
				current
			);
			exit(1);
		}
		if (value > UCHAR_MAX) {
			fprintf(
				stderr,
				"%s: '%s' is bigger than max '%d'\n",
				pgm_name, current, UCHAR_MAX
			);
			exit(1);
		}
		pattern[ind] = (unsigned char)value;
	}

	if ( 
		get_ehdr_phdrs_and_shdrs(
			loader, 
			&ehdr,
			&phdrs,
			NULL,
			NULL,
			NULL
		) == 0
	) exit(1);

	for (ind = 0, ph = phdrs; ind < ehdr.e_phnum; ind++, ph++) {
		if (ph->p_type != PT_LOAD) continue;
		if (
			(ph->p_vaddr                  <= ehdr.e_entry) &&
			((ph->p_vaddr + ph->p_filesz) >= ehdr.e_entry)
		) {
			break;
		}
	}

	if (ind == ehdr.e_phnum) {
		fprintf(
			stderr,
			"%s: No PT_LOAD segment contain e_entry=0x%x\n",
			pgm_name,
			ehdr.e_phnum
		);	
		exit(1);
	}

	data = my_fread_from_position(
			loader, 
			ph->p_offset + (ehdr.e_entry - ph->p_vaddr), 
			SIZE_FOR_LOOKUP, 
			"e_entry nearby area"
	);
	if (data == NULL) exit(1);

	for (ind = 0; ind < (SIZE_FOR_LOOKUP - pattern_size); ind++) {
		if (memcmp(data + ind, pattern, pattern_size) == 0) {
			printf("0x%x\n", ehdr.e_entry + ind);
			exit(0);
		}	
	}
	fprintf(
		stderr,
		"%s: can't find specified pattern e_entry=0x%x\n",
		pgm_name,
		ehdr.e_entry
	);
 	exit(1);
	return 1;
}