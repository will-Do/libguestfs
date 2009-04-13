# libguestfs Python bindings
# Copyright (C) 2009 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

import guestfs

g = guestfs.guestfs()
f = open ("test.img", "w")
f.truncate (500 * 1024 * 1024)
f.close ()
g.add_drive ("test.img")
g.launch ()
g.wait_ready ()
g.pvcreate ("/dev/sda")
g.vgcreate ("VG", ["/dev/sda"])
g.lvcreate ("LV1", "VG", 200)
g.lvcreate ("LV2", "VG", 200)
if (g.lvs () != ["/dev/VG/LV1", "/dev/VG/LV2"]):
    raise "Error: g.lvs() returned incorrect result"
g.sync ()
del g

import os
os.unlink ("test.img")
