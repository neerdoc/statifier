/*
 * Copyright (C) 2004 Valery Reznic
 * This file is part of the Elf Statifier project
 * 
 * This project is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License.
 * See LICENSE file in the doc directory.
 */

/*
 * This program create "non-load part" of the output executable
 * It contains following:
 *    - changed elf header
 *    - all non-allocated sections from original exe
 *    - changed shdrs from original exe
 *    - phdrs for all PT_LOAD segments 
 *    - filler to the alignment boundary. Alignment is alignment for the
 *      first orig exe's PT_LOAD segment
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

/* Different common variables */
static ElfW(Ehdr) ehdr_exe;         /* Ehdr for original exe */
static ElfW(Ehdr) ehdr_out;         /* Ehdr for oitput   exe */

static ElfW(Phdr) *phdrs_exe;       /* Phdrs for original exe */
static ElfW(Shdr) *shdrs_exe;       /* Shdrs for original exe */
static ElfW(Shdr) *shdrs_out;       /* Shdrs for original exe */

static size_t phdrs_size_exe;      /* size of phdrs for original exe */
static size_t shdrs_size_exe;      /* size of shdrs for original exe */

/* End of variables */

static int create_sections()
{
#if 0
	/* Adjust shdrs */
	/* Sections which are not allocated, should be copied from
	 * the original executable and appended to the end of 
	 * statified exe and thiir offset should be calculated.
	 * Sections which are allocated already present in the statified
	 * exe (as part of PT_LOAD segments).
	 * If starter is under executable, their offset should be increased
	 * by starter_seg_size.
	 * If starter is above executable nothing should be done for
	 * allocated sections.
	 * Here I assume that ALL not allocated sections after ALL allocated
	 * ones. It's looks like reasonable from the linker/loader
	 * points of view, but to be sure I'll need to do more 
	 * accurate chech here.
	 * NOTE: for now I'll trust allocation flag in the p_flags.
	 *       but may be I'll need to verify section offset and
	 *       PT_LOAD segments offset
	 */
	FILE *input;            /* input File for original exe */
	FILE *output;           /* output file for sections */

	ElfW(Off) sh_offset;    /* Current section offset 
				   for non-allocateid sections */
	ElfW(Shdr) *shdrs_out;  /* Shdrs for output exe */
	ElfW(Shdr) *shdr;       /* Pointer to the current shdr */

	char *section_buf;      /* Buffer to hold non-allocated section */

	int result;             /* result for my_fread/my_fwrite */
	size_t ind;             /* loop index */
	size_t shdrs_size_out;  /* shdrs size for the output file */

	/* Duplicate shdrs_size_exe to shdrs_size_out */ 
	shdrs_size_out = shdrs_size_exe;
	/* Duplicate shdrs_exe to shdrs_out */ 
	shdrs_out = my_malloc(shdrs_size_out, "shdrs output size");
	if (shdrs_out == NULL) exit(1);
	memcpy(shdrs_out, shdrs_exe, shdrs_size_exe);

	sh_offset = ehdr_out.e_shoff + shdrs_size_out; /* here first section
							  to be copied begin */
	/* Adjust/calculate sections offsets */
	for (ind = 0, shdr = shdrs_out; ind < ehdr_exe.e_shnum; ind++, shdr++) {
		if (shdr->sh_flags & SHF_ALLOC) { /* Allocated section */
			if (is_starter_under_executable) { 
				shdr->sh_offset += starter_seg_size;
			}
		} else { /* Not allocated section */
			shdr->sh_offset = sh_offset;
			sh_offset += shdr->sh_size;
		}
	}

	/* Open orig exe */
	input = my_fopen(exe_in, "r");
	if (input == NULL) exit(1);

	/* Open sections for output */
	output = my_fopen(sections, "w");
	if (output == NULL) exit(1);

	/* Write shdrs to output */
	result = my_fwrite(shdrs_out, shdrs_size_out, output, "shdrs", sections);
	if (result == -1) exit(1);

	/* Copy all non-allocated sections from orig exe to sections file */
	for (ind = 0, shdr = shdrs_out; ind < ehdr_exe.e_shnum; ind++, shdr++) {
		if (shdr->sh_flags & SHF_ALLOC) continue;
		if (shdr->sh_size == 0) continue;

		/* Locate section in the input file */
		result = my_fseek(input, shdrs_exe[ind].sh_offset, exe_in);
		if (result == -1) exit(1);

		/* Allocate space for it */
		section_buf = my_malloc(shdr->sh_size, "section buffer");
		if (section_buf == NULL) exit(1);

		/* Read section */
		result = my_fread(section_buf, shdr->sh_size, input, "section", exe_in);
		/* Write section */
		if (result == -1) exit(1);
		result = my_fwrite(section_buf, shdr->sh_size, output, "section", sections);
		if (result == -1) exit(1);

		/* Free buffer */
		free(section_buf);
	}
	/* Close output */
	result = my_fclose(output, sections);
	if (result == -1) exit(1);
#endif
 	return 0;
}

