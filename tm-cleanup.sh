#!/bin/zsh
# -*- coding: utf-8; tab-width: 2; indent-tabs-mode: nil; sh-basic-offset: 2; sh-indentation: 2; -*- vim:fenc=utf-8:et:sw=2:ts=2:sts=2
#
# Copyright (C) 2016-2017 Enrico M. Crisostomo
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
setopt localoptions
setopt localtraps
unsetopt glob_subst

set -o errexit
set -o nounset

PROGNAME=$0
VERSION=1.2.0

# Define an integer variable to store the deletion threshold for each mode.
# Default: 30 days
# Default: 7 backups
typeset -i DAYS_TO_KEEP=30
typeset -i NUMBER_TO_KEEP=7
typeset -i DRY_RUN=0
typeset -i FORCE_EXECUTION=0
# Execution modes
#   - 0: number of days
#   - 1: number of backups
typeset -ri MODE_DAYS=1
typeset -ri MODE_BACKUPS=2
typeset -ri MODE_UNKNOWN=0
typeset -i EXECUTION_MODE=${MODE_UNKNOWN}
typeset -i ARGS_PROCESSED=0
typeset -a TM_BACKUPS
typeset -i TM_BACKUPS_LOADED=0
typeset -a TM_DIALOG_OPTS=( --backtitle "Time Machine Cleanup" )
typeset -a TM_DIALOG_CMD=( dialog ${TM_DIALOG_OPTS} )
typeset -a TM_OPERATIONS=( D "Delete backups" L "List backups" E "Exit" )
typeset -A TM_OPERATION_NAMES=( D "Delete backups" L "List backups" E "Exit" )

typeset -ri DIALOG_OK=0
typeset -ri DIALOG_CANCEL=1
typeset -ri DIALOG_HELP=2
typeset -ri DIALOG_EXTRA=3
typeset -ri DIALOG_ITEM_HELP=4
typeset -ri DIALOG_ESC=255
typeset -r TM_ERR_TEMP_FILE=$(mktemp)

command -v tmutil > /dev/null 2>&1 || {
  >&2 print -- Cannot find tmutil.
  exit 1
}

print_usage()
{
  print -- "${PROGNAME} ${VERSION}"
  print
  print -- "Usage:"
  print -- "${PROGNAME} (-d days | -n number) [-f] [-x]"
  print -- "${PROGNAME} [-h]"
  print
  print -- "Options:"
  print -- " -d         Number of days to keep."
  print -- " -f         Force execution even if a Time Machine backup is in progress."
  print -- " -h         Show this help."
  print -- " -n         Number of backups to keep."
  print -- " -x         Perform a dry run."
  print
  print -- "Report bugs to <https://github.com/emcrisostomo/Time-Machine-Cleanup>."
}

parse_opts()
{
  while getopts ":hd:fn:x" opt
  do
    case $opt in
      h)
        print_usage
        exit 0
        ;;
      d)
        DAYS_TO_KEEP=${OPTARG}
        EXECUTION_MODE=$((MODE_DAYS | EXECUTION_MODE))
        ;;
      f)
        FORCE_EXECUTION=1
        ;;
      n)
        NUMBER_TO_KEEP=${OPTARG}
        EXECUTION_MODE=$((MODE_BACKUPS | EXECUTION_MODE))
        ;;
      x)
        DRY_RUN=1
        ;;
      \?)
        >&2 print -- "Invalid option -${OPTARG}."
        exit 1
        ;;
      :)
        >&2 print -- "Missing argument to -${OPTARG}."
        exit 1
        ;;
    esac
  done

  ARGS_PROCESSED=$((OPTIND - 1))
}

