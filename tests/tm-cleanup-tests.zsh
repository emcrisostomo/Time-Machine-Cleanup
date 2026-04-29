#!/bin/zsh
# -*- coding: utf-8; tab-width: 2; indent-tabs-mode: nil; sh-basic-offset: 2; sh-indentation: 2; -*- vim:fenc=utf-8:et:sw=2:ts=2:sts=2

setopt local_options
unsetopt shwordsplit

set -o errexit
set -o nounset

typeset -i FAILURES=0

assert_eq()
{
  local expected=${1}
  local actual=${2}
  local message=${3}

  if [[ ${actual} != ${expected} ]]
  then
    print -u2 -- "not ok - ${message}"
    print -u2 -- "  expected: ${expected}"
    print -u2 -- "  actual:   ${actual}"
    FAILURES+=1
  else
    print -- "ok - ${message}"
  fi
}

assert_status()
{
  local expected=${1}
  local actual=${2}
  local message=${3}

  assert_eq ${expected} ${actual} ${message}
}

export TM_CLEANUP_TESTING=1
. ${0:A:h}/../src/tm-cleanup.sh.in

assert_eq \
  "2024-02-15-151647" \
  "$(tm_backup_timestamp "/Volumes/.timemachine/2024-02-15-151647.backup")" \
  "APFS backup names are normalized to tmutil timestamps"

assert_eq \
  "2024-02-15-151647" \
  "$(tm_backup_timestamp "2024-02-15-151647")" \
  "bare tmutil timestamps are kept unchanged"

assert_eq \
  "/Volumes/Time Machine" \
  "$(tm_machine_dir_to_mount_point "/Volumes/Time Machine/Backups.backupdb/MacBook")" \
  "HFS machine directories map to their backup mount point"

assert_eq \
  "/Volumes/Time Machine" \
  "$(tm_machine_dir_to_mount_point "/Volumes/Time Machine")" \
  "APFS machine directories are already backup mount points"

TM_BACKUPS=(
  "2024-02-15-151647.backup"
  "2024-02-16-151647"
)

set +o errexit
tm_validate_backup_dates
assert_status 0 $? "validation accepts APFS suffixes and bare timestamps"
set -o errexit

TM_BACKUPS=( "not-a-backup" )
set +o errexit
( tm_validate_backup_dates ) > /dev/null 2>&1
assert_status 8 $? "validation rejects unexpected names"
set -o errexit

typeset TM_TEST_LOG=$(mktemp)
trap 'rm -f ${TM_TEST_LOG} ${TM_ERR_TEMP_FILE}' EXIT

tmutil()
{
  print -- "$*" >> ${TM_TEST_LOG}
}

TM_BACKUP_MOUNT_POINT="/Volumes/Time Machine"
TM_BACKUPS=(
  "2024-02-15-151647.backup"
  "2024-02-16-151647.backup"
  "2024-02-17-151647.backup"
)
NUMBER_TO_KEEP=1
DRY_RUN=0
process_by_backups > /dev/null
assert_eq \
  $'delete -d /Volumes/Time Machine -t 2024-02-15-151647\ndelete -d /Volumes/Time Machine -t 2024-02-16-151647' \
  "$(cat ${TM_TEST_LOG})" \
  "backup-count deletion uses the backup mount point and normalized timestamp"

print -n -- "" > ${TM_TEST_LOG}
tm_test_dialog()
{
  cat > /dev/null
}
TM_DIALOG_CMD=( tm_test_dialog )
tm_delete_backups 2 > /dev/null
assert_eq \
  "delete -d /Volumes/Time Machine -t 2024-02-16-151647" \
  "$(cat ${TM_TEST_LOG})" \
  "interactive deletion deletes the selected backup index"

if (( FAILURES > 0 ))
then
  exit 1
fi
