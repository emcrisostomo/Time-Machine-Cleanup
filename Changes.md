# Updates to Time-Machine-Cleanup v2.1.1

The original version of this [project](https://github.com/emcrisostomo/Time-Machine-Cleanup) from Enrico hasn't been updated for ~7 years.

At that time, TM backups were housed in an HFS+ FS. 

In Big Sur it became possible to use APFS for TM backups. This seems to have changed the semantics of the `tmutil(8)` command. The associated manpage details different treatment for HFS+ and APFS TM backup volumes.

The updates for this version are in this [repo](https://github.com/rprimmer/Time-Machine-Cleanup/tree/Sonoma-changes).

## Testing

This branch tested successfully on macOS 14.4.1 23E224 x86_64 and arm. In both cases the TM volumes were housed on APFS.
I don't have access to a system with TM volumes on HFS+, so that needs to be tested.

### Potential Update

The delete entry in the tmutil manpage seems to indicate a difference in the required flags for APFS and HFS+. If true, then `MACHINE_DIR` could be appended to an array that includes the `-t` and `-d` flags.

If `set -o nounset` is removed from the script, then this array could be empty for cases where TM uses HFS+. Example code to test TM FS.

```zsh
tm_mount_point=$(tmutil machinedirectory)

if [ -z "$tm_mount_point" ]; then
    echo "Time Machine disk not found."
    exit 1
fi

file_system=$(diskutil info "$tm_mount_point" | grep "Type (Bundle)" | awk '{print $NF}')

if [ "$file_system" == "hfs" ]; then
    echo "Time Machine disk is formatted as HFS+"
    # zero out command array
elif [ "$file_system" == "apfs" ]; then
    echo "Time Machine disk is formatted as APFS"
    # build command array to: -d "$MACHINE_DIR"
else
    echo "Unrecognized Time Machine filesystem"
fi
```

## Code Changes v2.1.1

Version 2.1.1 changes are in the Sonoma-changes [branch](https://github.com/rprimmer/Time-Machine-Cleanup/tree/Sonoma-changes).

### New Feature

Here are the changes made.

Added flag `-s` to show existing TM backups. Changes:

* added global `MODE_SHOW_BACKUPS=4`,
* added to `print_usage()`,
* added to `parse_opts()`, and
* added to `tm_start_batch()`.

Upped the version in `configure.ac` from 2.1.0 to 2.1.1.

It's now: `AC_INIT([tm-cleanup], [2.1.1], [enrico.m.crisostomo@gmail.com])`

## Code Changes v2.1.0

### Sonoma APFS Fixes

In `process_by_days()`, changed `tmutil delete ${i}` to `tmutil delete -t ${i} -d "$MACHINE_DIR"`, where `MACHINE_DIR` is created in the `tm_health_checks()`.

In `process_by_backups()` changed `tmutil delete -t ${TM_BACKUPS[i]}` to `tmutil delete -t ${TM_BACKUPS[i]} -d "$MACHINE_DIR"`

In `tm_health_checks()` added assignment for `MACHINE_DIR`.

```zsh
  MACHINE_DIR=$(tmutil machinedirectory)
  if [[ -z "$MACHINE_DIR" ]]; then
    echo "failed to set the machine directory for tmutil"
    exit 3
  fi
```

Also in `tm_health_checks()` updated the two checks to see if a TM backup is in progress.

```zsh
 if (( ${FORCE_EXECUTION} == 0 )); then
    if tmutil status | grep -E -q 'Starting|PreparingSourceVolumes|FindingChanges|Copying|ThinningPostBackup'; then
      print -- "A Time Machine backup is being performed. Skipping execution." >&2
      exit 4
    fi
  fi
```
and

```zsh
  if (( ${FORCE_EXECUTION} == 0 )) && tmutil status | grep -E -q 'Starting|PreparingSourceVolumes|FindingChanges|Copying|ThinningPostBackup';
  then
    >&2 print -- "A Time Machine backup is being performed.  Skip execution."
    exit 4
  fi
```

In `tm_load_backups()`, the assignment line with `tmutil` needed to have a `-t` added to the `tmutil listbackups` command.
`TM_BACKUPS=( "${(ps:\n:)$(tmutil listbackups -t)}" )`

Finally, I upped the version in `configure.ac` from 2.0.0 to 2.1.0.

It's now: `AC_INIT([tm-cleanup], [2.1.0], [enrico.m.crisostomo@gmail.com])`

## TODO

I didn't do any changes for the interactive code, which makes use of the `dialog(1)` package.

I had tried this with the original build and it didn't work well on my systems. Since I only use the command line options, I left this as a future TODO for any who prefer the interactive mode.
