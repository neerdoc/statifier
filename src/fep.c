/*
 * Copyright (C) 2004 Valery Reznic
 * This file is part of the Elf Statifier project
 * 
 * This project is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License.
 * See LICENSE file in the doc directory.
 */

/*
 * This file try find place for starter in the specified file.
 * On success starter's entry point is printed to stdout.
 */

#include "./my_lib.inc.c"
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


int main(int argc, char *argv[])
{
	const char *elf_name;
	const char *s_start_addr;
	const char *starter_name;
	off_t starter_size;
	int err;
	int i;
	int first = 1;
	unsigned long start_addr;
	unsigned long rest;
	ElfW(Ehdr) ehdr;         /* Ehdr */
	ElfW(Phdr) *phdrs;       /* Phdrs */

	pgm_name = argv[0];	
	if (argc != 4) {
		fprintf(
			stderr, 
			"Usage: %s <elf_file> <start_addr> <starter>\n",
		       	pgm_name
		);
		exit(1);
	}

	elf_name     = argv[1];
	s_start_addr = argv[2];
	starter_name = argv[3];

	start_addr = my_strtoul(s_start_addr);

	/* Get ehdr, phdrs and shdrs from elf_file */
	if ( 
		get_ehdr_phdrs_and_shdrs(
			elf_name,
			&ehdr,
			&phdrs,
			NULL,
			NULL,
			NULL
		) == 0
	) exit(1);

	/* Get starter's size */
	starter_size = my_file_size(starter_name, &err);
	if (err == -1) exit(1);

	/* 
	 * I want starter aligned on the 16 boundary,
	 * For some (perfomance ? ) reason so do kernel with a stack
	 * So, let us round up starter_size
	 */ 
	rest = starter_size % 16;
	if (rest) starter_size += (16 - rest);

	/* Try to find segment, which has enought room to host starter */
	for (i = 0; i < ehdr.e_phnum; i++) {
		unsigned long total_space;
		unsigned long used_space;
		unsigned long unused_space;
		unsigned long file_start_addr;
		unsigned long e_entry;

		/* Look for PT_LOAD segment */
		if (phdrs[i].p_type != PT_LOAD) continue;

		if (first) {
			/* Save v_addr for the first PT_LOAD segment */
			first = 0;
			file_start_addr = phdrs[i].p_vaddr;
		}
		/* Look for segment with PF_X permissions */
		if ( (phdrs[i].p_flags & PF_X) == 0) continue;

		/* Have many space used in this segment ? */ 
		used_space = phdrs[i].p_memsz; /* 
						* ok, usually for exec seg
						* p_memsz == p_filesz.
						* But I want to be on the 
						* safe side...
						*/ 
		/* Segment's total space */
		total_space = used_space;
		rest = used_space % phdrs[i].p_align;
		if (rest) total_space += (phdrs[i].p_align - rest);

		/* How many unused space left here ? */
		unused_space = total_space - used_space;

		/* Have we got enougth unused space here ? */ 
		if (unused_space < starter_size) continue;

		/* Ok, got it ! */
		 e_entry = 
			 /* base addr */
			 start_addr + 
			 /* Offset to the needed segment */
			 (phdrs[i].p_vaddr - file_start_addr) + 
			 /* offset in the segment to starter */
			 used_space
		;

		printf("0x%lx\n", e_entry);
		break;
	}	
 	exit(0);
}
