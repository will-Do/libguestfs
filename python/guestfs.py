# libguestfs generated file
# WARNING: THIS FILE IS GENERATED BY 'src/generator.ml'.
# ANY CHANGES YOU MAKE TO THIS FILE WILL BE LOST.
#
# Copyright (C) 2009 Red Hat Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

import libguestfsmod

class guestfs:
    def __init__ (self):
        self._o = libguestfsmod.create ()

    def __del__ (self):
        libguestfsmod.close (self._o)

    def launch (self):
        return libguestfsmod.launch (self._o)

    def wait_ready (self):
        return libguestfsmod.wait_ready (self._o)

    def kill_subprocess (self):
        return libguestfsmod.kill_subprocess (self._o)

    def add_drive (self, filename):
        return libguestfsmod.add_drive (self._o, filename)

    def add_cdrom (self, filename):
        return libguestfsmod.add_cdrom (self._o, filename)

    def config (self, qemuparam, qemuvalue):
        return libguestfsmod.config (self._o, qemuparam, qemuvalue)

    def set_path (self, path):
        return libguestfsmod.set_path (self._o, path)

    def get_path (self):
        return libguestfsmod.get_path (self._o)

    def set_autosync (self, autosync):
        return libguestfsmod.set_autosync (self._o, autosync)

    def get_autosync (self):
        return libguestfsmod.get_autosync (self._o)

    def set_verbose (self, verbose):
        return libguestfsmod.set_verbose (self._o, verbose)

    def get_verbose (self):
        return libguestfsmod.get_verbose (self._o)

    def mount (self, device, mountpoint):
        return libguestfsmod.mount (self._o, device, mountpoint)

    def sync (self):
        return libguestfsmod.sync (self._o)

    def touch (self, path):
        return libguestfsmod.touch (self._o, path)

    def cat (self, path):
        return libguestfsmod.cat (self._o, path)

    def ll (self, directory):
        return libguestfsmod.ll (self._o, directory)

    def ls (self, directory):
        return libguestfsmod.ls (self._o, directory)

    def list_devices (self):
        return libguestfsmod.list_devices (self._o)

    def list_partitions (self):
        return libguestfsmod.list_partitions (self._o)

    def pvs (self):
        return libguestfsmod.pvs (self._o)

    def vgs (self):
        return libguestfsmod.vgs (self._o)

    def lvs (self):
        return libguestfsmod.lvs (self._o)

    def pvs_full (self):
        return libguestfsmod.pvs_full (self._o)

    def vgs_full (self):
        return libguestfsmod.vgs_full (self._o)

    def lvs_full (self):
        return libguestfsmod.lvs_full (self._o)

    def read_lines (self, path):
        return libguestfsmod.read_lines (self._o, path)

    def aug_init (self, root, flags):
        return libguestfsmod.aug_init (self._o, root, flags)

    def aug_close (self):
        return libguestfsmod.aug_close (self._o)

    def aug_defvar (self, name, expr):
        return libguestfsmod.aug_defvar (self._o, name, expr)

    def aug_defnode (self, name, expr, val):
        return libguestfsmod.aug_defnode (self._o, name, expr, val)

    def aug_get (self, path):
        return libguestfsmod.aug_get (self._o, path)

    def aug_set (self, path, val):
        return libguestfsmod.aug_set (self._o, path, val)

    def aug_insert (self, path, label, before):
        return libguestfsmod.aug_insert (self._o, path, label, before)

    def aug_rm (self, path):
        return libguestfsmod.aug_rm (self._o, path)

    def aug_mv (self, src, dest):
        return libguestfsmod.aug_mv (self._o, src, dest)

    def aug_match (self, path):
        return libguestfsmod.aug_match (self._o, path)

    def aug_save (self):
        return libguestfsmod.aug_save (self._o)

    def aug_load (self):
        return libguestfsmod.aug_load (self._o)

    def aug_ls (self, path):
        return libguestfsmod.aug_ls (self._o, path)

    def rm (self, path):
        return libguestfsmod.rm (self._o, path)

    def rmdir (self, path):
        return libguestfsmod.rmdir (self._o, path)

    def rm_rf (self, path):
        return libguestfsmod.rm_rf (self._o, path)

    def mkdir (self, path):
        return libguestfsmod.mkdir (self._o, path)

    def mkdir_p (self, path):
        return libguestfsmod.mkdir_p (self._o, path)

    def chmod (self, mode, path):
        return libguestfsmod.chmod (self._o, mode, path)

    def chown (self, owner, group, path):
        return libguestfsmod.chown (self._o, owner, group, path)

    def exists (self, path):
        return libguestfsmod.exists (self._o, path)

    def is_file (self, path):
        return libguestfsmod.is_file (self._o, path)

    def is_dir (self, path):
        return libguestfsmod.is_dir (self._o, path)

    def pvcreate (self, device):
        return libguestfsmod.pvcreate (self._o, device)

    def vgcreate (self, volgroup, physvols):
        return libguestfsmod.vgcreate (self._o, volgroup, physvols)

    def lvcreate (self, logvol, volgroup, mbytes):
        return libguestfsmod.lvcreate (self._o, logvol, volgroup, mbytes)

    def mkfs (self, fstype, device):
        return libguestfsmod.mkfs (self._o, fstype, device)

    def sfdisk (self, device, cyls, heads, sectors, lines):
        return libguestfsmod.sfdisk (self._o, device, cyls, heads, sectors, lines)

    def write_file (self, path, content, size):
        return libguestfsmod.write_file (self._o, path, content, size)

    def umount (self, pathordevice):
        return libguestfsmod.umount (self._o, pathordevice)

    def mounts (self):
        return libguestfsmod.mounts (self._o)

    def umount_all (self):
        return libguestfsmod.umount_all (self._o)

    def lvm_remove_all (self):
        return libguestfsmod.lvm_remove_all (self._o)