process_by_days()
{
  (( ${DAYS_TO_KEEP} > 0 )) || {
    >&2 print -- "The number of days to keep must be positive."
    exit 2
  }

  # Establish the threshold date before which backups will be deleted
  THRESHOLD_DATE=$(date -j -v-${DAYS_TO_KEEP}d +"%Y-%m-%d")

  # As a safety precaution, just check that the output format has not changed.
  # If it has, let's not proceed.
  for i in ${TM_BACKUPS}
  do
    TM_DATE=$(basename $i)

    if [[ ! ${TM_DATE} =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$" ]]
    then
      >&2 print -- "Unexpected snapshot name: ${TM_DATE}."
      >&2 print -- "Aborting."
      exit 8
    fi
  done

  for i in ${TM_BACKUPS}
  do
    TM_DATE=$(basename $i)

    if [[ ${THRESHOLD_DATE} > ${TM_DATE} ]]
    then
      if [[ ${i} != ${TM_BACKUPS[-1]} ]]
      then
        print -- "${TM_DATE} will be deleted."

        if (( ${DRY_RUN} == 0 ))
        then
          tmutil delete ${i}
        fi
      else
        print -- "${TM_DATE} will not be deleted because it is the latest available Time Machine snapshot."
      fi
    fi
  done
}

process_by_backups()
{
  (( ${NUMBER_TO_KEEP} > 0 )) || {
    >&2 print -- "The number of backups to keep must be positive."
    exit 2
  }

  if (( ${NUMBER_TO_KEEP} >= ${#TM_BACKUPS} ))
  then
    exit 0
  fi

  typeset -i LAST_IDX=$(( ${#TM_BACKUPS} - ${NUMBER_TO_KEEP} ))

  for i in $(seq 1 ${LAST_IDX})
  do
    if [[ ${i} != ${TM_BACKUPS[-1]} ]]
    then
      print -- "${TM_BACKUPS[i]:t} will be deleted."

      if (( ${DRY_RUN} == 0 ))
      then
        tmutil delete ${TM_BACKUPS[i]}
      fi
    else
      print -- "${TM_DATE} will not be deleted because it is the latest available Time Machine snapshot."
    fi
  done
}

tm_health_checks()
{
  (( $# == 0 )) || {
    >&2 print -- "No arguments are allowed."
    exit 2
  }

  (( ${EUID} == 0 )) || {
    >&2 print -- "This command must be executed with super user privileges."
    exit 1
  }

  # Check if a backup is running and if it is, skip execution.
  # This check relies on the undocumented tmutil `status' verb.
  if (( ${FORCE_EXECUTION} == 0 )) && tmutil status | grep Running | grep -q 1
  then
    >&2 print -- "A Time Machine backup is being performed.  Skip execution."
    exit 4
  fi

  if (( EXECUTION_MODE & (EXECUTION_MODE - 1) ))
  then
    >&2 print -- "Only one mode can be specified.  Exiting."
    exit 2
  fi
}

tm_load_backups()
{
  if (( TM_BACKUPS_LOADED > 0 ))
  then
    return
  fi

  # Get the full list of backups from tmutil
  if TMUTIL_OUTPUT=$(tmutil listbackups 2> ${TM_ERR_TEMP_FILE})
  then
    TM_BACKUPS=( "${(ps:\n:)$(tmutil listbackups)}" )

    # We are sorting the output of tmutil listbackups because its documentation
    # states nowhere that the output is sorted in any way.
    TM_BACKUPS=( ${(n)TM_BACKUPS} )

    TM_BACKUPS_LOADED=1
    TM_LOAD_BACKUPS=0
  else
    TM_LOAD_BACKUPS=1
  fi
}

tm_start_batch()
{
  tm_load_backups

  case ${EXECUTION_MODE} in
    ${MODE_DAYS})
      process_by_days
      ;;
    ${MODE_BACKUPS})
      process_by_backups
      ;;
    *)
      >&2 print -- "Unexpected mode.  Exiting."
      exit 4
      ;;
  esac
}

tm_open_operation()
{
  case $1 in
    D)
      ${TM_DIALOG_CMD} --title ${TM_OPERATION_NAMES[$1]} --msgbox "To do" 0 0
      ;;
    E)
      exit 0
      ;;
    L)
      tm_load_backups

      if (( TM_LOAD_BACKUPS == 0 ))
      then
        ${TM_DIALOG_CMD} --title ${TM_OPERATION_NAMES[$1]} --msgbox "${TM_BACKUPS}" 0 0
      else
        ${TM_DIALOG_CMD} --title ${TM_OPERATION_NAMES[$1]} --msgbox "$(cat ${TM_ERR_TEMP_FILE})" 0 0
      fi
      ;;
    *)
      >&2 print -- "Unknown operation $1.  This is a bug."
      exit 1
      ;;
  esac
}

tm_start_dialog()
{
  command -v dialog > /dev/null 2>&1 ||
    {
      >&2 print -- "dialog is required to use the interactive mode."
      exit 1
    }

  exec 3>&1

  while true
  do
    ret=$( ${TM_DIALOG_CMD} --no-cancel --menu "Operations" 0 0 ${#TM_OPERATIONS} ${TM_OPERATIONS} 2>&1 1>&3)

    case $? in
      ${DIALOG_OK})
        tm_open_operation ${ret}
        ;;
      *)
        break
        ;;
    esac
  done

  exec 3>&-
}

# Main
parse_opts $* && shift ${ARGS_PROCESSED}

tm_health_checks

if (( ${EXECUTION_MODE} == ${MODE_UNKNOWN} ))
then
  tm_start_dialog
else
  tm_start_batch
fi
