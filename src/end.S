# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Include file for all .S sources.
# And MY_ORG macro needed to be used in order
# to align code to the REG_SIZE boundary.
# Otherwise gcc (at least gcc 2.95.3)
# will add bytes to the end of the file.
# It is not good, so I do it by myself where I need it


# Idea is following:
#    I need move addr to the multiple by REG_SIZE.
#    (. % REG_SIZE) - how many spare bytes we have
#    (REG_SIZE - (. % REG_SIZE)) - how many bytes we need to add in order to
#                                  by multiplly by REG_SIZE
#    ((REG_SIZE - (. % REG_SIZE )) % REG_SIZE) - if . was alignment avoid 
#                                                adding REG_SIZE bytes

MY_DATA NEXT_CODE
	jmp	data + NEXT_CODE
	.org . + ((REG_SIZE - (. % REG_SIZE )) % REG_SIZE)
data:

