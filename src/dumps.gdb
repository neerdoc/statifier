# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Default second command file for gdb. 
# This one should be overwriten.
# If it was leaved as is something went wrong and gdb should be killed.

shell echo "$0: File '@DUMPS_GDB@' was not created by '@DUMPS_SH@' as needed." 1>&2; kill $PPID
quit
