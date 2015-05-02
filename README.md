Time Machine Cleanup
====================

ZSH scripts to clean up Time Machine backups and reduce its size.

tm-cleanup.sh
-------------

`tm-cleanup.sh` is a ZSH script that lists the completed Time Machine snapshots
and deletes those that are oldest that a specified number of days.  The default
threshold is 30 days.

The syntax of `tm-cleanup.sh` is the following:

```
$ tm-cleanup.sh [-d days] [-h]
```

where

  * `days` is an unsigned positive integer number.  The accepted format is
    `[0-9]+`.

  * `-h` prints the help message and exits the program.

This scripts *never* deletes the latest snapshot, no matter the value of the
`days` option.

Installation
------------

The scripts require no installation: they can be downloaded and run from any
location.
However, this repository provides an installation script that creates
symbolic links to `/usr/local/bin`, a directory which is included by default
in the `${PATH}` of any OS X user.
Installing the symbolic links has the advantage of always providing the current
version of the scripts on the `${PATH}` when the local repository is updated.

To install the symbolic links:

```
$ sudo make install
```

To uninstall the symbolic links:

```
$ sudo make uninstal
```

Requirements
------------

Since a compatible version of ZSH is bundled with OS X, these scripts have no
other requirements.

Bug Reports
-----------

Bug reports can be sent directly to the authors.

-----

Copyright (C) 2015 Enrico M. Crisostomo

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
