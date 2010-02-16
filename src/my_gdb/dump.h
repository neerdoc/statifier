#ifndef dump_h
#define dump_h

#include <sys/types.h>
#include <stddef.h>

void get_memory(pid_t pid, const void *start, const void *stop, char *buffer);
void dumps(pid_t pid, const char *maps_filename, const char *output_dir);
#endif /* dump_h */
