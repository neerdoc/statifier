# Copyright (C) 2005 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for clear trace bit in the processor's status for x86_64
set $eflags = $eflags & ~ 0x100
