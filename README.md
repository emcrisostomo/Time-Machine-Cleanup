Time Machine Cleanup
====================

`tm-cleanup.sh` is a Zsh script to clean up Time Machine backups and reduce its
size.  `tm-cleanup.sh` provides two interfaces:

  * A command-line interface.

  * An interactive, dialog-based interface.

`tm-cleanup.sh` requires super-user privileges, so it's normally executed using
`sudo`.

tm-cleanup.sh
-------------

`tm-cleanup.sh` is a Zsh script that lists the completed Time Machine snapshots
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

![tm-cleanup.sh - Start](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-start.png)

The _Delete backups_ operation brings the user to a dialog where the backups to
delete can be selected.  By default, backups are shown in reverse chronological
order (i.e.: latest first) and all except the first are selected.

![tm-cleanup.sh - Choose backups](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-delete.png)

The backups deletion may take a long time to complete, during which a progress
dialog is shown.

![tm-cleanup.sh - Backup deletion progress](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-progress.png)

At the end of the deletion, a confirmation is shown to the user.

![tm-cleanup.sh - Backup deletion done](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-delete-done.png)

The script prevents users to delete all the backups.  If all the backups are
selected, an error message is shown.

![tm-cleanup.sh - Invalid backup choice](https://raw.githubusercontent.com/emcrisostomo/Time-Machine-Cleanup/assets/images/tm-delete-invalid-choice.png)

Installation
------------

This package is configured using the GNU Autotools.  For this reason, users who
just wish to use this software have to download a release tarball.  Release
tarball are attached to each release.  The [latest] release of this package can
always be found using the [latest] tag.

[latest]: https://github.com/emcrisostomo/Time-Machine-Cleanup/releases/latest

Once a release tarball has been downloaded and uncompressed, this package can be
installed using the following commands:

    $ ./configure
    $ sudo make install

Please, refer to the Autotools documentation if you'd like to customise the
installation procedure.

The package can then be uninstalled using the following command:

    $ sudo make uninstall

To make path changes visibile in an existing Zsh session, execute the `rehash`
command:

    $ rehash

Requirements
------------

Since a compatible version of Zsh is bundled with OS X, the command-line
interface of this script has no other requirements.  To use the dialog-based
interface, `dialog` is required.

Testing locally
---------------

To create an HFS+ disk image:

    $ hdiutil create -size 100g \
        -fs HFS+J -type SPARSEBUNDLE \
        -volname "TimeMachineBackup-HFSplus" \
        ~/TimeMachineBackup-HFSplus

To create an APFS disk image:

    $ hdiutil create -size 100g \
        -fs APFS -type SPARSEBUNDLE \
        -volname "TimeMachineBackup-APFS" \
        ~/TimeMachineBackup-APFS

Check whether the disk is mounted:

    $ diskutil list

If it's not mounted, attach it to the system:

    $ hdiutil attach ~/TimeMachineBackup-APFS

Verify it's mounted:

    $ ls /Volumes

Set it as the destination of a Time Machine backup.  It might be necessary to
grant _Full Disk Access_ permissions to the terminal application used to launch
the following command, or use the _Preferences_ application.

*Note:* make sure to use the `-a` flag in order not to clobber the current set
of destinations.

    $ sudo tmutil -a setdestination /Volumes/TimeMachineBackup-APFS

Verify the configuration:

    $ tmutil destinationinfo

Bug Reports
-----------

Bug reports can be sent directly to the authors.

-----

Copyright (C) 2015-2025 Enrico M. Crisostomo

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
