Time Machine Cleanup
====================

`tm-cleanup.sh` is a ZSH script to clean up Time Machine backups and reduce its
size.  `tm-cleanup.sh` provides two interfaces:

  * A command-line interface.

  * An interactive, dialog-based interface.

`tm-cleanup.sh` requires super-user privileges, so it's normally executed using
`sudo`.

tm-cleanup.sh
-------------

`tm-cleanup.sh` is a ZSH script that lists the completed Time Machine snapshots
and deletes those that satisfy the specified criteria.  Two types of deletion
criteria exist:

  * By date: snapshots that are older than a specified number of days are
    deleted.  The default threshold is 30 days.

  * By number: a maximum number of snapshots is retained and oldest snapshots
  are deleted.

Only one deletion criteria can be specified.

The syntax of `tm-cleanup.sh` is the following:

    $ tm-cleanup.sh (-d days | -n number) [-f] [-x]
    $ tm-cleanup.sh [-h]

where

  * If `-d` is specified, backups older than the specified number of days will
    be deleted.  `days` is a positive integer number.

  * `-n` specifies the number of backups to retain.  `number` is a positive
    integer number.

  * By default, `tm-cleanup.sh` exits and prints an error message if a Time
    Machine backup is currently in progress.  `-f` forces the backup deletion
    concurrently.

  * `-h` prints the help message and exits the program.

  * `-x` performs a dry clean: it will print the list of operations that will
    be performed without actually performing any.

This script *never* deletes the latest snapshot, no matter the value of the `-d`
or `-n` options.

Interactive Interface
---------------------

`tm-cleanup.sh` also provides an interactive interface which is useful if the
user wishes to pick which backups to delete using a dialog-based interface.  The
interactive interface can be launched by passing no arguments to the script:

    $ tm-cleanup.sh

The interactive interface starts with a menu showing the available operations a
user can perform:

![tm-cleanup.sh - Start dialog](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-start.png)

Installation
------------

The scripts require no installation: they can be downloaded and run from any
location.  However, this repository provides an installation script that creates
symbolic links to `/usr/local/bin`, a directory which is included by default in
the `${PATH}` of any OS X user.  Installing the symbolic links has the advantage
of always providing the current version of the scripts on the `${PATH}` when the
local repository is updated.

To install the symbolic links:

```
$ sudo make install
```

To uninstall the symbolic links:

```
$ sudo make uninstall
```

To make the changes visibile in an existing ZSH session, execute this command:

```
$ rehash
```

Requirements
------------

Since a compatible version of ZSH is bundled with OS X, the command-line
interface of this script has no other requirements.  To use the dialog-based
interface, `dialog` is required.

Bug Reports
-----------

Bug reports can be sent directly to the authors.

-----

Copyright (C) 2016-2017 Enrico M. Crisostomo

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
