/*
  Copyright (C) 2004 Valery Reznic
  This file is part of the Elf Statifier project
  
  This project is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License.
  See LICENSE file in the doc directory.
*/

/*
 * This program create new load segment for the "pseudo_static" exe
 * Segment contains following:
 *    - changed elf header
 *    - changed phdrs
 *    - starter program, which restore registers
 *    - registers' values
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <elf.h>
#include <link.h> /* I need it for define ElfW() */

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

static int my_fseek(
		FILE *      file, 
		long        offset,
		const char *pgm_name,
		const char *file_name
)
{
	int result;
	result = fseek(file, offset, SEEK_SET);
	if (result == -1) {
		fprintf(
			stderr,
			"%s: Can't fseek in the file '%s' to the pos=%ld. Errno = %d (%s)\n",
			pgm_name, file_name, offset, errno, strerror(errno)
		);
		return -1;
	}
	return result;
}

void *my_malloc(size_t size, const char *item, const char *pgm_name)
{
	void *result;
	result = malloc(size);
	if (result == NULL) {
		fprintf(
			stderr,
			"%s: Can't malloc %lu byte for '%s'.\n",
			pgm_name, (unsigned long)size, item
		);
		return NULL;
	}
	return result;
}

static int get_ehdr_phdrs_and_shdrs(
	const char *path,
	const char *pgm_name,
	ElfW(Ehdr) *ehdr,
	ElfW(Phdr) **phdrs,
	ElfW(Shdr) **shdrs
)
{
	FILE *file;
	size_t result;
	size_t phdrs_size, shdrs_size;
	int    res = 0;

	file = my_fopen(path, "r", pgm_name);
	if (file == NULL) goto err_open;

	result = my_fread(ehdr, sizeof(*ehdr), file, "ehdr", path, pgm_name);
	if (result == 0) goto err_opened;

	if ( ehdr->e_phentsize == 0) {
		fprintf(
			stderr,
			"%s: in the file '%s' e_phentsize == 0\n",
			pgm_name, path
		);
		goto err_opened;
	}

	if ( ehdr->e_phnum == 0) {
		fprintf(
			stderr,
			"%s: in the file '%s' e_phnum == 0\n",
			pgm_name, path
		);
		goto err_opened;
	}
	if (phdrs != NULL) {
		phdrs_size = ehdr->e_phentsize * ehdr->e_phnum;
		*phdrs = my_malloc(phdrs_size, "phdrs", pgm_name);
		if (*phdrs == NULL) goto err_opened;

		if (my_fseek(file, ehdr->e_phoff, pgm_name, path) == -1) goto err_phdrs;
		if (my_fread(*phdrs, phdrs_size, file, "phdrs", pgm_name, path) == 0) goto err_phdrs;
	}

	if (shdrs != NULL) {
		shdrs_size = ehdr->e_shentsize * ehdr->e_shnum;
		*shdrs = my_malloc(shdrs_size, "shdrs", pgm_name);
		if (*shdrs == NULL) goto err_phdrs;

		if (my_fseek(file, ehdr->e_shoff, pgm_name, path) == -1) goto err_shdrs;
		if (my_fread(*shdrs, shdrs_size, file, "shdrs", pgm_name, path) == 0) goto err_shdrs;
	}
	res = 1;
	goto ret_ok;

err_shdrs:
	if (shdrs != NULL) free(*shdrs); 
err_phdrs:
	if (phdrs != NULL) free(*phdrs); 
err_opened:
ret_ok:
	fclose(file);
err_open:
	return res;
}

