#include <stdio.h>
#include <stdlib.h>
#include <link.h>

int main(int argc, char *argv[])
{
	printf ("0x%x\n", _r_debug.r_ldbase);
	exit(0);
	return 0;
}