int main(int argc, char *argv[])
{
	const char *exe_in;
	const char *phdrs_name;
	const char *e_entry;
	char *phdrs_out;
	off_t phdrs_size;
	int res;
	int pt_load_num;
	int non_pt_load_num = 0;
	off_t pt_load_offset;
	off_t non_alloc_sections_size;
	off_t end_of_non_alloc_sections;
	unsigned long align = 0;
	unsigned long fill_size;
	pgm_name = argv[0];	
	if (argc != 4) {
		fprintf(
			stderr, 
			"Usage: %s <orig_exe> <phdrs> <e_entry>\n",
		       	pgm_name
		);
		exit(1);
	}

	exe_in     = argv[1];
	phdrs_name = argv[2];
	e_entry    = argv[3];

	/* Get ehdr, phdrs and shdrs from original exe */
	if ( 
		get_ehdr_phdrs_and_shdrs(
			exe_in, 
			&ehdr_exe,
			&phdrs_exe,
			&phdrs_size_exe,
			&shdrs_exe,
			&shdrs_size_exe
		) == 0
	) exit(1);

	/* Find executable's PT_LOA segment align */
	{
		int i;
		for (i = 0; i < ehdr_exe.e_phnum; i++) {
			if (phdrs_exe[i].p_type == PT_LOAD) {
				align = phdrs_exe[i].p_align;
				break;
			}
		}
		if (align == 0) {
			fprintf(
				stderr,
				"%s: can't find PT_LOAD segment align for '%s'\n",
				pgm_name, exe_in
			);
			exit(1);
		}	
	}
	/* Read file with PT_OAD segments */
	phdrs_out = my_fread_whole_file(phdrs_name, "PT_LOAD phdrs", &phdrs_size);

	/* Sanity */
	if (phdrs_size == 0) {
		fprintf(
			stderr,
			"%s: size of the file '%s' is 0.\n",
			pgm_name, phdrs_name
		);
		exit(1);
	}

	if (phdrs_size % sizeof(ElfW(Phdr)) != 0) {
		fprintf(
			stderr,
			"%s: size=%ld of the file '%s' is not multiple of phdr size=%d\n",
			pgm_name, phdrs_size, phdrs_name, sizeof(ElfW(Phdr))
		);
		exit(1);
	}

	/* Calculate number of PT_LOAD segments */ 
	pt_load_num = phdrs_size / sizeof(ElfW(Phdr));

	/* Fill in output elf header */
	memcpy(&ehdr_out, &ehdr_exe, sizeof(ehdr_out)); /* copy from orig */
	/* If input exe was build as PIC executable convert type to
	 * regular exe */
	if (ehdr_exe.e_type == ET_DYN) ehdr_out.e_type = ET_EXEC;

	/* e_entry we got as parameter from the command line */
	ehdr_out.e_entry = my_strtoul(e_entry);

	/* Let us put Programs headers just after ehdr */
	ehdr_out.e_phoff = sizeof(ehdr_out);

	/* Phdrs num */
	ehdr_out.e_phnum = pt_load_num + non_pt_load_num;

	/* Sections header just after phdrs */
	ehdr_out.e_shoff = 
		ehdr_out.e_phoff + 
		sizeof(ElfW(Phdr)) * ehdr_out.e_phnum
	;
	/* Sections number from original exe  - do nothing */
	ehdr_out.e_shnum = 0; /* TEMP !!! */

	non_alloc_sections_size = 0; /* TEMP !!! */

	/* Calculate end of the nonallocated sections in the output file */  
	end_of_non_alloc_sections = 
		ehdr_out.e_shoff                      +
       		sizeof(ElfW(Shdr)) * ehdr_out.e_shnum +
 		non_alloc_sections_size
	;		

	/* 
	 * Calculate begin of the PT_LOAD segments in the filei:
	 * it should be on the align boundary.
	 */
	pt_load_offset = (end_of_non_alloc_sections / align) * align;
	if (pt_load_offset < end_of_non_alloc_sections) pt_load_offset += align;

	fill_size = pt_load_offset - end_of_non_alloc_sections;

	/* Update p_offset field for the pt_load segmnets */
	{
		ElfW(Phdr) *phdr = (ElfW(Phdr) *)phdrs_out;
		int i;
		phdr[0].p_offset = pt_load_offset;
		for (i = 1; i < pt_load_num; i++) {
			phdr[i].p_offset = 
				phdr[i-1].p_offset + 
				phdr[i-1].p_filesz
			;
		}
	}

	/* Ok, everything prepared. Let us write output file */
	/* Ehdr */
	res = my_fwrite(&ehdr_out, sizeof(ehdr_out), stdout, "ehdr", "stdout");
	if (res == -1) exit(1);

	/* Phdrs */
	res = my_fwrite(phdrs_out, ehdr_out.e_phnum * sizeof(ElfW(Phdr)), stdout, "phdrs", "stdout");
	if (res == -1) exit(1);

	/* Shdrs */
	if (ehdr_out.e_shnum != 0) {
		shdrs_out = my_malloc(shdrs_size_exe, "shdrs");
		if (shdrs_out == NULL) exit(1);
		res = my_fwrite(shdrs_out, ehdr_out.e_shnum * sizeof(ElfW(Shdr)), stdout, "shdrs", "stdout");
		if (res == -1) exit(1);
	}

	/* Non-allocated sections */
	if (non_alloc_sections_size > 0) {
		; /* copy non-allocated sections from orig exe.*/
	}

	if (fill_size > 0) {
		char *fill;
		fill = my_malloc(fill_size, "filler");
		if (fill == NULL) exit(1);
		/* Clean it */
		memset(fill, 0, fill_size);
		res = my_fwrite(fill, fill_size, stdout, "filler", "stdout");
	}
 	exit(0);
}