static off_t my_file_size(const char *path, const char *pgm_name, int *err)
{
	struct stat buf;
	int result;
	result = stat(path, &buf);
	if (result == -1) {
		*err = 1;
		fprintf(
			stderr,
			"%s: can't fstat file '%s'. Errno = %d (%s).\n",
			pgm_name, path, errno, strerror(errno)
		);
		return -1;
	}
	*err = 0;
	return buf.st_size;
}
int main(int argc, char *argv[])
{
	const char *pgm_name = argv[0];	
	const char *exe_in;   /* original exe filname */
	const char *core;     /* gdb's core filename */ 
	const char *starter;  /* starter's filename */
	ElfW(Ehdr) ehdr_exe;  /* Ehdr for original exe */
	ElfW(Ehdr) ehdr_core; /* Ehdr for core file */ 
	ElfW(Phdr) *phdrs_exe; /* Phdrs for orig file */
       	ElfW(Phdr) *phdrs_core; /* Phdrs for core file */ 
	ElfW(Phdr) *phdrs_out;  /* Phdrs for output file */
	ElfW(Shdr) *shdrs_exe;  /* Shdrs for orig exe */
	ElfW(Phdr) *ph_starter; /* Phdr pointer for the starter segment */

	const char *s_is_stack_under_executable; /* as string */
	const char *s_is_starter_under_executable; /* as string */
	int is_stack_under_executable;
	int is_starter_under_executable;
	int first_load_segment = 0;
	FILE *input;
	FILE *output = stdout;
	int result;
	size_t ind_out, num_seg_out;
	size_t num_load_segment_in_core;
	off_t  starter_pgm_size, file_size, starter_seg_size;
	static int err;
	const char *s_ignored_segments; /* Ignored segments, as string */
	int ignored_segments;           /* Ignored segments */ 
	int arg_ind;
	char *starter_segment, *cur_ptr;
	size_t cur_size;

	if (argc < 7) {
		fprintf(
			stderr, 
			"Usage: %s <exe_in> <gdb_core_file> <starter_program> <is_stack_under_executable> <is_starter_under_executable> <ignored_seg> <seg_file_1> [<seg_file_2>...]\n",
		       	pgm_name
		);
		exit(1);
	}

	arg_ind                       = 1;
	exe_in                        = argv[arg_ind++];
	core                          = argv[arg_ind++];
	starter                       = argv[arg_ind++];
	s_is_stack_under_executable   = argv[arg_ind++];
	s_is_starter_under_executable = argv[arg_ind++];
	s_ignored_segments            = argv[arg_ind++];

	is_stack_under_executable = atoi(s_is_stack_under_executable);
	if (is_stack_under_executable < 0) {
		fprintf(
			stderr,
			"%s: is_stack_under_executable='%s', should be >= 0\n",
			pgm_name, s_is_stack_under_executable
		);
		exit(1);
	}

	is_starter_under_executable = atoi(s_is_starter_under_executable);
	if (is_starter_under_executable < 0) {
		fprintf(
			stderr,
			"%s: is_starter_under_executable='%s', should be >= 0\n",
			pgm_name, s_is_starter_under_executable
		);
		exit(1);
	}

	ignored_segments = atoi(s_ignored_segments);
	if (ignored_segments <= 0) {
		fprintf(
			stderr,
			"%s: ignored_segment='%s', should be > 0\n",
			pgm_name, s_ignored_segments
		);
		exit(1);
	}

	if ( 
		get_ehdr_phdrs_and_shdrs(
			exe_in, 
			pgm_name, 
			&ehdr_exe,
			&phdrs_exe,
			&shdrs_exe
		) == 0
	) exit(1);

	if ( 
		get_ehdr_phdrs_and_shdrs(
			core, 
			pgm_name, 
			&ehdr_core, 
			&phdrs_core,
			NULL
		) == 0
	) exit(1);

	/* How many LOAD segments have we in the core ? */
	/* What's first load segment */
	num_load_segment_in_core = 0;
	{
		int i;
		for (i = 0; i < ehdr_core.e_phnum; i++) {
			if (phdrs_core[i].p_type == PT_LOAD) {
				if (num_load_segment_in_core == 0) {
					first_load_segment = i;
				}
				num_load_segment_in_core++;
			}
		}
	}

	/* Sanity */
	if (num_load_segment_in_core == 0) {
		fprintf(
			stderr,
			"%s: there are no PT_LOAD segments in the core '%s'.\n",
			pgm_name, core
		);
		exit(1);
	}

	/* Command line sanity */

	/*
	 * linux 2.5, 2.6 create one more segment
	 * gdb 6.0 save it in the core file, but gdb 6.1 not
	 * so check
	 * num_load_segment_in_core - ignored_segments) != (argc - arg_ind))
	 * not always correct.
	 * Let's try to use something less strict.
	 */
	if (
		((argc - arg_ind) >  num_load_segment_in_core) ||
		((argc - arg_ind) < (num_load_segment_in_core - ignored_segments))
	) {
		fprintf(
			stderr,
			"%s: mismatch: core file '%s' has %lu LOAD segments but command line supply ignored_segments='%d' and %d files\n",
			pgm_name,
			core,
			(unsigned long)num_load_segment_in_core,
			ignored_segments,
			argc - arg_ind
		);
		exit(1);
	}

	/* Segments number in the output file */
	num_seg_out = 
		  (argc - arg_ind)
		+ 1 /* My segment */
	;

	/* Get place for output phdrs */
	/*
	 * I'll allocate space for number of ALL segment's in the
	 * core file plus 1 for the starter segment.
	 * It's a bigger than strictly needed but it simplify logic
	 */
	phdrs_out = my_malloc(
		ehdr_core.e_phentsize * (ehdr_core.e_phnum + 1),
		"phdrs for output exe file",
		pgm_name
	);
	if (phdrs_out == NULL) exit(1);

	/* Fill appropriative entries in phdrs_out from the phdrs_core */ 
	{
		int i_core = first_load_segment + (is_stack_under_executable ? 1 : 0);
		int i_out = is_starter_under_executable ? 1 : 0;

		ElfW(Phdr) *ph_core = &phdrs_core[i_core];
		ElfW(Phdr) *ph_out  = &phdrs_out [i_out];
		for (; i_core < ehdr_core.e_phnum; i_core++, ph_core++) {
			if (ph_core->p_type == PT_LOAD) {
				ph_out->p_type   = PT_LOAD;
				/* p_offset - to be fill later */
				ph_out->p_vaddr  = ph_core->p_vaddr;
				ph_out->p_paddr  = ph_core->p_vaddr;
				ph_out->p_flags  = ph_core->p_flags;
				/*
				 * I have no information about alinment,
				 * but because it's a dump from the memory
				 * and loader had align it correctly,
				 * I can not 're-align' it.
				 * So, let say align = 1, i.e no align
				 */ 
				ph_out->p_align = 1; 	
				ph_out++;
			}
		}
		/* Fill more entries in phdrs_out */ 
		ph_out  = &phdrs_out[i_out];
		for (; arg_ind < argc; arg_ind++, ph_out++) {
			file_size = my_file_size( /* get file size */
					argv[arg_ind], 
					pgm_name, 
					&err
			);
			if (err != 0) exit(1);
			ph_out->p_filesz = file_size;
			ph_out->p_memsz  = file_size;
		}
	}

	/* Fill data for the starter segment */
	ph_starter = &phdrs_out[is_starter_under_executable ? 0 : (num_seg_out-1) ];
	ph_starter->p_type = PT_LOAD; 
	/* Find alignment for the executable code */
	ph_starter->p_align = -1; /* no alignment */
	{
		int i;
		for (i = 0; i < ehdr_exe.e_phnum; i++) {
			if (phdrs_exe[i].p_type == PT_LOAD) {
				if (phdrs_exe[i].p_flags & PF_X) {
					ph_starter->p_align = phdrs_exe[i].p_align;
				}
			}
		}
	}

	starter_pgm_size = my_file_size(starter, pgm_name, &err);
	if (err != 0) exit(1);

	/* Starter seg size is elf header size + size of all phdrs + 
	 * + size of all shdrs + starter program size
	 */
	starter_seg_size =
		sizeof(ehdr_exe)                        + 
		ehdr_exe.e_shnum * ehdr_exe.e_shentsize +
	       	num_seg_out      * sizeof(*ph_starter)  +
		starter_pgm_size
	;

	/* Now round it up to the align boundary if needed*/
	{
		size_t rest;
		rest = starter_seg_size % ph_starter->p_align;
		if (rest) starter_seg_size += (ph_starter->p_align - rest);
	}

	ph_starter->p_filesz = starter_seg_size;
	ph_starter->p_memsz  = starter_seg_size;
	ph_starter->p_flags  = PF_X | PF_R; 

	if (is_starter_under_executable) {
		/* i.e ph_starter == &phdrs_out[0] */
		ph_starter->p_vaddr = phdrs_out[1].p_vaddr - ph_starter->p_align;
		ph_starter->p_paddr = ph_starter->p_vaddr;
		ph_starter->p_offset = 0;
	} else {
		/* i.e ph_starter is last segment */
		ph_starter->p_vaddr = 
			phdrs_out[num_seg_out - 2].p_vaddr + 
			phdrs_out[num_seg_out - 2].p_memsz
		;
		ph_starter->p_vaddr = ph_starter->p_paddr;
		/* I guess here first exe segment contain also ehdr and phdrs */
		phdrs_out[0].p_offset = 0;
	}

	/* Fill offset field  for all but first segment */
	for (ind_out = 1; ind_out < num_seg_out; ind_out++) {
		phdrs_out[ind_out].p_offset = 
			phdrs_out[ind_out - 1].p_offset + 
			phdrs_out[ind_out - 1].p_filesz
		;
	}

	/* Adjust shdrs */
	/* Needed Only if starter_under_executable */
	if (is_starter_under_executable) {
		for (ind_out = 0; ind_out < ehdr_exe.e_shnum; ind_out++) {
			shdrs_exe[ind_out].sh_offset += starter_seg_size;
		}
	}

	/* Adjust Ehdr */
	ehdr_exe.e_entry = 
		ph_starter->p_vaddr                     +
		sizeof(ehdr_exe)                        + 
		num_seg_out * sizeof(*ph_starter)       + 
		ehdr_exe.e_shentsize * ehdr_exe.e_shnum
	;
	ehdr_exe.e_phoff = ph_starter->p_offset + sizeof(ehdr_exe);
	ehdr_exe.e_shoff = ehdr_exe.e_phoff + num_seg_out * sizeof(*ph_starter);
	ehdr_exe.e_phnum = num_seg_out;

	/* Allocate space for the starter segment */
	starter_segment = my_malloc(starter_seg_size, "starter_segment", pgm_name);
	if (starter_segment == NULL) exit(1);
	memset(starter_segment, 0, starter_seg_size);

	cur_ptr  = starter_segment;
	cur_size = sizeof(ehdr_exe);
	memcpy(cur_ptr, &ehdr_exe, cur_size);
	cur_ptr += cur_size;
	cur_size = num_seg_out * sizeof(*ph_starter);
	memcpy(cur_ptr, phdrs_out, cur_size);
	/* Add schdrs */
	cur_ptr += cur_size;
	cur_size = ehdr_exe.e_shentsize * ehdr_exe.e_shnum;
	memcpy(cur_ptr, shdrs_exe, cur_size);

	/* Read starter program in */
	cur_ptr += cur_size;
	input = my_fopen(starter, "r", pgm_name);
	if (input == NULL) exit(1);

	result = my_fread(cur_ptr, starter_pgm_size, input, "all file", starter, pgm_name);
	if (result == 0) exit(1);
	fclose(input);

	fwrite(starter_segment, 1, starter_seg_size, output);
	
 	exit(0);
	return 0;
}
